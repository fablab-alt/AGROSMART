import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_review.dart';
import '../repositories/review_repository.dart';

class UpdateReview implements UseCase<ProductReview, UpdateReviewParams> {
  final ReviewRepository repository;

  UpdateReview(this.repository);

  @override
  Future<Either<Failure, ProductReview>> call(UpdateReviewParams params) async {
    return await repository.updateReview(
      reviewId: params.reviewId,
      note: params.note,
      commentaire: params.commentaire,
    );
  }
}

class UpdateReviewParams extends Equatable {
  final String reviewId;
  final int note;
  final String? commentaire;

  const UpdateReviewParams({
    required this.reviewId,
    required this.note,
    this.commentaire,
  });

  @override
  List<Object?> get props => [reviewId, note, commentaire];
}
