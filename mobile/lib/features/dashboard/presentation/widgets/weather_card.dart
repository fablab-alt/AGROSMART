import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_data.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Météo Actuelle',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature}°C',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
                // In a real app, we would load the icon from network or assets based on weather.icon
                const Icon(Icons.wb_sunny, color: Colors.yellow, size: 48),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Humidité: ${weather.humidity}%',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
