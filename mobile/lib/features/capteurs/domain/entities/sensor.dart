class Sensor {
  final String id;
  final String code;
  final String nom;
  final String type;
  final String status;
  final String? parcelleNom;
  final double niveauBatterie;
  final String signalForce; // 'fort', 'moyen', 'faible'
  final DateTime lastUpdate;

  Sensor({
    required this.id,
    required this.code,
    required this.nom,
    required this.type,
    required this.status,
    this.parcelleNom,
    required this.niveauBatterie,
    required this.signalForce,
    required this.lastUpdate,
    this.lastValue,
    this.unit,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
  });

  final double? lastValue;
  final String? unit;
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
}
