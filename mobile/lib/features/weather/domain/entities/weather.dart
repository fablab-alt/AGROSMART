import 'package:equatable/equatable.dart';

/// Weather forecast for a specific day
class WeatherForecast extends Equatable {
  final String id;
  final DateTime date;
  final String location;
  final double temperatureMin;
  final double temperatureMax;
  final double temperatureMoyenne;
  final int humidite;
  final double precipitation;
  final double precipitationProbabilite;
  final String conditionMeteo; // 'ensoleille', 'nuageux', 'pluvieux', 'orageux'
  final double vitesseVent;
  final String directionVent;
  final int indiceUV;
  final String iconWeather;
  final bool risqueSecheresse;
  final bool risquePluiesIntenses;
  final bool risqueVentsViolents;

  final double soilTemperature;
  final double soilMoisture;

  const WeatherForecast({
    required this.id,
    required this.date,
    required this.location,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.temperatureMoyenne,
    required this.humidite,
    required this.precipitation,
    required this.precipitationProbabilite,
    required this.conditionMeteo,
    required this.vitesseVent,
    required this.directionVent,
    required this.indiceUV,
    required this.iconWeather,
    required this.risqueSecheresse,
    required this.risquePluiesIntenses,
    required this.risqueVentsViolents,
    this.soilTemperature = 0.0,
    this.soilMoisture = 0.0,
  });

  /// Check if day has weather alert
  bool get hasAlert => risqueSecheresse || risquePluiesIntenses || risqueVentsViolents;

  /// Get alert type
  String? get alertType {
    if (risqueSecheresse) return 'Sécheresse';
    if (risquePluiesIntenses) return 'Pluies intenses';
    if (risqueVentsViolents) return 'Vents violents';
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        date,
        location,
        temperatureMin,
        temperatureMax,
        temperatureMoyenne,
        humidite,
        precipitation,
        precipitationProbabilite,
        conditionMeteo,
        vitesseVent,
        directionVent,
        indiceUV,
        iconWeather,
        risqueSecheresse,
        risquePluiesIntenses,
        risqueVentsViolents,
        soilTemperature,
        soilMoisture,
      ];

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      id: 'forecast_${json['date']}', // Simple ID generation
      date: DateTime.parse(json['date']),
      location: 'Localisation', // Not passed in item
      temperatureMin: (json['temp_min'] as num).toDouble(),
      temperatureMax: (json['temp_max'] as num).toDouble(),
      temperatureMoyenne: (json['temp_moyenne'] as num).toDouble(),
      humidite: (json['humidite'] as num?)?.toInt() ?? 70, // Default to 70 if missing
      precipitation: (json['precipitation_totale'] as num).toDouble(),
      precipitationProbabilite: (json['probabilite_pluie'] as num).toDouble(),
      conditionMeteo: json['description'] ?? '',
      vitesseVent: (json['vitesse_vent'] as num?)?.toDouble() ?? 0.0,
      directionVent: json['direction_vent'] ?? 'N',
      indiceUV: (json['uv_index'] as num?)?.toInt() ?? 0,
      iconWeather: json['icone'] ?? '01d',
      risqueSecheresse: false, // Calculated on backend or frontend? Backend usually.
      risquePluiesIntenses: (json['precipitation_totale'] as num) > 20,
      risqueVentsViolents: (json['vitesse_vent'] as num?) != null && (json['vitesse_vent'] as num) > 50,
      soilTemperature: (json['soil_temperature'] as num?)?.toDouble() ?? 0.0,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Weather alert
class WeatherAlert extends Equatable {
  final String id;
  final String type; // 'secheresse', 'pluies_intenses', 'vents_violents', 'temperature_extreme'
  final String niveau; // 'info', 'attention', 'alerte', 'danger'
  final String titre;
  final String message;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? region;
  final String? recommandation;

  const WeatherAlert({
    required this.id,
    required this.type,
    required this.niveau,
    required this.titre,
    required this.message,
    required this.dateDebut,
    required this.dateFin,
    this.region,
    this.recommandation,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] ?? 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: json['type'] ?? 'info',
      niveau: json['niveau'] ?? 'info',
      titre: json['titre'] ?? 'Alerte',
      message: json['message'] ?? '',
      dateDebut: json['date_debut'] != null ? DateTime.parse(json['date_debut']) : DateTime.now(),
      dateFin: json['date_fin'] != null ? DateTime.parse(json['date_fin']) : DateTime.now().add(const Duration(hours: 24)),
      region: json['region'],
      recommandation: json['recommandation'],
    );
  }

  /// Check if alert is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(dateDebut) && now.isBefore(dateFin);
  }

  @override
  List<Object?> get props => [
        id,
        type,
        niveau,
        titre,
        message,
        dateDebut,
        dateFin,
        region,
        recommandation,
      ];
}
