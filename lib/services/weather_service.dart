import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';

class WeatherData {
  final String condition;
  final double temperature;
  final String description;
  final String icon;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.description,
    required this.icon,
  });
}

class WeatherService {
  static Map<String, dynamic>? _cachedWeatherData;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  static Future<WeatherData?> getWeatherByLocation(double latitude, double longitude) async {
    try {
      if (_cachedWeatherData != null && 
          _cacheTime != null && 
          DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        final cached = _cachedWeatherData!;
        if (cached['coord']['lat'] == latitude && cached['coord']['lon'] == longitude) {
          return _parseWeatherData(cached);
        }
      }

      final url = Uri.parse(
        '${ApiConfig.openWeatherBaseUrl}/weather'
        '?lat=$latitude'
        '&lon=$longitude'
        '&appid=${ApiConfig.openWeatherApiKey}'
        '&units=metric'
        '&lang=kr'
      );
      
      debugPrint('Weather API URL: $url');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      debugPrint('Weather API Response Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        _cachedWeatherData = data;
        _cacheTime = DateTime.now();
        
        return _parseWeatherData(data);
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        debugPrint('Weather API error body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting weather: $e');
      return null;
    }
  }

  static WeatherData _parseWeatherData(Map<String, dynamic> data) {
    final weather = data['weather'][0];
    final main = data['main'];
    
    String condition = weather['main'];
    String koreanCondition = ApiConfig.weatherConditionKorean[condition] ?? condition;
    
    return WeatherData(
      condition: koreanCondition,
      temperature: main['temp'].toDouble(),
      description: weather['description'],
      icon: weather['icon'],
    );
  }

  static Future<Map<String, dynamic>?> getWeatherDataForStorage(double latitude, double longitude) async {
    final weatherData = await getWeatherByLocation(latitude, longitude);
    
    if (weatherData != null) {
      return {
        'weather': weatherData.condition,
        'temperature': weatherData.temperature,
      };
    }
    return null;
  }

  static void clearCache() {
    _cachedWeatherData = null;
    _cacheTime = null;
  }
}