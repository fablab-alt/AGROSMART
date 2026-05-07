import 'package:agriculture/features/dashboard/data/datasources/weather_remote_data_source.dart';
import 'package:agriculture/features/weather/domain/entities/weather.dart';
import 'package:agriculture/features/dashboard/presentation/widgets/weather_widget.dart';

class WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepository({required this.remoteDataSource});

  Future<WeatherData> getWeather(double lat, double lon) async {
    final data = await remoteDataSource.getCurrentWeather(lat, lon);
    
    // Legacy mapping (keep for dashboard compatibility if needed)
    return WeatherData(
      location: data['location'] ?? 'Position actuelle', 
      temperature: (data['temperature'] as num).toDouble(),
      condition: data['condition'] ?? '',
      humidity: (data['humidity'] as num).toInt(),
      windSpeed: (data['wind_speed'] as num).toInt(),
      rainChance: 0, // Not always present in current
      alerts: [], 
    );
  }

  Future<List<WeatherForecast>> getForecasts(double lat, double lon) async {
    final data = await remoteDataSource.getForecast(lat, lon);
    return data.map((json) => WeatherForecast.fromJson(json)).toList();
  }

  Future<List<WeatherAlert>> getAlerts(double lat, double lon) async {
    final data = await remoteDataSource.getAlerts(lat, lon);
    return data.map((json) => WeatherAlert.fromJson(json)).toList();
  }
}
