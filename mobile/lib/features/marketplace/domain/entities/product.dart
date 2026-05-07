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
  });

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
      ];
}
