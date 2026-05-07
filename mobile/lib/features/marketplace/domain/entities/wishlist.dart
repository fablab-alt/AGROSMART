import 'package:equatable/equatable.dart';

class Wishlist extends Equatable {
  final String id;
  final String userId;
  final List<WishlistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wishlist({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, items, createdAt, updatedAt];
}

class WishlistItem extends Equatable {
  final String id;
  final String produitId;
  final String nom;
  final double prix;
  final String? imageUrl;
  final bool disponible;
  final DateTime addedAt;

  const WishlistItem({
    required this.id,
    required this.produitId,
    required this.nom,
    required this.prix,
    this.imageUrl,
    required this.disponible,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
    id,
    produitId,
    nom,
    prix,
    imageUrl,
    disponible,
    addedAt,
  ];
}
