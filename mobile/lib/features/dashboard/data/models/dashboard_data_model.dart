import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/dashboard_data.dart';

part 'dashboard_data_model.g.dart';

@JsonSerializable()
class DashboardDataModel extends DashboardData {
  @override
  final WeatherModel weather;
  @override
  final StatsModel stats;
  @override
  final List<AlertModel> alerts;

  const DashboardDataModel({
    required this.weather,
    required this.stats,
    required this.alerts,
  }) : super(weather: weather, stats: stats, alerts: alerts);

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) => _$DashboardDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardDataModelToJson(this);
}

@JsonSerializable()
class WeatherModel extends Weather {
  const WeatherModel({
    required super.temperature,
    required super.humidity,
    required super.description,
    required super.icon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) => _$WeatherModelFromJson(json);
}

@JsonSerializable()
class StatsModel extends Stats {
  const StatsModel({
    required super.yield,
    required super.roi,
    required super.soilHealth,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) => _$StatsModelFromJson(json);
}

@JsonSerializable()
class AlertModel extends Alert {
  const AlertModel({
    required super.id,
    required super.title,
    required super.message,
    required super.level,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => _$AlertModelFromJson(json);
}
