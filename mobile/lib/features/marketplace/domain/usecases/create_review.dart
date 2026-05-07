import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_review.dart';
import '../repositories/review_repository.dart';

class CreateReview implements UseCase<ProductReview, CreateReviewParams> {
  final ReviewRepository repository;

  CreateReview(this.repository);

  @override
  Future<Either<Failure, ProductReview>> call(CreateReviewParams params) async {
    return await repository.createReview(
      produitId: params.produitId,
      note: params.note,
      commentaire: params.commentaire,
      images: params.images,
    );
  }
}

class CreateReviewParams extends Equatable {
  final String produitId;
  final int note;
  final String? commentaire;
  final List<String>? images;

  const CreateReviewParams({
    required this.produitId,
    required this.note,
    this.commentaire,
    this.images,
  });

  @override
  List<Object?> get props => [produitId, note, commentaire, images];
}
