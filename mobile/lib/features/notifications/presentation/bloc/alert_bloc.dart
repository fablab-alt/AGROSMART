import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/notifications/domain/repositories/alert_repository.dart';

// Events
abstract class AlertEvent extends Equatable {
  const AlertEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlerts extends AlertEvent {
  const LoadAlerts();
}

class MarkAlertAsRead extends AlertEvent {
  final String id;
  const MarkAlertAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllAlertsAsRead extends AlertEvent {
  const MarkAllAlertsAsRead();
}

// States
abstract class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object?> get props => [];
}

class AlertInitial extends AlertState {
  const AlertInitial();
}

class AlertLoading extends AlertState {
  const AlertLoading();
}

class AlertLoaded extends AlertState {
  final List<Alert> alerts;
  const AlertLoaded(this.alerts);

  @override
  List<Object?> get props => [alerts];
}

class AlertError extends AlertState {
  final String message;
  const AlertError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final AlertRepository repository;

  AlertBloc({required this.repository}) : super(const AlertInitial()) {
    on<LoadAlerts>(_onLoadAlerts);
    on<MarkAlertAsRead>(_onMarkAlertAsRead);
    on<MarkAllAlertsAsRead>(_onMarkAllAlertsAsRead);
  }

  Future<void> _onLoadAlerts(LoadAlerts event, Emitter<AlertState> emit) async {
    emit(const AlertLoading());
    try {
      final alerts = await repository.getAlerts();
      emit(AlertLoaded(alerts));
    } catch (e) {
      emit(AlertError(e.toString()));
    }
  }

  Future<void> _onMarkAlertAsRead(
    MarkAlertAsRead event,
    Emitter<AlertState> emit,
  ) async {
    if (state is AlertLoaded) {
      try {
        await repository.markAsRead(event.id);
        add(const LoadAlerts()); // Reload to be sure
      } catch (e) {
        emit(AlertError(e.toString()));
      }
    }
  }

  Future<void> _onMarkAllAlertsAsRead(
    MarkAllAlertsAsRead event,
    Emitter<AlertState> emit,
  ) async {
    try {
      await repository.markAllAsRead();
      add(const LoadAlerts());
    } catch (e) {
      emit(AlertError(e.toString()));
    }
  }
}
