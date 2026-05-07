import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/features/formations/domain/entities/formation.dart';
import 'package:agriculture/features/formations/domain/repositories/formation_repository.dart';

// Events
abstract class FormationEvent extends Equatable {
  const FormationEvent();
  @override
  List<Object> get props => [];
}

class LoadFormations extends FormationEvent {}

// States
abstract class FormationState extends Equatable {
  const FormationState();
  @override
  List<Object> get props => [];
}

class FormationInitial extends FormationState {}

class FormationLoading extends FormationState {}

class FormationLoaded extends FormationState {
  final List<Formation> formations;

  const FormationLoaded(this.formations);

  @override
  List<Object> get props => [formations];
}

class FormationError extends FormationState {
  final String message;

  const FormationError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class FormationBloc extends Bloc<FormationEvent, FormationState> {
  final FormationRepository repository;

  FormationBloc({required this.repository}) : super(FormationInitial()) {
    on<LoadFormations>(_onLoadFormations);
  }

  Future<void> _onLoadFormations(LoadFormations event, Emitter<FormationState> emit) async {
    emit(FormationLoading());
    final result = await repository.getFormations();
    result.fold(
      (failure) => emit(FormationError(failure.message)),
      (formations) => emit(FormationLoaded(formations)),
    );
  }
}
