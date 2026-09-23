import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

enum WeatherStatus { idle, loading, success, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

  WeatherStatus _status = WeatherStatus.idle;
  WeatherModel? _weather;
  String? _errorMessage;

  WeatherStatus get status => _status;
  WeatherModel? get weather => _weather;
  String? get errorMessage => _errorMessage;

  Future<void> loadWeather() async {
    _status = WeatherStatus.loading;
    notifyListeners();

    try {
      final result = await _weatherService.fetchWeatherAndRisk();
      _weather = result;
      _status = WeatherStatus.success;
    } catch (e) {
      _status = WeatherStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}