import 'package:equatable/equatable.dart';

/// GPS Coordinate for polygon delineation
class GeoPoint extends Equatable {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Culture Reference
class CultureInfo extends Equatable {
  final String id;
  final String nom;
  final String nomScientifique;
  final String? nomLocalBaoule;
  final String? nomLocalMalinke;
  final String? nomLocalSenoufo;
  final String categorie;

  const CultureInfo({
    required this.id,
    required this.nom,
    required this.nomScientifique,
    this.nomLocalBaoule,
    this.nomLocalMalinke,
    this.nomLocalSenoufo,
    required this.categorie,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        nomScientifique,
        nomLocalBaoule,
        nomLocalMalinke,
        nomLocalSenoufo,
        categorie,
      ];
}

enum ParcelleHealth { optimal, surveillance, critique }

/// Parcelle Entity - Enhanced for CDC Multi-Parcel Management
class Parcelle extends Equatable {
  final String id;
  final String nom;
  final double superficie; // in hectares
  final String uniteSuperficie; // 'hectare' or 'm2'
  
  // Culture Information
  final CultureInfo? cultureActuelle;
  final String? cultureLegacy; // For backward compatibility
  
  // GPS & Mapping
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final List<GeoPoint>? polygonDelimitation; // GPS polygon points
  
  // Soil & Status
  final String typeSol;
  final String status; // 'active', 'en_repos', 'preparee', etc.
  final ParcelleHealth sante;
  
  // Sensor Data (current readings)
  final int? humidite;
  final int? temperature;
  final DateTime? lastUpdate;
  
  // Metadata
  final DateTime? dateAcquisition;
  final String? description;
  
  // Plantation info (if active)
  final String? plantationId;
  final DateTime? dateSemis;
  final DateTime? dateRecoltePrevue;

  const Parcelle({
    required this.id,
    required this.nom,
    required this.superficie,
    this.uniteSuperficie = 'hectare',
    this.cultureActuelle,
    this.cultureLegacy,
    this.latitude,
    this.longitude,
    this.altitude,
    this.polygonDelimitation,
    required this.typeSol,
    required this.status,
    this.sante = ParcelleHealth.optimal,
    this.humidite,
    this.temperature,
    this.lastUpdate,
    this.dateAcquisition,
    this.description,
    this.plantationId,
    this.dateSemis,
    this.dateRecoltePrevue,
  });

  /// Get culture name (prioritize current culture object, fallback to legacy)
  String get culture => cultureActuelle?.nom ?? cultureLegacy ?? 'Non définie';

  /// Check if parcel has GPS coordinates
  bool get hasGPSCoordinates => latitude != null && longitude != null;

  /// Check if parcel has polygon delineation
  bool get hasPolygonDelineation =>
      polygonDelimitation != null && polygonDelimitation!.length >= 3;

  /// Calculate polygon area (simplified - for display purposes)
  double? get calculatedArea {
    if (!hasPolygonDelineation) return null;
    // Simple area calculation would go here
    // For now, return the stored superficie
    return superficie;
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        superficie,
        uniteSuperficie,
        cultureActuelle,
        cultureLegacy,
        latitude,
        longitude,
        altitude,
        polygonDelimitation,
        typeSol,
        status,
        sante,
        humidite,
        temperature,
        lastUpdate,
        dateAcquisition,
        description,
        plantationId,
        dateSemis,
        dateRecoltePrevue,
      ];
}
