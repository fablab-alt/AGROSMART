import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class MarketplaceRepository {
  Future<Either<Failure, List<Product>>> getProducts({int page = 1});
  Future<Either<Failure, List<Product>>> searchProducts(String query);
  Future<Either<Failure, List<Product>>> getMyProducts();
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> data, List<File> images);
}
