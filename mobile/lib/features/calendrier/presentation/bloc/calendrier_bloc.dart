import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_activites.dart';
import '../../domain/usecases/create_activite.dart';
import '../../domain/usecases/update_activite.dart';
import '../../domain/usecases/delete_activite.dart';
import '../../domain/usecases/get_activites_prochaines.dart';
import '../../domain/usecases/marquer_activite_terminee.dart';
import 'calendrier_event.dart';
import 'calendrier_state.dart';

class CalendrierBloc extends Bloc<CalendrierEvent, CalendrierState> {
  final GetActivites getActivites;
  final CreateActivite createActivite;
  final UpdateActivite updateActivite;
  final DeleteActivite deleteActivite;
  final GetActivitesProchaines getActivitesProchaines;
  final MarquerActiviteTerminee marquerActiviteTerminee;

  CalendrierBloc({
    required this.getActivites,
    required this.createActivite,
    required this.updateActivite,
    required this.deleteActivite,
    required this.getActivitesProchaines,
    required this.marquerActiviteTerminee,
  }) : super(CalendrierInitial()) {
    on<LoadActivites>(_onLoadActivites);
    on<LoadActivitesProchaines>(_onLoadActivitesProchaines);
    on<CreateNewActivite>(_onCreateNewActivite);
    on<UpdateExistingActivite>(_onUpdateExistingActivite);
    on<DeleteExistingActivite>(_onDeleteExistingActivite);
    on<MarquerActiviteComplete>(_onMarquerActiviteComplete);
  }

  Future<void> _onLoadActivites(
    LoadActivites event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await getActivites(
      parcelleId: event.parcelleId,
      typeActivite: event.typeActivite,
      statut: event.statut,
      priorite: event.priorite,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
    );

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (activites) => emit(CalendrierLoaded(activites)),
    );
  }

  Future<void> _onLoadActivitesProchaines(
    LoadActivitesProchaines event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await getActivitesProchaines(event.jours);

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (activites) => emit(CalendrierLoaded(activites)),
    );
  }

  Future<void> _onCreateNewActivite(
    CreateNewActivite event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await createActivite(
      titre: event.titre,
      description: event.description,
      typeActivite: event.typeActivite,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      parcelleId: event.parcelleId,
      priorite: event.priorite,
      dateRappel: event.dateRappel,
      coutEstime: event.coutEstime,
      produitsUtilises: event.produitsUtilises,
      estRecurrente: event.estRecurrente,
      frequenceJours: event.frequenceJours,
      dateFinRecurrence: event.dateFinRecurrence,
      notesTechniques: event.notesTechniques,
    );

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (activite) => emit(ActiviteCreated(activite)),
    );
  }

  Future<void> _onUpdateExistingActivite(
    UpdateExistingActivite event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await updateActivite(
      id: event.id,
      titre: event.titre,
      description: event.description,
      typeActivite: event.typeActivite,
      statut: event.statut,
      priorite: event.priorite,
      dateDebut: event.dateDebut,
      dateFin: event.dateFin,
      dateRappel: event.dateRappel,
      coutEstime: event.coutEstime,
      notesTechniques: event.notesTechniques,
      produitsUtilises: event.produitsUtilises,
    );

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (activite) => emit(ActiviteUpdated(activite)),
    );
  }

  Future<void> _onDeleteExistingActivite(
    DeleteExistingActivite event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await deleteActivite(event.id);

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (_) => emit(ActiviteDeleted()),
    );
  }

  Future<void> _onMarquerActiviteComplete(
    MarquerActiviteComplete event,
    Emitter<CalendrierState> emit,
  ) async {
    emit(CalendrierLoading());

    final result = await marquerActiviteTerminee(event.id);

    result.fold(
      (failure) => emit(CalendrierError(failure.message)),
      (activite) => emit(ActiviteMarqueeTerminee(activite)),
    );
  }
}
