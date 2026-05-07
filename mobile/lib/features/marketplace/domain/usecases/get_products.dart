import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/marketplace_repository.dart';

class GetProducts implements UseCase<List<Product>, int> {
  final MarketplaceRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(int page) async {
    return await repository.getProducts(page: page);
  }
}
