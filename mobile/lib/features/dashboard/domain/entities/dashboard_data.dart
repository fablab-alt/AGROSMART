import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final Weather weather;
  final Stats stats;
  final List<Alert> alerts;

  const DashboardData({
    required this.weather,
    required this.stats,
    required this.alerts,
  });

  @override
  List<Object> get props => [weather, stats, alerts];
}

class Weather extends Equatable {
  final double temperature;
  final double humidity;
  final String description;
  final String icon;

  const Weather({
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.icon,
  });

  @override
  List<Object> get props => [temperature, humidity, description, icon];
}

class Stats extends Equatable {
  final double yield; // Rendement
  final double roi; // Retour sur investissement
  final double soilHealth; // Santé du sol (0-100)

  const Stats({
    required this.yield,
    required this.roi,
    required this.soilHealth,
  });

  @override
  List<Object> get props => [yield, roi, soilHealth];
}

class Alert extends Equatable {
  final String id;
  final String title;
  final String message;
  final String level; // critical, warning, info

  const Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
  });

  @override
  List<Object> get props => [id, title, message, level];
}
