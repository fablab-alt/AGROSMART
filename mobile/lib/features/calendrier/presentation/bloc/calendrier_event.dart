import 'package:equatable/equatable.dart';
import '../../domain/entities/activite.dart';

abstract class CalendrierEvent extends Equatable {
  const CalendrierEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivites extends CalendrierEvent {
  final String? parcelleId;
  final TypeActivite? typeActivite;
  final StatutActivite? statut;
  final PrioriteActivite? priorite;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const LoadActivites({
    this.parcelleId,
    this.typeActivite,
    this.statut,
    this.priorite,
    this.dateDebut,
    this.dateFin,
  });

  @override
  List<Object?> get props => [
    parcelleId,
    typeActivite,
    statut,
    priorite,
    dateDebut,
    dateFin,
  ];
}

class LoadActivitesProchaines extends CalendrierEvent {
  final int jours;

  const LoadActivitesProchaines({this.jours = 7});

  @override
  List<Object?> get props => [jours];
}

class CreateNewActivite extends CalendrierEvent {
  final String titre;
  final String? description;
  final TypeActivite typeActivite;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String? parcelleId;
  final PrioriteActivite priorite;
  final DateTime? dateRappel;
  final double? coutEstime;
  final List<String>? produitsUtilises;
  final bool estRecurrente;
  final int? frequenceJours;
  final DateTime? dateFinRecurrence;
  final String? notesTechniques;

  const CreateNewActivite({
    required this.titre,
    this.description,
    required this.typeActivite,
    required this.dateDebut,
    this.dateFin,
    this.parcelleId,
    this.priorite = PrioriteActivite.moyenne,
    this.dateRappel,
    this.coutEstime,
    this.produitsUtilises,
    this.estRecurrente = false,
    this.frequenceJours,
    this.dateFinRecurrence,
    this.notesTechniques,
  });

  @override
  List<Object?> get props => [
    titre,
    description,
    typeActivite,
    dateDebut,
    dateFin,
    parcelleId,
    priorite,
    dateRappel,
    coutEstime,
    produitsUtilises,
    estRecurrente,
    frequenceJours,
    dateFinRecurrence,
    notesTechniques,
  ];
}

class UpdateExistingActivite extends CalendrierEvent {
  final String id;
  final String? titre;
  final String? description;
  final TypeActivite? typeActivite;
  final StatutActivite? statut;
  final PrioriteActivite? priorite;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? dateRappel;
  final double? coutEstime;
  final String? notesTechniques;
  final List<String>? produitsUtilises;

  const UpdateExistingActivite({
    required this.id,
    this.titre,
    this.description,
    this.typeActivite,
    this.statut,
    this.priorite,
    this.dateDebut,
    this.dateFin,
    this.dateRappel,
    this.coutEstime,
    this.notesTechniques,
    this.produitsUtilises,
  });

  @override
  List<Object?> get props => [
    id,
    titre,
    description,
    typeActivite,
    statut,
    priorite,
    dateDebut,
    dateFin,
    dateRappel,
    coutEstime,
    notesTechniques,
    produitsUtilises,
  ];
}

class DeleteExistingActivite extends CalendrierEvent {
  final String id;

  const DeleteExistingActivite(this.id);

  @override
  List<Object?> get props => [id];
}

class MarquerActiviteComplete extends CalendrierEvent {
  final String id;

  const MarquerActiviteComplete(this.id);

  @override
  List<Object?> get props => [id];
}
