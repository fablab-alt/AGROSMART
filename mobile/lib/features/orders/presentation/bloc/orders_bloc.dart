import 'package:agriculture/features/orders/domain/entities/order.dart';
import 'package:agriculture/features/orders/domain/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object> get props => [];
}

class LoadMyOrders extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository repository;

  OrdersBloc({required this.repository}) : super(OrdersInitial()) {
    on<LoadMyOrders>(_onLoadMyOrders);
  }

  Future<void> _onLoadMyOrders(LoadMyOrders event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final result = await repository.getMyOrders();
    result.fold(
      (failure) => emit(OrdersError(failure.message)),
      (orders) => emit(OrdersLoaded(orders)),
    );
  }
}
