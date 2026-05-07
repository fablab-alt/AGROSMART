import 'package:equatable/equatable.dart';
import '../../domain/entities/activite.dart';

abstract class CalendrierState extends Equatable {
  const CalendrierState();

  @override
  List<Object?> get props => [];
}

class CalendrierInitial extends CalendrierState {}

class CalendrierLoading extends CalendrierState {}

class CalendrierLoaded extends CalendrierState {
  final List<Activite> activites;

  const CalendrierLoaded(this.activites);

  @override
  List<Object?> get props => [activites];
}

class CalendrierError extends CalendrierState {
  final String message;

  const CalendrierError(this.message);

  @override
  List<Object?> get props => [message];
}

class ActiviteCreated extends CalendrierState {
  final Activite activite;

  const ActiviteCreated(this.activite);

  @override
  List<Object?> get props => [activite];
}

class ActiviteUpdated extends CalendrierState {
  final Activite activite;

  const ActiviteUpdated(this.activite);

  @override
  List<Object?> get props => [activite];
}

class ActiviteDeleted extends CalendrierState {}

class ActiviteMarqueeTerminee extends CalendrierState {
  final Activite activite;

  const ActiviteMarqueeTerminee(this.activite);

  @override
  List<Object?> get props => [activite];
}
