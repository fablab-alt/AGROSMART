import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String nom;
  final String? description;
  final String categorie;
  final double prix;
  final String? unite;
  final double quantiteDisponible;
  final String? localisation;
  final List<String> images;
  final String vendeurId;
  final String? vendeurNom;
  final String? vendeurTelephone;
  final DateTime createdAt;
  // Location de matériel
  final String typeOffre;          // 'vente' (default) | 'location'
  final double? prixLocationJour;  // prix par jour si location
  final int? dureeMinLocation;     // durée minimale en jours
  final double? caution;           // caution exigée
  final String? etat;              // 'neuf', 'bon', 'moyen', 'usé'

  const Product({
    required this.id,
    required this.nom,
    this.description,
    required this.categorie,
    required this.prix,
    this.unite,
    required this.quantiteDisponible,
    this.localisation,
    required this.images,
    required this.vendeurId,
    this.vendeurNom,
    this.vendeurTelephone,
    required this.createdAt,
    this.typeOffre = 'vente',
    this.prixLocationJour,
    this.dureeMinLocation,
    this.caution,
    this.etat,
  });

  bool get estLocation => typeOffre == 'location';
  double get prixAffiche => estLocation ? (prixLocationJour ?? prix) : prix;

  @override
  List<Object?> get props => [
        id,
        nom,
        description,
        categorie,
        prix,
        unite,
        quantiteDisponible,
        localisation,
        images,
        vendeurId,
        createdAt,
        typeOffre,
        prixLocationJour,
        dureeMinLocation,
        caution,
        etat,
      ];
}
