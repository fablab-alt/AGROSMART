import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/features/diagnostic/data/models/diagnostic_model.dart';
import 'package:agriculture/features/diagnostic/data/repositories/diagnostic_repository_impl.dart';

// Events
abstract class DiagnosticEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AnalyzeImage extends DiagnosticEvent {
  final File image;
  final String? cropType;
  final String? parcelleId;

  AnalyzeImage({required this.image, this.cropType, this.parcelleId});
}

class LoadHistory extends DiagnosticEvent {}

// States
abstract class DiagnosticState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DiagnosticInitial extends DiagnosticState {}

class DiagnosticLoading extends DiagnosticState {}

class DiagnosticSuccess extends DiagnosticState {
  final DiagnosticModel result;
  DiagnosticSuccess(this.result);
}

class DiagnosticHistoryLoaded extends DiagnosticState {
  final List<DiagnosticModel> history;
  DiagnosticHistoryLoaded(this.history);
}

class DiagnosticError extends DiagnosticState {
  final String message;
  DiagnosticError(this.message);
}

// Bloc
class DiagnosticBloc extends Bloc<DiagnosticEvent, DiagnosticState> {
  final DiagnosticRepository repository;

  DiagnosticBloc({required this.repository}) : super(DiagnosticInitial()) {
    on<AnalyzeImage>(_onAnalyzeImage);
    on<LoadHistory>(_onLoadHistory);
  }

  Future<void> _onAnalyzeImage(AnalyzeImage event, Emitter<DiagnosticState> emit) async {
    emit(DiagnosticLoading());
    final result = await repository.analyzePlant(event.image, cropType: event.cropType, parcelleId: event.parcelleId);
    result.fold(
      (failure) => emit(DiagnosticError(failure.message)),
      (diagnostic) => emit(DiagnosticSuccess(diagnostic)),
    );
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<DiagnosticState> emit) async {
    emit(DiagnosticLoading());
    final result = await repository.getHistory();
    result.fold(
      (failure) => emit(DiagnosticError(failure.message)),
      (history) => emit(DiagnosticHistoryLoaded(history)),
    );
  }
}
