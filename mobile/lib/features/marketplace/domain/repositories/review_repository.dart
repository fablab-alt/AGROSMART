import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<ProductReview>>> getProductReviews(
    String produitId,
  );

  Future<Either<Failure, ReviewStats>> getProductReviewStats(String produitId);

  Future<Either<Failure, ProductReview>> createReview({
    required String produitId,
    required int note,
    String? commentaire,
    List<String>? images,
  });

  Future<Either<Failure, ProductReview>> updateReview({
    required String reviewId,
    required int note,
    String? commentaire,
  });

  Future<Either<Failure, void>> deleteReview(String reviewId);
}
