import 'package:flutter/material.dart';

/// Widget affichant les prévisions météo
class WeatherWidget extends StatelessWidget {
  final WeatherData weather;

  const WeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(
                    _getWeatherIcon(weather.condition),
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather.condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(Icons.water_drop, '${weather.humidity}%', 'Humidité'),
              _buildInfoItem(Icons.air, '${weather.windSpeed} km/h', 'Vent'),
              _buildInfoItem(Icons.umbrella, '${weather.rainChance}%', 'Pluie'),
            ],
          ),
          if (weather.alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weather.alerts.first,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleillé':
      case 'sunny':
        return Icons.wb_sunny;
      case 'nuageux':
      case 'cloudy':
        return Icons.cloud;
      case 'pluie':
      case 'rain':
        return Icons.water_drop;
      case 'orage':
      case 'storm':
        return Icons.flash_on;
      case 'partiellement nuageux':
        return Icons.cloud_queue;
      default:
        return Icons.wb_sunny;
    }
  }
}

/// Prévisions pour les prochains jours
class WeatherForecastWidget extends StatelessWidget {
  final List<DailyForecast> forecast;

  const WeatherForecastWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prévisions 7 jours',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: forecast.length,
              itemBuilder: (context, index) {
                final day = forecast[index];
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: index == 0 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: index == 0
                        ? Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        day.dayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Icon(
                        _getWeatherIcon(day.condition),
                        color: Colors.blue.shade400,
                        size: 22,
                      ),
                      Text(
                        '${day.tempMax.round()}°',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        '${day.tempMin.round()}°',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleillé':
        return Icons.wb_sunny;
      case 'nuageux':
        return Icons.cloud;
      case 'pluie':
        return Icons.water_drop;
      case 'orage':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }
}

/// Model pour les données météo
class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final int humidity;
  final int windSpeed;
  final int rainChance;
  final List<String> alerts;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.rainChance,
    this.alerts = const [],
  });
}

class DailyForecast {
  final String dayName;
  final String condition;
  final double tempMax;
  final double tempMin;

  DailyForecast({
    required this.dayName,
    required this.condition,
    required this.tempMax,
    required this.tempMin,
  });
}
