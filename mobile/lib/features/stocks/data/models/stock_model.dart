import '../../domain/entities/stock.dart';

/// Modèle Stock pour la sérialisation JSON
class StockModel extends Stock {
  const StockModel({
    required super.id,
    required super.userId,
    super.parcelleId,
    required super.nom,
    required super.categorie,
    required super.type,
    required super.quantite,
    required super.unite,
    required super.seuilAlerte,
    super.prixUnitaire,
    super.dateAchat,
    super.dateExpiration,
    super.fournisseur,
    super.localisation,
    super.notes,
    required super.estActif,
    required super.createdAt,
    required super.updatedAt,
    super.parcelle,
    super.nombreMouvements,
    super.nombreAlertesNonLues,
  });

  /// Crée un StockModel depuis un JSON
  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      parcelleId: json['parcelleId'] as String?,
      nom: json['nom'] as String,
      categorie: _parseCategorieFromString(json['categorie'] as String),
      type: json['type'] as String,
      quantite: _parseDouble(json['quantite']),
      unite: json['unite'] as String,
      seuilAlerte: _parseDouble(json['seuilAlerte']),
      prixUnitaire: json['prixUnitaire'] != null
          ? _parseDouble(json['prixUnitaire'])
          : null,
      dateAchat: json['dateAchat'] != null
          ? DateTime.parse(json['dateAchat'] as String)
          : null,
      dateExpiration: json['dateExpiration'] != null
          ? DateTime.parse(json['dateExpiration'] as String)
          : null,
      fournisseur: json['fournisseur'] as String?,
      localisation: json['localisation'] as String?,
      notes: json['notes'] as String?,
      estActif: json['estActif'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      parcelle: json['parcelle'] != null
          ? ParcelleModel.fromJson(json['parcelle'] as Map<String, dynamic>)
          : null,
      nombreMouvements: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>)['mouvements'] as int?
          : null,
      nombreAlertesNonLues: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>)['alertesStock'] as int?
          : null,
    );
  }

  /// Convertit le StockModel en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'parcelleId': parcelleId,
      'nom': nom,
      'categorie': categorie.name,
      'type': type,
      'quantite': quantite,
      'unite': unite,
      'seuilAlerte': seuilAlerte,
      'prixUnitaire': prixUnitaire,
      'dateAchat': dateAchat?.toIso8601String(),
      'dateExpiration': dateExpiration?.toIso8601String(),
      'fournisseur': fournisseur,
      'localisation': localisation,
      'notes': notes,
      'estActif': estActif,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static StockCategory _parseCategorieFromString(String categorie) {
    return StockCategory.values.firstWhere(
      (e) => e.name == categorie,
      orElse: () => StockCategory.autres,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }
}

/// Modèle Parcelle pour la sérialisation JSON
class ParcelleModel extends Parcelle {
  const ParcelleModel({required super.id, required super.nom});

  factory ParcelleModel.fromJson(Map<String, dynamic> json) {
    return ParcelleModel(id: json['id'] as String, nom: json['nom'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom};
  }
}

/// Modèle MouvementStock pour la sérialisation JSON
class MouvementStockModel extends MouvementStock {
  const MouvementStockModel({
    required super.id,
    required super.stockId,
    required super.typeMouvement,
    required super.quantite,
    required super.quantiteAvant,
    required super.quantiteApres,
    super.motif,
    super.reference,
    required super.createdAt,
  });

  factory MouvementStockModel.fromJson(Map<String, dynamic> json) {
    return MouvementStockModel(
      id: json['id'] as String,
      stockId: json['stockId'] as String,
      typeMouvement: _parseTypeMouvementFromString(
        json['typeMouvement'] as String,
      ),
      quantite: StockModel._parseDouble(json['quantite']),
      quantiteAvant: StockModel._parseDouble(json['quantiteAvant']),
      quantiteApres: StockModel._parseDouble(json['quantiteApres']),
      motif: json['motif'] as String?,
      reference: json['reference'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stockId': stockId,
      'typeMouvement': typeMouvement.name,
      'quantite': quantite,
      'quantiteAvant': quantiteAvant,
      'quantiteApres': quantiteApres,
      'motif': motif,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TypeMouvement _parseTypeMouvementFromString(String type) {
    return TypeMouvement.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TypeMouvement.sortie,
    );
  }
}

/// Modèle AlerteStock pour la sérialisation JSON
class AlerteStockModel extends AlerteStock {
  const AlerteStockModel({
    required super.id,
    required super.stockId,
    required super.typeAlerte,
    required super.message,
    required super.estLue,
    required super.createdAt,
  });

  factory AlerteStockModel.fromJson(Map<String, dynamic> json) {
    return AlerteStockModel(
      id: json['id'] as String,
      stockId: json['stockId'] as String,
      typeAlerte: _parseTypeAlerteFromString(json['typeAlerte'] as String),
      message: json['message'] as String,
      estLue: json['estLue'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stockId': stockId,
      'typeAlerte': typeAlerte.name,
      'message': message,
      'estLue': estLue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TypeAlerte _parseTypeAlerteFromString(String type) {
    return TypeAlerte.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TypeAlerte.stockBas,
    );
  }
}
