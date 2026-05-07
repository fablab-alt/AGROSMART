import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/orders/domain/entities/order.dart';
import 'package:dartz/dartz.dart' as dartz;

abstract class OrderRepository {
  Future<dartz.Either<Failure, List<Order>>> getMyOrders();
}
