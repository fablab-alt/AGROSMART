import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:agriculture/features/orders/domain/entities/order.dart';
import 'package:agriculture/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart' as dartz;

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<dartz.Either<Failure, List<Order>>> getMyOrders() async {
    try {
      final remoteOrders = await remoteDataSource.getMyOrders();
      return dartz.Right(remoteOrders);
    } catch (e) {
      return dartz.Left(ServerFailure('Erreur serveur lors de la récupération des commandes'));
    }
  }
}
