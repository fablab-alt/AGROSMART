import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<List<ProductReviewModel>> getProductReviews(String produitId);
  Future<ReviewStatsModel> getProductReviewStats(String produitId);
  Future<ProductReviewModel> createReview({
    required String produitId,
    required int note,
    String? commentaire,
    List<String>? images,
  });
  Future<ProductReviewModel> updateReview({
    required String reviewId,
    required int note,
    String? commentaire,
  });
  Future<void> deleteReview(String reviewId);
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient apiClient;

  ReviewRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ProductReviewModel>> getProductReviews(String produitId) async {
    try {
      final response = await apiClient.get('/produits/$produitId/avis');

      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => ProductReviewModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ReviewStatsModel> getProductReviewStats(String produitId) async {
    try {
      final response = await apiClient.get('/produits/$produitId/avis/stats');

      return ReviewStatsModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductReviewModel> createReview({
    required String produitId,
    required int note,
    String? commentaire,
    List<String>? images,
  }) async {
    try {
      final response = await apiClient.post(
        '/avis',
        data: {
          'produit_id': produitId,
          'note': note,
          'commentaire': commentaire,
          'images': images,
        },
      );

      return ProductReviewModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ProductReviewModel> updateReview({
    required String reviewId,
    required int note,
    String? commentaire,
  }) async {
    try {
      final response = await apiClient.put(
        '/avis/$reviewId',
        data: {'note': note, 'commentaire': commentaire},
      );

      return ProductReviewModel.fromJson(
        response.data['data'] ?? response.data,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      await apiClient.delete('/avis/$reviewId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final message =
        error.response?.data?['message'] ??
        error.response?.data?['error'] ??
        'Une erreur est survenue';

    switch (statusCode) {
      case 400:
        return Exception('Données invalides: $message');
      case 401:
        return Exception('Non autorisé: $message');
      case 403:
        return Exception('Accès refusé: $message');
      case 404:
        return Exception('Avis non trouvé: $message');
      case 409:
        return Exception('Vous avez déjà donné un avis pour ce produit');
      case 500:
        return Exception('Erreur serveur: $message');
      default:
        return Exception('Erreur: $message');
    }
  }
}
