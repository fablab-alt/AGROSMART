import 'package:equatable/equatable.dart';

/// Types d'annonce dans la communauté
enum ListingType {
  vente, // Vente d'équipement
  location, // Location d'équipement
  service, // Service (labour, transport, etc.)
}

/// Statut d'une annonce
enum ListingStatus { active, reserved, sold, expired }

/// Annonce communautaire (vente/location d'équipement ou service)
class CommunityListing extends Equatable {
  final String id;
  final String vendeurId;
  final String vendeurNom;
  final String? vendeurPhoto;
  final String titre;
  final String description;
  final ListingType type;
  final String categorie; // tracteur, semoir, pulverisateur, etc.
  final double prix;
  final String? prixUnite; // /jour, /heure, ou null pour vente
  final bool negociable;
  final String etat; // neuf, excellent, bon, moyen, usage
  final List<String> images;
  final String localisation;
  final double? latitude;
  final double? longitude;
  final ListingStatus statut;
  final int vues;
  final int favoris;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? specifications;

  const CommunityListing({
    required this.id,
    required this.vendeurId,
    required this.vendeurNom,
    this.vendeurPhoto,
    required this.titre,
    required this.description,
    required this.type,
    required this.categorie,
    required this.prix,
    this.prixUnite,
    this.negociable = false,
    required this.etat,
    required this.images,
    required this.localisation,
    this.latitude,
    this.longitude,
    this.statut = ListingStatus.active,
    this.vues = 0,
    this.favoris = 0,
    required this.createdAt,
    this.expiresAt,
    this.specifications,
  });

  bool get isForSale => type == ListingType.vente;
  bool get isForRent => type == ListingType.location;
  bool get isService => type == ListingType.service;
  bool get isActive => statut == ListingStatus.active;

  String get typeLabel {
    switch (type) {
      case ListingType.vente:
        return 'À vendre';
      case ListingType.location:
        return 'À louer';
      case ListingType.service:
        return 'Service';
    }
  }

  String get priceDisplay {
    final priceStr = '${prix.toStringAsFixed(0)} FCFA';
    if (prixUnite != null) {
      return '$priceStr$prixUnite';
    }
    return priceStr;
  }

  @override
  List<Object?> get props => [
    id,
    vendeurId,
    titre,
    type,
    prix,
    statut,
    createdAt,
  ];
}

/// Demande de contact/réservation pour une annonce
class ListingInquiry extends Equatable {
  final String id;
  final String listingId;
  final String demandeurId;
  final String demandeurNom;
  final String message;
  final DateTime? dateProposee;
  final int? dureeJours;
  final String statut; // pending, accepted, rejected
  final DateTime createdAt;

  const ListingInquiry({
    required this.id,
    required this.listingId,
    required this.demandeurId,
    required this.demandeurNom,
    required this.message,
    this.dateProposee,
    this.dureeJours,
    this.statut = 'pending',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, listingId, demandeurId, statut];
}
