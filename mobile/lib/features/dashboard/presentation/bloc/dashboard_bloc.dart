import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/usecases/get_dashboard_data.dart';
import '../../../../core/usecases/usecase.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadDashboard extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardData data;
  DashboardLoaded(this.data);
  @override
  List<Object> get props => [data];
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardData getDashboardData;

  DashboardBloc({required this.getDashboardData}) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    final result = await getDashboardData(NoParams());
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (data) => emit(DashboardLoaded(data)),
    );
  }
}
