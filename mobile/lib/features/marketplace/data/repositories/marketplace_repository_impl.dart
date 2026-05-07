import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/marketplace_remote_datasource.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MarketplaceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  /// Helper pour vérifier la connectivité avec fallback
  /// Sur émulateur, la vérification peut échouer même si le réseau est disponible
  Future<bool> _checkConnectivity() async {
    try {
      final isConnected = await networkInfo.isConnected;
      debugPrint('[MARKETPLACE] Network check: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('[MARKETPLACE] Network check error: $e - proceeding anyway');
      return true; // En cas d'erreur, on essaie quand même
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts({int page = 1}) async {
    debugPrint('[MARKETPLACE] getProducts called, page: $page');

    // On tente toujours la requête - la vérification réseau peut être peu fiable sur émulateur
    try {
      final products = await remoteDataSource.getProducts(page: page);
      debugPrint('[MARKETPLACE] Got ${products.length} products');
      return Right(products);
    } on ServerException catch (e) {
      debugPrint('[MARKETPLACE] ServerException: $e');
      return Left(ServerFailure());
    } on SocketException catch (e) {
      debugPrint('[MARKETPLACE] SocketException (no network): $e');
      return Left(NetworkFailure());
    } catch (e) {
      debugPrint('[MARKETPLACE] Unexpected error: $e');
      // Vérifier si c'est un problème réseau
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        return Left(NetworkFailure());
      }
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    debugPrint('[MARKETPLACE] searchProducts called, query: $query');
    try {
      final products = await remoteDataSource.searchProducts(query);
      return Right(products);
    } on ServerException {
      return Left(ServerFailure());
    } on SocketException {
      return Left(NetworkFailure());
    } catch (e) {
      debugPrint('[MARKETPLACE] Search error: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getMyProducts() async {
    debugPrint('[MARKETPLACE] getMyProducts called');
    try {
      final products = await remoteDataSource.getMyProducts();
      return Right(products);
    } on ServerException {
      return Left(ServerFailure());
    } on SocketException {
      return Left(NetworkFailure());
    } catch (e) {
      debugPrint('[MARKETPLACE] GetMyProducts error: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(
    Map<String, dynamic> data,
    List<File> images,
  ) async {
    debugPrint('[MARKETPLACE] createProduct called');
    try {
      final product = await remoteDataSource.createProduct(data, images);
      return Right(product);
    } on ServerException {
      return Left(ServerFailure());
    } on SocketException {
      return Left(NetworkFailure());
    } catch (e) {
      debugPrint('[MARKETPLACE] CreateProduct error: $e');
      return Left(ServerFailure());
    }
  }
}
