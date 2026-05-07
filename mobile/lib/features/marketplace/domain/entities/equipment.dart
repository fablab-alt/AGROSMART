import 'package:equatable/equatable.dart';

/// Equipment available for rental
class Equipment extends Equatable {
  final String id;
  final String nom;
  final String categorie;
  final String? description;
  final double prixParJour;
  final double caution;
  final bool disponible;
  final String etat; // 'excellent', 'bon', 'moyen'
  final String? localisation;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final Map<String, dynamic>? specifications;
  final String proprietaireId;
  final DateTime createdAt;

  const Equipment({
    required this.id,
    required this.nom,
    required this.categorie,
    this.description,
    required this.prixParJour,
    this.caution = 0,
    required this.disponible,
    required this.etat,
    this.localisation,
    this.latitude,
    this.longitude,
    required this.images,
    this.specifications,
    required this.proprietaireId,
    required this.createdAt,
  });

  /// Check if equipment has GPS coordinates
  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        nom,
        categorie,
        description,
        prixParJour,
        caution,
        disponible,
        etat,
        localisation,
        latitude,
        longitude,
        images,
        specifications,
        proprietaireId,
        createdAt,
      ];
}

/// Rental transaction  
class Rental extends Equatable {
  final String id;
  final String equipmentId;
  final String locataireId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int dureeJours;
  final double prixTotal;
  final double cautionVersee;
  final bool cautionRetournee;
  final String statut; // 'demande', 'confirmee', 'en_cours', 'terminee', 'annulee'
  final String? commentaireLocataire;
  final String? commentaireProprietaire;
  final int? evaluationNote;
  final DateTime createdAt;

  const Rental({
    required this.id,
    required this.equipmentId,
    required this.locataireId,
    required this.dateDebut,
    required this.dateFin,
    required this.dureeJours,
    required this.prixTotal,
    this.cautionVersee = 0,
    this.cautionRetournee = false,
    required this.statut,
    this.commentaireLocataire,
    this.commentaireProprietaire,
    this.evaluationNote,
    required this.createdAt,
  });

  /// Check if rental is active
  bool get isActive => statut == 'en_cours';

  /// Check if rental can be rated
  bool get canBeRated => statut == 'terminee' && evaluationNote == null;

  @override
  List<Object?> get props => [
        id,
        equipmentId,
        locataireId,
        dateDebut,
        dateFin,
        dureeJours,
        prixTotal,
        cautionVersee,
        cautionRetournee,
        statut,
        commentaireLocataire,
        commentaireProprietaire,
        evaluationNote,
        createdAt,
      ];
}
