import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/wishlist.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;

  WishlistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Wishlist>> getWishlist() async {
    try {
      final wishlist = await remoteDataSource.getWishlist();
      return Right(wishlist);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String produitId) async {
    try {
      final item = await remoteDataSource.addToWishlist(produitId);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlist(String produitId) async {
    try {
      await remoteDataSource.removeFromWishlist(produitId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearWishlist() async {
    try {
      await remoteDataSource.clearWishlist();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isInWishlist(String produitId) async {
    try {
      final inWishlist = await remoteDataSource.isInWishlist(produitId);
      return Right(inWishlist);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
