import '../../domain/entities/wishlist.dart';

class WishlistModel extends Wishlist {
  const WishlistModel({
    required super.id,
    required super.userId,
    required super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] as String,
      userId: json['utilisateur_id'] as String,
      items:
          (json['items'] as List?)
              ?.map((item) => WishlistItemModel.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'utilisateur_id': userId,
      'items': items
          .map((item) => WishlistItemModel.fromEntity(item).toJson())
          .toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({
    required super.id,
    required super.produitId,
    required super.nom,
    required super.prix,
    super.imageUrl,
    required super.disponible,
    required super.addedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      produitId: json['produit_id'] as String,
      nom: json['nom'] as String,
      prix: (json['prix'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      disponible: json['disponible'] as bool? ?? true,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit_id': produitId,
      'nom': nom,
      'prix': prix,
      'image_url': imageUrl,
      'disponible': disponible,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory WishlistItemModel.fromEntity(WishlistItem entity) {
    return WishlistItemModel(
      id: entity.id,
      produitId: entity.produitId,
      nom: entity.nom,
      prix: entity.prix,
      imageUrl: entity.imageUrl,
      disponible: entity.disponible,
      addedAt: entity.addedAt,
    );
  }
}
