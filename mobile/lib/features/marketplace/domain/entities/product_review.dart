import 'package:equatable/equatable.dart';

class ProductReview extends Equatable {
  final String id;
  final String produitId;
  final String userId;
  final String userName;
  final int note; // 1-5 étoiles
  final String? commentaire;
  final DateTime createdAt;
  final List<String>? images;

  const ProductReview({
    required this.id,
    required this.produitId,
    required this.userId,
    required this.userName,
    required this.note,
    this.commentaire,
    required this.createdAt,
    this.images,
  });

  @override
  List<Object?> get props => [
    id,
    produitId,
    userId,
    note,
    commentaire,
    createdAt,
  ];
}

class ReviewStats extends Equatable {
  final double moyenneNote;
  final int nombreAvis;
  final Map<int, int> repartitionNotes; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  const ReviewStats({
    required this.moyenneNote,
    required this.nombreAvis,
    required this.repartitionNotes,
  });

  @override
  List<Object?> get props => [moyenneNote, nombreAvis, repartitionNotes];
}
