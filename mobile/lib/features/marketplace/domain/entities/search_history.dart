import 'package:equatable/equatable.dart';

class SearchHistory extends Equatable {
  final List<SearchQuery> queries;

  const SearchHistory({required this.queries});

  @override
  List<Object?> get props => [queries];
}

class SearchQuery extends Equatable {
  final String query;
  final DateTime timestamp;
  final int resultCount;

  const SearchQuery({
    required this.query,
    required this.timestamp,
    required this.resultCount,
  });

  @override
  List<Object?> get props => [query, timestamp, resultCount];
}

class ProductRecommendation extends Equatable {
  final String id;
  final String produitId;
  final String nom;
  final double prix;
  final String? imageUrl;
  final String raison; // "Populaire", "Basé sur votre historique", etc.
  final double score;

  const ProductRecommendation({
    required this.id,
    required this.produitId,
    required this.nom,
    required this.prix,
    this.imageUrl,
    required this.raison,
    required this.score,
  });

  @override
  List<Object?> get props => [
    id,
    produitId,
    nom,
    prix,
    imageUrl,
    raison,
    score,
  ];
}
