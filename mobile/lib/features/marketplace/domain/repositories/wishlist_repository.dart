import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wishlist.dart';

abstract class WishlistRepository {
  Future<Either<Failure, Wishlist>> getWishlist();
  Future<Either<Failure, WishlistItem>> addToWishlist(String produitId);
  Future<Either<Failure, void>> removeFromWishlist(String produitId);
  Future<Either<Failure, void>> clearWishlist();
  Future<Either<Failure, bool>> isInWishlist(String produitId);
}
