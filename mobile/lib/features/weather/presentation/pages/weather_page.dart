import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weather_bloc.dart';
import '../widgets/weather_forecast_card.dart';
import '../widgets/weather_alerts_card.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Météo Détaillée'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WeatherForecastLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WeatherBloc>().add(RefreshWeather());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alerts
                    if (state.alerts.isNotEmpty) ...[
                      WeatherAlertsCard(alerts: state.alerts),
                      const SizedBox(height: 24),
                    ],

                    // Current Weather Header
                    if (state.forecasts.isNotEmpty)
                      _buildCurrentWeatherHeader(context, state.forecasts.first),
                    
                    const SizedBox(height: 24),

                    // Weather Details Grid
                    if (state.forecasts.isNotEmpty)
                      _buildDetailsGrid(context, state.forecasts.first),

                    const SizedBox(height: 24),

                    // Forecast Host
                    const Text(
                      'Prévisions 10 Jours',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    WeatherForecast10DaysCard(
                      forecasts: state.forecasts,
                      onRefresh: () {}, // Handled by parent refresh indicator
                    ),
                  ],
                ),
              ),
            );
          } else if (state is WeatherError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Erreur: ${state.message}"),
                  ElevatedButton(
                    onPressed: () => context.read<WeatherBloc>().add(RefreshWeather()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text("Aucune donnée météo."));
        },
      ),
    );
  }
  Widget _buildCurrentWeatherHeader(BuildContext context, dynamic forecast) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
             color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
             blurRadius: 15,
             offset: const Offset(0, 8),
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     "Aujourd'hui", 
                     style: const TextStyle(color: Colors.white70, fontSize: 16)
                   ),
                   const SizedBox(height: 4),
                   Text(
                     "${forecast.temperatureMoyenne.round()}°C",
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 48,
                       fontWeight: FontWeight.bold
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     forecast.conditionMeteo,
                     style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                   )
                 ],
               ),
               Icon(
                 _getWeatherIcon(forecast.conditionMeteo),
                 color: Colors.white,
                 size: 80,
               )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Min: ${forecast.temperatureMin.round()}°", style: const TextStyle(color: Colors.white70)),
              Text("Max: ${forecast.temperatureMax.round()}°", style: const TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context, dynamic forecast) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildDetailItem(context, Icons.water_drop, "Humidité", "${forecast.humidite}%", Colors.blue),
        _buildDetailItem(context, Icons.air, "Vent", "${forecast.vitesseVent} km/h", Colors.grey),
        _buildDetailItem(context, Icons.speed, "Pression", "1015 hPa", Colors.purple), // Placeholder if missing
        _buildDetailItem(context, Icons.sunny, "Indice UV", "${forecast.indiceUV}", Colors.orange),
        _buildDetailItem(context, Icons.umbrella, "Précipitations", "${forecast.precipitation} mm", Colors.blueGrey),
        _buildDetailItem(context, Icons.grain, "Probabilité", "${forecast.precipitationProbabilite.round()}%", Colors.indigo),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'ensoleille': return Icons.wb_sunny;
      case 'nuageux': return Icons.cloud;
      case 'pluvieux': return Icons.water_drop;
      case 'orageux': return Icons.thunderstorm;
      default: return Icons.wb_cloudy;
    }
  }
}
