import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product_review.dart';
import '../../domain/usecases/create_review.dart';
import '../../domain/usecases/delete_review.dart';
import '../../domain/usecases/get_product_reviews.dart';
import '../../domain/usecases/update_review.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductReviews extends ReviewEvent {
  final String produitId;

  const LoadProductReviews(this.produitId);

  @override
  List<Object?> get props => [produitId];
}

class AddReview extends ReviewEvent {
  final String produitId;
  final int note;
  final String? commentaire;
  final List<String>? images;

  const AddReview({
    required this.produitId,
    required this.note,
    this.commentaire,
    this.images,
  });

  @override
  List<Object?> get props => [produitId, note, commentaire, images];
}

class EditReview extends ReviewEvent {
  final String reviewId;
  final int note;
  final String? commentaire;

  const EditReview({
    required this.reviewId,
    required this.note,
    this.commentaire,
  });

  @override
  List<Object?> get props => [reviewId, note, commentaire];
}

class RemoveReview extends ReviewEvent {
  final String reviewId;

  const RemoveReview(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<ProductReview> reviews;
  final ReviewStats? stats;

  const ReviewLoaded({required this.reviews, this.stats});

  @override
  List<Object?> get props => [reviews, stats];
}

class ReviewError extends ReviewState {
  final String message;

  const ReviewError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReviewSubmitted extends ReviewState {
  final ProductReview review;

  const ReviewSubmitted(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewUpdated extends ReviewState {
  final ProductReview review;

  const ReviewUpdated(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewDeleted extends ReviewState {}

// Bloc
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final GetProductReviews getProductReviews;
  final GetProductReviewStats getProductReviewStats;
  final CreateReview createReview;
  final UpdateReview updateReview;
  final DeleteReview deleteReview;

  ReviewBloc({
    required this.getProductReviews,
    required this.getProductReviewStats,
    required this.createReview,
    required this.updateReview,
    required this.deleteReview,
  }) : super(ReviewInitial()) {
    on<LoadProductReviews>(_onLoadProductReviews);
    on<AddReview>(_onAddReview);
    on<EditReview>(_onEditReview);
    on<RemoveReview>(_onRemoveReview);
  }

  Future<void> _onLoadProductReviews(
    LoadProductReviews event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    final reviewsResult = await getProductReviews(event.produitId);
    final statsResult = await getProductReviewStats(event.produitId);

    reviewsResult.fold((failure) => emit(ReviewError(failure.message)), (
      reviews,
    ) {
      ReviewStats? stats;
      statsResult.fold((_) => null, (s) => stats = s);
      emit(ReviewLoaded(reviews: reviews, stats: stats));
    });
  }

  Future<void> _onAddReview(AddReview event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());

    final result = await createReview(
      CreateReviewParams(
        produitId: event.produitId,
        note: event.note,
        commentaire: event.commentaire,
        images: event.images,
      ),
    );

    result.fold((failure) => emit(ReviewError(failure.message)), (review) {
      emit(ReviewSubmitted(review));
      // Reload reviews after submission
      add(LoadProductReviews(event.produitId));
    });
  }

  Future<void> _onEditReview(
    EditReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    final result = await updateReview(
      UpdateReviewParams(
        reviewId: event.reviewId,
        note: event.note,
        commentaire: event.commentaire,
      ),
    );

    result.fold((failure) => emit(ReviewError(failure.message)), (review) {
      emit(ReviewUpdated(review));
      // Reload reviews after update
      if (state is ReviewLoaded) {
        final currentState = state as ReviewLoaded;
        final updatedReviews = currentState.reviews.map((r) {
          return r.id == review.id ? review : r;
        }).toList();
        emit(ReviewLoaded(reviews: updatedReviews, stats: currentState.stats));
      }
    });
  }

  Future<void> _onRemoveReview(
    RemoveReview event,
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewLoading());

    final result = await deleteReview(event.reviewId);

    result.fold((failure) => emit(ReviewError(failure.message)), (_) {
      emit(ReviewDeleted());
      // Reload reviews after deletion
      if (state is ReviewLoaded) {
        final currentState = state as ReviewLoaded;
        final updatedReviews = currentState.reviews
            .where((r) => r.id != event.reviewId)
            .toList();
        emit(ReviewLoaded(reviews: updatedReviews, stats: currentState.stats));
      }
    });
  }
}
