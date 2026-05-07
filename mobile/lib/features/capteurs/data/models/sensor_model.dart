import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';

class SensorModel extends Sensor {
  SensorModel({
    required super.id,
    required super.code,
    required super.nom,
    required super.type,
    required super.status,
    super.parcelleNom,
    required super.niveauBatterie,
    required super.signalForce,
    required super.lastUpdate,
    super.lastValue,
    super.unit,
    super.nitrogen,
    super.phosphorus,
    super.potassium,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    // Map signal level (int dBm or similar) to 'fort'/'moyen'/'faible'
    // This logic might need refinement based on real API data
    String signal = 'moyen';
    // if (json['signal'] > ...) signal = 'fort';

    // Map signal strength from int to label
    final signalValue = json['signal'];
    if (signalValue is num) {
      if (signalValue > 70) {
        signal = 'fort';
      } else if (signalValue > 40) {
        signal = 'moyen';
      } else {
        signal = 'faible';
      }
    }

    return SensorModel(
      id: json['id'] ?? '',
      code: json['code'] ?? json['id'] ?? '',
      nom: json['nom'] ?? 'Capteur sans nom',
      type: json['type'] ?? 'Inconnu',
      status: (json['statut'] ?? json['status'] ?? 'inactif')
          .toString()
          .toLowerCase(),
      parcelleNom: json['parcelle_nom'],
      niveauBatterie:
          double.tryParse(
            json['batterie']?.toString() ??
                json['niveau_batterie']?.toString() ??
                '0',
          ) ??
          0.0,
      signalForce: signal,
      lastUpdate: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      lastValue:
          double.tryParse(
            json['derniere_valeur']?.toString() ??
                json['derniereMesure']?['valeur']?.toString() ??
                '0',
          ) ??
          0.0,
      unit: json['unite']?.toString() ?? json['unite_mesure']?.toString(),
      nitrogen: json['nitrogen'] != null
          ? double.tryParse(json['nitrogen'].toString())
          : null,
      phosphorus: json['phosphorus'] != null
          ? double.tryParse(json['phosphorus'].toString())
          : null,
      potassium: json['potassium'] != null
          ? double.tryParse(json['potassium'].toString())
          : null,
    );
  }
}
