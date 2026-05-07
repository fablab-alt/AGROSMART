import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/domain/repositories/sensor_repository.dart';

import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';

// Events
abstract class SensorEvent extends Equatable {
  const SensorEvent();

  @override
  List<Object?> get props => [];
}

class LoadSensors extends SensorEvent {
  const LoadSensors();
}

class LoadSensorHistory extends SensorEvent {
  final String sensorId;
  const LoadSensorHistory(this.sensorId);

  @override
  List<Object?> get props => [sensorId];
}

class ToggleSensorStatus extends SensorEvent {
  final String sensorId;
  final String status;
  const ToggleSensorStatus(this.sensorId, this.status);

  @override
  List<Object?> get props => [sensorId, status];
}

// States
abstract class SensorState extends Equatable {
  const SensorState();

  @override
  List<Object?> get props => [];
}

class SensorInitial extends SensorState {
  const SensorInitial();
}

class SensorLoading extends SensorState {
  const SensorLoading();
}

class SensorLoaded extends SensorState {
  final List<Sensor> sensors;
  const SensorLoaded(this.sensors);

  @override
  List<Object?> get props => [sensors];
}

class SensorHistoryLoaded extends SensorState {
  final List<SensorMeasure> history;
  const SensorHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class SensorError extends SensorState {
  final String message;
  const SensorError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class SensorBloc extends Bloc<SensorEvent, SensorState> {
  final SensorRepository repository;

  SensorBloc({required this.repository}) : super(const SensorInitial()) {
    on<LoadSensors>(_onLoadSensors);
    on<LoadSensorHistory>(_onLoadSensorHistory);
    on<ToggleSensorStatus>(_onToggleSensorStatus);
  }

  Future<void> _onLoadSensors(
    LoadSensors event,
    Emitter<SensorState> emit,
  ) async {
    debugPrint('[SENSOR_BLOC] LoadSensors event received');
    emit(const SensorLoading());
    try {
      debugPrint('[SENSOR_BLOC] Calling repository.getSensors()');
      final sensors = await repository.getSensors();
      debugPrint('[SENSOR_BLOC] Got ${sensors.length} sensors');
      emit(SensorLoaded(sensors));
    } catch (e) {
      debugPrint('[SENSOR_BLOC] Error: $e');
      emit(SensorError(e.toString()));
    }
  }

  Future<void> _onLoadSensorHistory(
    LoadSensorHistory event,
    Emitter<SensorState> emit,
  ) async {
    emit(const SensorLoading());
    try {
      final history = await repository.getSensorHistory(event.sensorId);
      emit(SensorHistoryLoaded(history));
    } catch (e) {
      emit(SensorError(e.toString()));
    }
  }

  Future<void> _onToggleSensorStatus(
    ToggleSensorStatus event,
    Emitter<SensorState> emit,
  ) async {
    debugPrint('[SENSOR_BLOC] ToggleSensorStatus event received');
    try {
      await repository.toggleSensorStatus(event.sensorId, event.status);
      debugPrint('[SENSOR_BLOC] Status toggled, reloading sensors');
      // Recharger la liste des capteurs après le toggle
      add(const LoadSensors());
    } catch (e) {
      debugPrint('[SENSOR_BLOC] Toggle error: $e');
      emit(SensorError(e.toString()));
    }
  }
}
