import 'package:equatable/equatable.dart';

/// Modèle pour une métrique IoT d'un capteur
class IotMetricModel extends Equatable {
  final String capteurId;
  final String type; // NPK, HUMIDITE_SOL, TEMPERATURE_AMBIANTE, etc.
  final String nom;
  final String unite;
  final String statut;
  final double? valeur;
  final DateTime? timestamp;
  final double seuilMin;
  final double seuilMax;
  final int? signal;
  final int? batterie;
  final bool horsSeuils;

  const IotMetricModel({
    required this.capteurId,
    required this.type,
    required this.nom,
    required this.unite,
    this.statut = 'actif',
    this.valeur,
    this.timestamp,
    required this.seuilMin,
    required this.seuilMax,
    this.signal,
    this.batterie,
    this.horsSeuils = false,
  });

  factory IotMetricModel.fromJson(Map<String, dynamic> json) {
    return IotMetricModel(
      capteurId: json['capteur_id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      nom: json['nom'] ?? 'Capteur',
      unite: json['unite'] ?? '',
      statut: (json['statut'] ?? json['status'] ?? 'actif')
          .toString()
          .toLowerCase(),
      valeur: _parseDouble(json['valeur']),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      seuilMin: _parseDouble(json['seuil_min']) ?? 0.0,
      seuilMax: _parseDouble(json['seuil_max']) ?? 100.0,
      signal: json['signal'] as int?,
      batterie: json['batterie'] as int?,
      horsSeuils: json['hors_seuils'] ?? false,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Formater la valeur avec l'unité
  String get formattedValue {
    if (valeur == null) return 'N/A';
    if (unite == '%') {
      return '${valeur!.toStringAsFixed(0)}%';
    }
    if (unite == '°C' || unite == 'C') {
      return '${valeur!.toStringAsFixed(1)}°C';
    }
    return '${valeur!.toStringAsFixed(1)} $unite';
  }

  /// Nom d'affichage simplifié pour le type de capteur
  String get displayName {
    switch (type) {
      case 'HUMIDITE_SOL':
        return 'Humidité du Sol';
      case 'HUMIDITE_TEMPERATURE_AMBIANTE':
        return 'Température Ambiante';
      case 'NPK':
        return 'NPK';
      case 'UV':
        return 'UV';
      case 'DIRECTION_VENT':
        return 'Direction du Vent';
      case 'TRANSPIRATION_PLANTE':
        return 'Transpiration Plante';
      default:
        return nom;
    }
  }

  @override
  List<Object?> get props => [
    capteurId,
    type,
    nom,
    unite,
    statut,
    valeur,
    timestamp,
    seuilMin,
    seuilMax,
    signal,
    batterie,
    horsSeuils,
  ];
}

/// Modèle pour la réponse complète des métriques IoT
class IotMetricsResponse extends Equatable {
  final List<IotMetricModel> metrics;
  final Map<String, List<IotMetricModel>> groupedByType;
  final int totalCapteurs;
  final int capteursAvecDonnees;
  final String? message;

  const IotMetricsResponse({
    required this.metrics,
    required this.groupedByType,
    required this.totalCapteurs,
    required this.capteursAvecDonnees,
    this.message,
  });

  factory IotMetricsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    final metricsList =
        (data['metrics'] as List?)
            ?.map((m) => IotMetricModel.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    final groupedData = data['grouped_by_type'] as Map<String, dynamic>? ?? {};
    final grouped = <String, List<IotMetricModel>>{};

    groupedData.forEach((key, value) {
      grouped[key] = (value as List)
          .map((m) => IotMetricModel.fromJson(m as Map<String, dynamic>))
          .toList();
    });

    return IotMetricsResponse(
      metrics: metricsList,
      groupedByType: grouped,
      totalCapteurs: data['total_capteurs'] ?? 0,
      capteursAvecDonnees: data['capteurs_avec_donnees'] ?? 0,
      message: data['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    metrics,
    groupedByType,
    totalCapteurs,
    capteursAvecDonnees,
    message,
  ];
}
