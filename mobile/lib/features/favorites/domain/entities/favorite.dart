import 'package:equatable/equatable.dart';

/// Entité représentant un produit favori
class FavoriteItem extends Equatable {
  final String id;
  final String produitId;
  final String nom;
  final String? description;
  final double prix;
  final String? unite;
  final int stock;
  final List<String> images;
  final String categorie;
  final bool actif;
  final String? vendeurNom;
  final DateTime createdAt;

  const FavoriteItem({
    required this.id,
    required this.produitId,
    required this.nom,
    this.description,
    required this.prix,
    this.unite,
    required this.stock,
    required this.images,
    required this.categorie,
    required this.actif,
    this.vendeurNom,
    required this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final produit = json['produit'] as Map<String, dynamic>?;
    final vendeur = produit?['vendeur'] as Map<String, dynamic>?;

    return FavoriteItem(
      id: json['id'] as String,
      produitId: produit?['id'] as String? ?? json['produitId'] as String,
      nom: produit?['nom'] as String? ?? 'Produit inconnu',
      description: produit?['description'] as String?,
      prix: (produit?['prix'] as num?)?.toDouble() ?? 0.0,
      unite: produit?['unite'] as String?,
      stock: produit?['stock'] as int? ?? 0,
      images:
          (produit?['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categorie: produit?['categorie'] as String? ?? 'Autre',
      actif: produit?['actif'] as bool? ?? true,
      vendeurNom: vendeur != null
          ? '${vendeur['nom'] ?? ''} ${vendeur['prenoms'] ?? ''}'.trim()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  bool get isAvailable => actif && stock > 0;

  String? get imageUrl => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [
    id,
    produitId,
    nom,
    description,
    prix,
    unite,
    stock,
    images,
    categorie,
    actif,
    vendeurNom,
    createdAt,
  ];
}
