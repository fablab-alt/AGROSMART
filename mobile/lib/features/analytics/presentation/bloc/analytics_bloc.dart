import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAnalytics extends AnalyticsEvent {}

// States
abstract class AnalyticsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsData data;

  AnalyticsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository repository;

  AnalyticsBloc({required this.repository}) : super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(LoadAnalytics event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    final result = await repository.getStats();
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (data) => emit(AnalyticsLoaded(data)),
    );
  }
}
