class DailyForecast {
  final String dayLabel; // e.g. "Mon"
  final double avgTemp;
  final double avgHumidity;
  final double riskFraction; // 0.0 - 1.0

  DailyForecast({
    required this.dayLabel,
    required this.avgTemp,
    required this.avgHumidity,
    required this.riskFraction,
  });
}

class WeatherModel {
  final String cityName;
  final double temperature;
  final double humidity;
  final double riskFraction; // 0.0 - 1.0
  final String riskLabel; // e.g. "HIGH FUNGAL RISK"
  final List<DailyForecast> forecast;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.riskFraction,
    required this.riskLabel,
    required this.forecast,
  });

  /// Calculates a 0.0-1.0 fungal/bacterial disease risk score.
  /// Based on general plant pathology guidance: most fungal pathogens
  /// thrive between 20-30°C with humidity above 70%.
  static double calculateRisk(double temp, double humidity) {
    double tempFactor;
    if (temp >= 20 && temp <= 30) {
      tempFactor = 1.0; // ideal fungal growth range
    } else if (temp >= 15 && temp < 20 || temp > 30 && temp <= 35) {
      tempFactor = 0.6; // moderate risk range
    } else {
      tempFactor = 0.25; // low risk (too cold or too hot)
    }

    double humidityFactor;
    if (humidity >= 80) {
      humidityFactor = 1.0;
    } else if (humidity >= 60) {
      humidityFactor = 0.65;
    } else if (humidity >= 40) {
      humidityFactor = 0.35;
    } else {
      humidityFactor = 0.15;
    }

    // Weighted combination - humidity matters slightly more for fungal risk
    final risk = (tempFactor * 0.45) + (humidityFactor * 0.55);
    return risk.clamp(0.0, 1.0);
  }

  static String riskLabelFor(double riskFraction) {
    if (riskFraction >= 0.75) return 'HIGH FUNGAL RISK';
    if (riskFraction >= 0.45) return 'MODERATE RISK';
    return 'LOW RISK';
  }

  factory WeatherModel.fromApiData(
      Map<String, dynamic> currentData,
      Map<String, dynamic> forecastData,
      ) {
    final cityName = currentData['name'] ?? 'Unknown';
    final temp = (currentData['main']['temp'] as num).toDouble();
    final humidity = (currentData['main']['humidity'] as num).toDouble();
    final risk = calculateRisk(temp, humidity);

    // Parse 5-day forecast list (3-hour intervals) and group by day
    final List<dynamic> list = forecastData['list'] ?? [];
    final Map<String, List<Map<String, double>>> groupedByDay = {};

    for (final entry in list) {
      final dtTxt = entry['dt_txt'] as String; // "2026-08-20 12:00:00"
      final dayKey = dtTxt.split(' ')[0];
      final entryTemp = (entry['main']['temp'] as num).toDouble();
      final entryHumidity = (entry['main']['humidity'] as num).toDouble();

      groupedByDay.putIfAbsent(dayKey, () => []);
      groupedByDay[dayKey]!.add({'temp': entryTemp, 'humidity': entryHumidity});
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final forecastDays = <DailyForecast>[];

    final sortedKeys = groupedByDay.keys.toList()..sort();
    for (final key in sortedKeys.take(5)) {
      final entries = groupedByDay[key]!;
      final avgTemp = entries.map((e) => e['temp']!).reduce((a, b) => a + b) / entries.length;
      final avgHumidity = entries.map((e) => e['humidity']!).reduce((a, b) => a + b) / entries.length;
      final dayRisk = calculateRisk(avgTemp, avgHumidity);

      final date = DateTime.parse(key);
      final dayLabel = dayNames[date.weekday - 1];

      forecastDays.add(DailyForecast(
        dayLabel: dayLabel,
        avgTemp: avgTemp,
        avgHumidity: avgHumidity,
        riskFraction: dayRisk,
      ));
    }

    return WeatherModel(
      cityName: cityName,
      temperature: temp,
      humidity: humidity,
      riskFraction: risk,
      riskLabel: riskLabelFor(risk),
      forecast: forecastDays,
    );
  }
}