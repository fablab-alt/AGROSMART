import 'package:agriculture/features/weather/domain/entities/weather.dart';

class WeatherForecastModel extends WeatherForecast {
  const WeatherForecastModel({
    required super.id,
    required super.date,
    required super.location,
    required super.temperatureMin,
    required super.temperatureMax,
    required super.temperatureMoyenne,
    required super.humidite,
    required super.precipitation,
    required super.precipitationProbabilite,
    required super.conditionMeteo,
    required super.vitesseVent,
    required super.directionVent,
    required super.indiceUV,
    required super.iconWeather,
    super.risqueSecheresse = false,
    super.risquePluiesIntenses = false,
    super.risqueVentsViolents = false,
  });

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    return WeatherForecastModel(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      location: json['location'] ?? '',
      temperatureMin: double.tryParse(json['temperature_min']?.toString() ?? '0') ?? 0.0,
      temperatureMax: double.tryParse(json['temperature_max']?.toString() ?? '0') ?? 0.0,
      temperatureMoyenne: double.tryParse(json['temperature_moyenne']?.toString() ?? '0') ?? 0.0,
      humidite: json['humidite'] ?? 0,
      precipitation: double.tryParse(json['precipitation']?.toString() ?? '0') ?? 0.0,
      precipitationProbabilite: double.tryParse(json['precipitation_probabilite']?.toString() ?? '0') ?? 0.0,
      conditionMeteo: json['condition_meteo'] ?? 'inconnu',
      vitesseVent: double.tryParse(json['vitesse_vent']?.toString() ?? '0') ?? 0.0,
      directionVent: json['direction_vent'] ?? 'N',
      indiceUV: json['indice_uv'] ?? 0,
      iconWeather: json['icon_weather'] ?? 'sunny',
      risqueSecheresse: json['risque_secheresse'] ?? false,
      risquePluiesIntenses: json['risque_pluies_intenses'] ?? false,
      risqueVentsViolents: json['risque_vents_violents'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'location': location,
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'temperature_moyenne': temperatureMoyenne,
      'humidite': humidite,
      'precipitation': precipitation,
      'precipitation_probabilite': precipitationProbabilite,
      'condition_meteo': conditionMeteo,
      'vitesse_vent': vitesseVent,
      'direction_vent': directionVent,
      'indice_uv': indiceUV,
      'icon_weather': iconWeather,
      'risque_secheresse': risqueSecheresse,
      'risque_pluies_intenses': risquePluiesIntenses,
      'risque_vents_violents': risqueVentsViolents,
    };
  }
}

class WeatherAlertModel extends WeatherAlert {
  const WeatherAlertModel({
    required super.id,
    required super.type,
    required super.niveau,
    required super.titre,
    required super.message,
    required super.dateDebut,
    required super.dateFin,
    super.region,
    super.recommandation,
  });

  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) {
    return WeatherAlertModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      niveau: json['niveau'] ?? 'info',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      dateDebut: DateTime.parse(json['date_debut']),
      dateFin: DateTime.parse(json['date_fin']),
      region: json['region'],
      recommandation: json['recommandation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'niveau': niveau,
      'titre': titre,
      'message': message,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
      'region': region,
      'recommandation': recommandation,
    };
  }
}
