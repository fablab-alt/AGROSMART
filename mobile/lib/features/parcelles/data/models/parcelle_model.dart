import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

class ParcelleModel extends Parcelle {
  const ParcelleModel({
    required super.id,
    required super.nom,
    required super.superficie,
    required super.cultureActuelle,
    required super.typeSol,
    required super.status,
    required super.humidite,
    required super.temperature,
    required super.lastUpdate,
    super.sante = ParcelleHealth.optimal,
    super.latitude,
    super.longitude,
  });

  factory ParcelleModel.fromJson(Map<String, dynamic> json) {
    // Adapter selon la réponse API réelle
    return ParcelleModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? 'Sans nom',
      superficie: _parseDouble(json['superficie'] ?? json['superficie_hectares']) ?? 0.0,
      cultureActuelle: json['culture_nom'] != null 
          ? CultureInfo(
              id: 'generated_id_${json['culture_nom']}',
              nom: json['culture_nom'],
              nomScientifique: 'Non spécifié',
              categorie: 'Culture vivrière', // Default
            ) 
          : null,
      typeSol: json['type_sol'] ?? 'Inconnu',
      status: json['status'] ?? 'active',
      sante: _parseHealth(json['sante']),
      humidite: _parseInt(json['humidite'] ?? json['derniere_humidite']) ?? 0,
      temperature: _parseInt(json['temperature'] ?? json['derniere_temperature']) ?? 0,
      lastUpdate: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
    );
  }

  static ParcelleHealth _parseHealth(String? value) {
    if (value == null) return ParcelleHealth.optimal;
    switch (value.toUpperCase()) {
      case 'OPTIMAL':
        return ParcelleHealth.optimal;
      case 'SURVEILLANCE':
        return ParcelleHealth.surveillance;
      case 'CRITIQUE':
        return ParcelleHealth.critique;
      default:
        return ParcelleHealth.optimal;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'superficie_hectares': superficie,
      'type_sol': typeSol,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
