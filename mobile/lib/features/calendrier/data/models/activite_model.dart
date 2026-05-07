import 'dart:convert';
import '../../domain/entities/activite.dart';

class ParcelleSimpleModel extends ParcelleSimple {
  const ParcelleSimpleModel({
    required super.id,
    required super.nom,
    super.superficie,
  });

  factory ParcelleSimpleModel.fromJson(Map<String, dynamic> json) {
    return ParcelleSimpleModel(
      id: json['id'],
      nom: json['nom'],
      superficie: json['superficie'] != null
          ? double.parse(json['superficie'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      if (superficie != null) 'superficie': superficie,
    };
  }
}

class ActiviteModel extends Activite {
  const ActiviteModel({
    required super.id,
    required super.userId,
    super.parcelleId,
    required super.titre,
    super.description,
    required super.typeActivite,
    required super.statut,
    required super.priorite,
    required super.dateDebut,
    super.dateFin,
    super.dateRappel,
    required super.estRecurrente,
    super.frequenceJours,
    super.dateFinRecurrence,
    super.coutEstime,
    super.notesTechniques,
    super.produitsUtilises,
    required super.rappelEnvoye,
    required super.createdAt,
    required super.updatedAt,
    super.parcelle,
  });

  factory ActiviteModel.fromJson(Map<String, dynamic> json) {
    List<String>? produits;
    if (json['produitsUtilises'] != null) {
      if (json['produitsUtilises'] is String) {
        produits = List<String>.from(jsonDecode(json['produitsUtilises']));
      } else if (json['produitsUtilises'] is List) {
        produits = List<String>.from(json['produitsUtilises']);
      }
    }

    return ActiviteModel(
      id: json['id'],
      userId: json['userId'],
      parcelleId: json['parcelleId'],
      titre: json['titre'],
      description: json['description'],
      typeActivite: TypeActivite.fromString(json['typeActivite']),
      statut: StatutActivite.fromString(json['statut']),
      priorite: PrioriteActivite.fromString(json['priorite']),
      dateDebut: DateTime.parse(json['dateDebut']),
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      dateRappel: json['dateRappel'] != null
          ? DateTime.parse(json['dateRappel'])
          : null,
      estRecurrente: json['estRecurrente'] ?? false,
      frequenceJours: json['frequenceJours'],
      dateFinRecurrence: json['dateFinRecurrence'] != null
          ? DateTime.parse(json['dateFinRecurrence'])
          : null,
      coutEstime: json['coutEstime'] != null
          ? double.parse(json['coutEstime'].toString())
          : null,
      notesTechniques: json['notesTechniques'],
      produitsUtilises: produits,
      rappelEnvoye: json['rappelEnvoye'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      parcelle: json['parcelle'] != null
          ? ParcelleSimpleModel.fromJson(json['parcelle'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      if (parcelleId != null) 'parcelleId': parcelleId,
      'titre': titre,
      if (description != null) 'description': description,
      'typeActivite': typeActivite.apiValue,
      'statut': statut.apiValue,
      'priorite': priorite.apiValue,
      'dateDebut': dateDebut.toIso8601String(),
      if (dateFin != null) 'dateFin': dateFin!.toIso8601String(),
      if (dateRappel != null) 'dateRappel': dateRappel!.toIso8601String(),
      'estRecurrente': estRecurrente,
      if (frequenceJours != null) 'frequenceJours': frequenceJours,
      if (dateFinRecurrence != null)
        'dateFinRecurrence': dateFinRecurrence!.toIso8601String(),
      if (coutEstime != null) 'coutEstime': coutEstime,
      if (notesTechniques != null) 'notesTechniques': notesTechniques,
      if (produitsUtilises != null) 'produitsUtilises': produitsUtilises,
      'rappelEnvoye': rappelEnvoye,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (parcelle != null)
        'parcelle': (parcelle as ParcelleSimpleModel).toJson(),
    };
  }
}
