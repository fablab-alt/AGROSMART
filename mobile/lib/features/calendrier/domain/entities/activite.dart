import 'package:equatable/equatable.dart';

enum TypeActivite {
  semis,
  plantation,
  arrosage,
  fertilisation,
  traitement,
  desherbage,
  taille,
  recolte,
  autre;

  String get displayName {
    switch (this) {
      case TypeActivite.semis:
        return '🌱 Semis';
      case TypeActivite.plantation:
        return '🌿 Plantation';
      case TypeActivite.arrosage:
        return '💧 Arrosage';
      case TypeActivite.fertilisation:
        return '🌾 Fertilisation';
      case TypeActivite.traitement:
        return '💊 Traitement';
      case TypeActivite.desherbage:
        return '🔪 Désherbage';
      case TypeActivite.taille:
        return '✂️ Taille';
      case TypeActivite.recolte:
        return '🌽 Récolte';
      case TypeActivite.autre:
        return '📋 Autre';
    }
  }

  String get apiValue {
    return name.toUpperCase();
  }

  static TypeActivite fromString(String value) {
    return TypeActivite.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TypeActivite.autre,
    );
  }
}

enum StatutActivite {
  planifiee,
  enCours,
  terminee,
  annulee,
  reportee;

  String get displayName {
    switch (this) {
      case StatutActivite.planifiee:
        return 'Planifiée';
      case StatutActivite.enCours:
        return 'En cours';
      case StatutActivite.terminee:
        return 'Terminée';
      case StatutActivite.annulee:
        return 'Annulée';
      case StatutActivite.reportee:
        return 'Reportée';
    }
  }

  String get apiValue {
    switch (this) {
      case StatutActivite.planifiee:
        return 'PLANIFIEE';
      case StatutActivite.enCours:
        return 'EN_COURS';
      case StatutActivite.terminee:
        return 'TERMINEE';
      case StatutActivite.annulee:
        return 'ANNULEE';
      case StatutActivite.reportee:
        return 'REPORTEE';
    }
  }

  static StatutActivite fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PLANIFIEE':
        return StatutActivite.planifiee;
      case 'EN_COURS':
        return StatutActivite.enCours;
      case 'TERMINEE':
        return StatutActivite.terminee;
      case 'ANNULEE':
        return StatutActivite.annulee;
      case 'REPORTEE':
        return StatutActivite.reportee;
      default:
        return StatutActivite.planifiee;
    }
  }
}

enum PrioriteActivite {
  basse,
  moyenne,
  haute,
  urgente;

  String get displayName {
    switch (this) {
      case PrioriteActivite.basse:
        return 'Basse';
      case PrioriteActivite.moyenne:
        return 'Moyenne';
      case PrioriteActivite.haute:
        return 'Haute';
      case PrioriteActivite.urgente:
        return 'Urgente';
    }
  }

  String get apiValue {
    return name.toUpperCase();
  }

  static PrioriteActivite fromString(String value) {
    return PrioriteActivite.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PrioriteActivite.moyenne,
    );
  }
}

class ParcelleSimple extends Equatable {
  final String id;
  final String nom;
  final double? superficie;

  const ParcelleSimple({required this.id, required this.nom, this.superficie});

  @override
  List<Object?> get props => [id, nom, superficie];
}

class Activite extends Equatable {
  final String id;
  final String userId;
  final String? parcelleId;
  final String titre;
  final String? description;
  final TypeActivite typeActivite;
  final StatutActivite statut;
  final PrioriteActivite priorite;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final DateTime? dateRappel;
  final bool estRecurrente;
  final int? frequenceJours;
  final DateTime? dateFinRecurrence;
  final double? coutEstime;
  final String? notesTechniques;
  final List<String>? produitsUtilises;
  final bool rappelEnvoye;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ParcelleSimple? parcelle;

  const Activite({
    required this.id,
    required this.userId,
    this.parcelleId,
    required this.titre,
    this.description,
    required this.typeActivite,
    required this.statut,
    required this.priorite,
    required this.dateDebut,
    this.dateFin,
    this.dateRappel,
    required this.estRecurrente,
    this.frequenceJours,
    this.dateFinRecurrence,
    this.coutEstime,
    this.notesTechniques,
    this.produitsUtilises,
    required this.rappelEnvoye,
    required this.createdAt,
    required this.updatedAt,
    this.parcelle,
  });

  // Computed properties
  bool get estEnRetard {
    if (statut == StatutActivite.terminee || statut == StatutActivite.annulee) {
      return false;
    }
    return DateTime.now().isAfter(dateDebut);
  }

  bool get estAVenir {
    return DateTime.now().isBefore(dateDebut);
  }

  bool get estAujourdhui {
    final now = DateTime.now();
    return dateDebut.year == now.year &&
        dateDebut.month == now.month &&
        dateDebut.day == now.day;
  }

  int get joursRestants {
    if (estEnRetard) return 0;
    return dateDebut.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    parcelleId,
    titre,
    description,
    typeActivite,
    statut,
    priorite,
    dateDebut,
    dateFin,
    dateRappel,
    estRecurrente,
    frequenceJours,
    dateFinRecurrence,
    coutEstime,
    notesTechniques,
    produitsUtilises,
    rappelEnvoye,
    createdAt,
    updatedAt,
    parcelle,
  ];
}
