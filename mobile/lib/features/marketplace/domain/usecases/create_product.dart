import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/marketplace_repository.dart';

class CreateProductParams {
  final Map<String, dynamic> data;
  final List<File> images;

  CreateProductParams({required this.data, required this.images});
}

class CreateProduct implements UseCase<Product, CreateProductParams> {
  final MarketplaceRepository repository;

  CreateProduct(this.repository);

  @override
  Future<Either<Failure, Product>> call(CreateProductParams params) async {
    return await repository.createProduct(params.data, params.images);
  }
}
