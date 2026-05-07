import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/wishlist.dart';
import '../../domain/usecases/wishlist_usecases.dart';

// Events
abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlist extends WishlistEvent {}

class AddProductToWishlist extends WishlistEvent {
  final String produitId;

  const AddProductToWishlist(this.produitId);

  @override
  List<Object?> get props => [produitId];
}

class RemoveProductFromWishlist extends WishlistEvent {
  final String produitId;

  const RemoveProductFromWishlist(this.produitId);

  @override
  List<Object?> get props => [produitId];
}

class ToggleWishlist extends WishlistEvent {
  final String produitId;

  const ToggleWishlist(this.produitId);

  @override
  List<Object?> get props => [produitId];
}

class ClearWishlistEvent extends WishlistEvent {}

// States
abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final Wishlist wishlist;

  const WishlistLoaded(this.wishlist);

  @override
  List<Object?> get props => [wishlist];

  bool isInWishlist(String produitId) {
    return wishlist.items.any((item) => item.produitId == produitId);
  }
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}

class WishlistItemAdded extends WishlistState {
  final WishlistItem item;

  const WishlistItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class WishlistItemRemoved extends WishlistState {
  final String produitId;

  const WishlistItemRemoved(this.produitId);

  @override
  List<Object?> get props => [produitId];
}

// Bloc
class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  final GetWishlist getWishlist;
  final AddToWishlist addToWishlist;
  final RemoveFromWishlist removeFromWishlist;
  final CheckInWishlist checkInWishlist;

  WishlistBloc({
    required this.getWishlist,
    required this.addToWishlist,
    required this.removeFromWishlist,
    required this.checkInWishlist,
  }) : super(WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
    on<AddProductToWishlist>(_onAddProductToWishlist);
    on<RemoveProductFromWishlist>(_onRemoveProductFromWishlist);
    on<ToggleWishlist>(_onToggleWishlist);
  }

  Future<void> _onLoadWishlist(
    LoadWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());

    final result = await getWishlist(NoParams());

    result.fold(
      (failure) => emit(WishlistError(failure.message)),
      (wishlist) => emit(WishlistLoaded(wishlist)),
    );
  }

  Future<void> _onAddProductToWishlist(
    AddProductToWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final currentState = state;
    emit(WishlistLoading());

    final result = await addToWishlist(event.produitId);

    result.fold(
      (failure) {
        emit(WishlistError(failure.message));
        if (currentState is WishlistLoaded) {
          emit(currentState);
        }
      },
      (item) {
        emit(WishlistItemAdded(item));
        // Reload wishlist
        add(LoadWishlist());
      },
    );
  }

  Future<void> _onRemoveProductFromWishlist(
    RemoveProductFromWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final currentState = state;
    emit(WishlistLoading());

    final result = await removeFromWishlist(event.produitId);

    result.fold(
      (failure) {
        emit(WishlistError(failure.message));
        if (currentState is WishlistLoaded) {
          emit(currentState);
        }
      },
      (_) {
        emit(WishlistItemRemoved(event.produitId));
        // Reload wishlist
        add(LoadWishlist());
      },
    );
  }

  Future<void> _onToggleWishlist(
    ToggleWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    final currentState = state;

    if (currentState is WishlistLoaded) {
      final isInWishlist = currentState.isInWishlist(event.produitId);

      if (isInWishlist) {
        add(RemoveProductFromWishlist(event.produitId));
      } else {
        add(AddProductToWishlist(event.produitId));
      }
    } else {
      // Load wishlist first
      add(LoadWishlist());
    }
  }
}
