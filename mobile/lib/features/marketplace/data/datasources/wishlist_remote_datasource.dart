import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/wishlist_model.dart';

abstract class WishlistRemoteDataSource {
  Future<WishlistModel> getWishlist();
  Future<WishlistItemModel> addToWishlist(String produitId);
  Future<void> removeFromWishlist(String produitId);
  Future<void> clearWishlist();
  Future<bool> isInWishlist(String produitId);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  final ApiClient apiClient;

  WishlistRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<WishlistModel> getWishlist() async {
    try {
      final response = await apiClient.get('/wishlist');
      return WishlistModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(String produitId) async {
    try {
      final response = await apiClient.post(
        '/wishlist',
        data: {'produit_id': produitId},
      );
      return WishlistItemModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> removeFromWishlist(String produitId) async {
    try {
      await apiClient.delete('/wishlist/$produitId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> clearWishlist() async {
    try {
      await apiClient.delete('/wishlist');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> isInWishlist(String produitId) async {
    try {
      final response = await apiClient.get('/wishlist/check/$produitId');
      return response.data['inWishlist'] as bool? ?? false;
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
      case 404:
        return Exception('Produit non trouvé: $message');
      case 409:
        return Exception('Ce produit est déjà dans vos favoris');
      case 500:
        return Exception('Erreur serveur: $message');
      default:
        return Exception('Erreur: $message');
    }
  }
}
