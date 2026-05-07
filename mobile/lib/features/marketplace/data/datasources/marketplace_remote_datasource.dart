import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/product_model.dart';

abstract class MarketplaceRemoteDataSource {
  Future<List<ProductModel>> getProducts({int page = 1, int limit = 20});
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<ProductModel>> getMyProducts();
  Future<ProductModel> createProduct(
    Map<String, dynamic> data,
    List<File> images,
  );
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final ApiClient client;

  MarketplaceRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ProductModel>> getProducts({int page = 1, int limit = 20}) async {
    final response = await client.get(
      '/marketplace/produits?page=$page&limit=$limit',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return (data['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final response = await client.get('/marketplace/produits/search?q=$query');

    if (response.statusCode == 200) {
      final data = response.data;
      return (data['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<List<ProductModel>> getMyProducts() async {
    final response = await client.get('/marketplace/produits/mes-produits');

    if (response.statusCode == 200) {
      final data = response.data;
      return (data['data'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } else {
      throw ServerException();
    }
  }

  @override
  Future<ProductModel> createProduct(
    Map<String, dynamic> data,
    List<File> images,
  ) async {
    final response = await client.postMultipart(
      '/marketplace/produits',
      data,
      images,
      fileField: 'images',
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body =
          response.data; // Dio response.data is already json decoded usually
      return ProductModel.fromJson(body['data']);
    } else {
      throw ServerException();
    }
  }
}
