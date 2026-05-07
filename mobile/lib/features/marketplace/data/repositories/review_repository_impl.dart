import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ProductReview>>> getProductReviews(
    String produitId,
  ) async {
    try {
      final reviews = await remoteDataSource.getProductReviews(produitId);
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReviewStats>> getProductReviewStats(
    String produitId,
  ) async {
    try {
      final stats = await remoteDataSource.getProductReviewStats(produitId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductReview>> createReview({
    required String produitId,
    required int note,
    String? commentaire,
    List<String>? images,
  }) async {
    try {
      final review = await remoteDataSource.createReview(
        produitId: produitId,
        note: note,
        commentaire: commentaire,
        images: images,
      );
      return Right(review);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductReview>> updateReview({
    required String reviewId,
    required int note,
    String? commentaire,
  }) async {
    try {
      final review = await remoteDataSource.updateReview(
        reviewId: reviewId,
        note: note,
        commentaire: commentaire,
      );
      return Right(review);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    try {
      await remoteDataSource.deleteReview(reviewId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
