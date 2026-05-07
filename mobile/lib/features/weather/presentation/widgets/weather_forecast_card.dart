import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/weather.dart';

class WeatherForecast10DaysCard extends StatelessWidget {
  final List<WeatherForecast> forecasts;
  final VoidCallback? onRefresh;

  const WeatherForecast10DaysCard({
    super.key,
    required this.forecasts,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prévisions Météo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '10 prochains jours',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: onRefresh,
                  ),
              ],
            ),
          ),

          // Forecast List
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: forecasts.length,
              itemBuilder: (context, index) {
                return _buildForecastDay(context, forecasts[index], isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastDay(BuildContext context, WeatherForecast forecast, bool isDark) {
    final isToday = DateUtils.isSameDay(forecast.date, DateTime.now());
    final dayName = isToday
        ? 'Aujourd\'hui'
        : DateFormat('EEE', 'fr').format(forecast.date);

    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: forecast.hasAlert
            ? Colors.orange.shade50
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: forecast.hasAlert
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            DateFormat('dd/MM').format(forecast.date),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Icon(
            _getWeatherIcon(forecast.conditionMeteo),
            color: _getWeatherColor(forecast.conditionMeteo),
            size: 28,
          ),
          Column(
            children: [
              Text(
                '${forecast.temperatureMax.round()}°',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${forecast.temperatureMin.round()}°',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (forecast.precipitation > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, size: 10, color: Colors.blue.shade700),
                const SizedBox(width: 2),
                Text(
                  '${forecast.precipitation.round()}mm',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleille':
      case 'clear':
        return Icons.wb_sunny;
      case 'nuageux':
      case 'clouds':
        return Icons.cloud;
      case 'pluvieux':
      case 'rain':
        return Icons.water_drop;
      case 'orageux':
      case 'thunderstorm':
        return Icons.thunderstorm;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleille':
      case 'clear':
        return Colors.orange;
      case 'nuageux':
      case 'clouds':
        return Colors.grey;
      case 'pluvieux':
      case 'rain':
        return Colors.blue;
      case 'orageux':
      case 'thunderstorm':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
