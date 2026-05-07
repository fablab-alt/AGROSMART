import 'package:equatable/equatable.dart';

enum RecommandationType { irrigation, fertilisation, culture, phytosanitaire, traitement, recolte }

class Recommandation extends Equatable {
  final String id;
  final String titre;
  final String description;
  final RecommandationType type;
  final String priorite;
  final String parcelleId;
  final String parcelleNom;
  final DateTime dateCreation;
  final Map<String, String> details;
  final String? impactEstime;

  const Recommandation({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.priorite,
    required this.parcelleId,
    required this.parcelleNom,
    required this.dateCreation,
    required this.details,
    this.impactEstime,
  });

  @override
  List<Object?> get props => [id, titre, description, type, priorite, parcelleId, parcelleNom, dateCreation, details, impactEstime];
}
