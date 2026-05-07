import '../../domain/entities/equipment.dart';

class EquipmentModel extends Equipment {
  const EquipmentModel({
    required super.id,
    required super.nom,
    required super.categorie,
    super.description,
    required super.prixParJour,
    super.caution,
    required super.disponible,
    required super.etat,
    super.localisation,
    super.latitude,
    super.longitude,
    required super.images,
    super.specifications,
    required super.proprietaireId,
    required super.createdAt,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      categorie: json['categorie'] ?? 'autre',
      description: json['description'],
      prixParJour: double.tryParse(json['prix_jour']?.toString() ?? '0') ?? 0.0,
      caution: double.tryParse(json['caution']?.toString() ?? '0') ?? 0.0,
      disponible: json['disponible'] ?? true,
      etat: json['etat'] ?? 'bon',
      localisation: json['localisation'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      specifications: json['specifications'],
      proprietaireId: json['proprietaire_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'categorie': categorie,
      'description': description,
      'prix_jour': prixParJour,
      'caution': caution,
      'disponible': disponible,
      'etat': etat,
      'localisation': localisation,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'specifications': specifications,
      'proprietaire_id': proprietaireId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class RentalModel extends Rental {
  const RentalModel({
    required super.id,
    required super.equipmentId,
    required super.locataireId,
    required super.dateDebut,
    required super.dateFin,
    required super.dureeJours,
    required super.prixTotal,
    super.cautionVersee,
    super.cautionRetournee,
    required super.statut,
    super.commentaireLocataire,
    super.commentaireProprietaire,
    super.evaluationNote,
    required super.createdAt,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['id'] ?? '',
      equipmentId: json['equipement_id'] ?? '',
      locataireId: json['locataire_id'] ?? '',
      dateDebut: DateTime.parse(json['date_debut']),
      dateFin: DateTime.parse(json['date_fin']),
      dureeJours: json['duree_jours'] ?? 0,
      prixTotal: double.tryParse(json['prix_total']?.toString() ?? '0') ?? 0.0,
      cautionVersee: double.tryParse(json['caution_versee']?.toString() ?? '0') ?? 0.0,
      cautionRetournee: json['caution_retournee'] ?? false,
      statut: json['statut'] ?? 'demande',
      commentaireLocataire: json['commentaire_locataire'],
      commentaireProprietaire: json['commentaire_proprietaire'],
      evaluationNote: json['evaluation_note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipement_id': equipmentId,
      'locataire_id': locataireId,
      'date_debut': dateDebut.toIso8601String().split('T')[0],
      'date_fin': dateFin.toIso8601String().split('T')[0],
      'duree_jours': dureeJours,
      'prix_total': prixTotal,
      'caution_versee': cautionVersee,
      'caution_retournee': cautionRetournee,
      'statut': statut,
      'commentaire_locataire': commentaireLocataire,
      'commentaire_proprietaire': commentaireProprietaire,
      'evaluation_note': evaluationNote,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
