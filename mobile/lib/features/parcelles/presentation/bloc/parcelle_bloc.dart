import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:agriculture/features/parcelles/domain/repositories/parcelle_repository.dart';
import 'package:agriculture/core/config/environment_config.dart';

// Events
abstract class ParcelleEvent extends Equatable {
  const ParcelleEvent();

  @override
  List<Object?> get props => [];
}

class LoadParcelles extends ParcelleEvent {
  const LoadParcelles();
}

class CreateParcelle extends ParcelleEvent {
  final Map<String, dynamic> data;
  const CreateParcelle(this.data);

  @override
  List<Object?> get props => [data];
}

// States
abstract class ParcelleState extends Equatable {
  const ParcelleState();

  @override
  List<Object?> get props => [];
}

class ParcelleInitial extends ParcelleState {
  const ParcelleInitial();
}

class ParcelleLoading extends ParcelleState {
  const ParcelleLoading();
}

class ParcelleLoaded extends ParcelleState {
  final List<Parcelle> parcelles;
  const ParcelleLoaded(this.parcelles);

  @override
  List<Object?> get props => [parcelles];
}

class ParcelleError extends ParcelleState {
  final String message;
  const ParcelleError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ParcelleBloc extends Bloc<ParcelleEvent, ParcelleState> {
  final ParcelleRepository repository;

  // Helper pour les logs conditionnels
  void _log(String message) {
    if (EnvironmentConfig.enableDebugLogs) {
      debugPrint(message);
    }
  }

  ParcelleBloc({required this.repository}) : super(const ParcelleInitial()) {
    on<LoadParcelles>(_onLoadParcelles);
    on<CreateParcelle>(_onCreateParcelle);
  }

  Future<void> _onLoadParcelles(
    LoadParcelles event,
    Emitter<ParcelleState> emit,
  ) async {
    emit(const ParcelleLoading());
    try {
      final parcelles = await repository.getParcelles();
      emit(ParcelleLoaded(parcelles));
    } catch (e) {
      emit(ParcelleError(e.toString()));
    }
  }

  Future<void> _onCreateParcelle(
    CreateParcelle event,
    Emitter<ParcelleState> emit,
  ) async {
    _log('[BLOC] CreateParcelle event received');
    emit(const ParcelleLoading());
    try {
      _log('[BLOC] Calling repository.createParcelle...');
      await repository.createParcelle(event.data);
      _log('[BLOC] Create successful, reloading list...');
      // Reload list
      add(const LoadParcelles());
    } catch (e) {
      _log('[BLOC] Create failed: $e');
      emit(ParcelleError(e.toString()));
    }
  }
}
