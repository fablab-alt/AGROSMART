import '../../domain/entities/product_review.dart';

class ProductReviewModel extends ProductReview {
  const ProductReviewModel({
    required super.id,
    required super.produitId,
    required super.userId,
    required super.userName,
    required super.note,
    super.commentaire,
    required super.createdAt,
    super.images,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: json['id'] as String,
      produitId: json['produit_id'] as String,
      userId: json['utilisateur_id'] as String,
      userName: json['utilisateur_nom'] as String,
      note: json['note'] as int,
      commentaire: json['commentaire'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      images: json['images'] != null
          ? (json['images'] as List).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit_id': produitId,
      'utilisateur_id': userId,
      'utilisateur_nom': userName,
      'note': note,
      'commentaire': commentaire,
      'created_at': createdAt.toIso8601String(),
      'images': images,
    };
  }

  factory ProductReviewModel.fromEntity(ProductReview entity) {
    return ProductReviewModel(
      id: entity.id,
      produitId: entity.produitId,
      userId: entity.userId,
      userName: entity.userName,
      note: entity.note,
      commentaire: entity.commentaire,
      createdAt: entity.createdAt,
      images: entity.images,
    );
  }
}

class ReviewStatsModel extends ReviewStats {
  const ReviewStatsModel({
    required super.moyenneNote,
    required super.nombreAvis,
    required super.repartitionNotes,
  });

  factory ReviewStatsModel.fromJson(Map<String, dynamic> json) {
    return ReviewStatsModel(
      moyenneNote: (json['moyenne_note'] as num).toDouble(),
      nombreAvis: json['nombre_avis'] as int,
      repartitionNotes: Map<int, int>.from(json['repartition_notes'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moyenne_note': moyenneNote,
      'nombre_avis': nombreAvis,
      'repartition_notes': repartitionNotes,
    };
  }
}
