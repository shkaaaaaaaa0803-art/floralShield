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
  /// thrive around 25°C with humidity above ~90%.
  ///
  /// Both factors are smooth curves rather than fixed buckets. The old
  /// bucketed version gave every temp in 20-30°C the same tempFactor and
  /// every humidity >=80% the same humidityFactor, so any day in that
  /// (very common, especially in humid regions) combination always came
  /// out to *exactly* 1.0 - a multi-day forecast could look like a flat
  /// line at 100% even though the underlying weather actually differed
  /// day to day. These curves keep the same overall shape (peak risk
  /// around 20-30°C / high humidity, tapering outside that) but vary
  /// continuously, so 23°C isn't scored identically to 29°C.
  static double calculateRisk(double temp, double humidity) {
    const peakTemp = 25.0;
    final distance = (temp - peakTemp).abs();
    double tempFactor;
    if (distance <= 5) {
      tempFactor = 1.0 - (distance / 5) * 0.15; // 20-30°C: 0.85 - 1.0
    } else if (distance <= 10) {
      tempFactor = 0.85 - ((distance - 5) / 5) * 0.35; // 15-20 / 30-35°C: 0.50 - 0.85
    } else if (distance <= 15) {
      tempFactor = 0.50 - ((distance - 10) / 5) * 0.30; // 10-15 / 35-40°C: 0.20 - 0.50
    } else {
      tempFactor = (0.20 - ((distance - 15) / 15) * 0.15).clamp(0.05, 0.20);
    }

    double humidityFactor;
    if (humidity >= 90) {
      humidityFactor = 1.0;
    } else if (humidity >= 40) {
      humidityFactor = 0.15 + ((humidity - 40) / 50) * 0.85; // 40-90%: 0.15 - 1.0
    } else {
      humidityFactor = (0.15 - ((40 - humidity) / 40) * 0.10).clamp(0.05, 0.15);
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
      Map<String, dynamic> forecastData, {
        String? state,
      }) {
    final rawCityName = (currentData['name'] as String?) ?? 'Unknown';
    // OpenWeatherMap's bundled city name can resolve to a small, unfamiliar
    // locality rather than the city you'd recognize (common in densely
    // named regions). Appending the state (from a best-effort reverse
    // geocode - see WeatherService) gives enough context to place it even
    // when the exact place name isn't one you know.
    final cityName = (state != null && state.isNotEmpty) ? '$rawCityName, $state' : rawCityName;
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