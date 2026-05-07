import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_review.dart';
import '../repositories/review_repository.dart';

class GetProductReviews implements UseCase<List<ProductReview>, String> {
  final ReviewRepository repository;

  GetProductReviews(this.repository);

  @override
  Future<Either<Failure, List<ProductReview>>> call(String produitId) async {
    return await repository.getProductReviews(produitId);
  }
}

class GetProductReviewStats implements UseCase<ReviewStats, String> {
  final ReviewRepository repository;

  GetProductReviewStats(this.repository);

  @override
  Future<Either<Failure, ReviewStats>> call(String produitId) async {
    return await repository.getProductReviewStats(produitId);
  }
}
