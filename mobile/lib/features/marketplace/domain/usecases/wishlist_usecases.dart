import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/wishlist.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlist implements UseCase<Wishlist, NoParams> {
  final WishlistRepository repository;

  GetWishlist(this.repository);

  @override
  Future<Either<Failure, Wishlist>> call(NoParams params) async {
    return await repository.getWishlist();
  }
}

class AddToWishlist implements UseCase<WishlistItem, String> {
  final WishlistRepository repository;

  AddToWishlist(this.repository);

  @override
  Future<Either<Failure, WishlistItem>> call(String produitId) async {
    return await repository.addToWishlist(produitId);
  }
}

class RemoveFromWishlist implements UseCase<void, String> {
  final WishlistRepository repository;

  RemoveFromWishlist(this.repository);

  @override
  Future<Either<Failure, void>> call(String produitId) async {
    return await repository.removeFromWishlist(produitId);
  }
}

class CheckInWishlist implements UseCase<bool, String> {
  final WishlistRepository repository;

  CheckInWishlist(this.repository);

  @override
  Future<Either<Failure, bool>> call(String produitId) async {
    return await repository.isInWishlist(produitId);
  }
}
