import 'package:dio/dio.dart';
// For WeatherData model, or move model to domain

abstract class WeatherRemoteDataSource {
  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon);
  Future<List<dynamic>> getForecast(double lat, double lon);
  Future<List<dynamic>> getAlerts(double lat, double lon);
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio dio;

  WeatherRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    try {
      final response = await dio.get('/weather/current', queryParameters: {
        'lat': lat,
        'lon': lon,
      });
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to load weather: $e');
    }
  }

  @override
  Future<List<dynamic>> getForecast(double lat, double lon) async {
    try {
      final response = await dio.get('/weather/forecast', queryParameters: {
        'lat': lat,
        'lon': lon,
      });
      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to load forecast: $e');
    }
  }

  @override
  Future<List<dynamic>> getAlerts(double lat, double lon) async {
    try {
      final response = await dio.get('/weather/alerts', queryParameters: {
        'lat': lat,
        'lon': lon,
      });
      return response.data['data'];
    } catch (e) {
      // Alerts are optional, return empty list on failure usually, but here we throw
      return []; 
    }
  }
}
