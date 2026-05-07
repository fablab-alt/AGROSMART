import 'package:equatable/equatable.dart';

/// Entité Stock - Représente un stock de ressource agricole
class Stock extends Equatable {
  final String id;
  final String userId;
  final String? parcelleId;
  final String nom;
  final StockCategory categorie;
  final String type;
  final double quantite;
  final String unite;
  final double seuilAlerte;
  final double? prixUnitaire;
  final DateTime? dateAchat;
  final DateTime? dateExpiration;
  final String? fournisseur;
  final String? localisation;
  final String? notes;
  final bool estActif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Parcelle? parcelle;
  final int? nombreMouvements;
  final int? nombreAlertesNonLues;

  const Stock({
    required this.id,
    required this.userId,
    this.parcelleId,
    required this.nom,
    required this.categorie,
    required this.type,
    required this.quantite,
    required this.unite,
    required this.seuilAlerte,
    this.prixUnitaire,
    this.dateAchat,
    this.dateExpiration,
    this.fournisseur,
    this.localisation,
    this.notes,
    required this.estActif,
    required this.createdAt,
    required this.updatedAt,
    this.parcelle,
    this.nombreMouvements,
    this.nombreAlertesNonLues,
  });

  /// Vérifie si le stock est en dessous du seuil d'alerte
  bool get estEnDessousDuSeuil => quantite <= seuilAlerte;

  /// Vérifie si le stock est épuisé
  bool get estEpuise => quantite == 0;

  /// Vérifie si le stock a une date d'expiration proche (moins de 30 jours)
  bool get expirationProche {
    if (dateExpiration == null) return false;
    final difference = dateExpiration!.difference(DateTime.now()).inDays;
    return difference > 0 && difference <= 30;
  }

  /// Calcule le pourcentage du stock par rapport au seuil
  double get pourcentageDuSeuil {
    if (seuilAlerte == 0) return 100;
    return (quantite / seuilAlerte) * 100;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    parcelleId,
    nom,
    categorie,
    type,
    quantite,
    unite,
    seuilAlerte,
    prixUnitaire,
    dateAchat,
    dateExpiration,
    fournisseur,
    localisation,
    notes,
    estActif,
    createdAt,
    updatedAt,
  ];
}

/// Parcelle simplifiée pour l'association avec le stock
class Parcelle extends Equatable {
  final String id;
  final String nom;

  const Parcelle({required this.id, required this.nom});

  @override
  List<Object?> get props => [id, nom];
}

/// Catégorie de stock
enum StockCategory {
  semences,
  engrais,
  pesticides,
  herbicides,
  outils,
  recoltes,
  autres,
}

/// Extension pour obtenir le label lisible d'une catégorie
extension StockCategoryExtension on StockCategory {
  String get label {
    switch (this) {
      case StockCategory.semences:
        return 'Semences';
      case StockCategory.engrais:
        return 'Engrais';
      case StockCategory.pesticides:
        return 'Pesticides';
      case StockCategory.herbicides:
        return 'Herbicides';
      case StockCategory.outils:
        return 'Outils';
      case StockCategory.recoltes:
        return 'Récoltes';
      case StockCategory.autres:
        return 'Autres';
    }
  }

  String get icon {
    switch (this) {
      case StockCategory.semences:
        return '🌱';
      case StockCategory.engrais:
        return '🧪';
      case StockCategory.pesticides:
        return '🐛';
      case StockCategory.herbicides:
        return '🌿';
      case StockCategory.outils:
        return '🔧';
      case StockCategory.recoltes:
        return '🌾';
      case StockCategory.autres:
        return '📦';
    }
  }
}

/// Mouvement de stock
class MouvementStock extends Equatable {
  final String id;
  final String stockId;
  final TypeMouvement typeMouvement;
  final double quantite;
  final double quantiteAvant;
  final double quantiteApres;
  final String? motif;
  final String? reference;
  final DateTime createdAt;

  const MouvementStock({
    required this.id,
    required this.stockId,
    required this.typeMouvement,
    required this.quantite,
    required this.quantiteAvant,
    required this.quantiteApres,
    this.motif,
    this.reference,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    stockId,
    typeMouvement,
    quantite,
    quantiteAvant,
    quantiteApres,
    motif,
    reference,
    createdAt,
  ];
}

/// Type de mouvement de stock
enum TypeMouvement { entree, sortie, ajustement, perte }

/// Extension pour obtenir le label lisible d'un type de mouvement
extension TypeMouvementExtension on TypeMouvement {
  String get label {
    switch (this) {
      case TypeMouvement.entree:
        return 'Entrée';
      case TypeMouvement.sortie:
        return 'Sortie';
      case TypeMouvement.ajustement:
        return 'Ajustement';
      case TypeMouvement.perte:
        return 'Perte';
    }
  }

  String get icon {
    switch (this) {
      case TypeMouvement.entree:
        return '➕';
      case TypeMouvement.sortie:
        return '➖';
      case TypeMouvement.ajustement:
        return '⚖️';
      case TypeMouvement.perte:
        return '🗑️';
    }
  }
}

/// Alerte de stock
class AlerteStock extends Equatable {
  final String id;
  final String stockId;
  final TypeAlerte typeAlerte;
  final String message;
  final bool estLue;
  final DateTime createdAt;

  const AlerteStock({
    required this.id,
    required this.stockId,
    required this.typeAlerte,
    required this.message,
    required this.estLue,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    stockId,
    typeAlerte,
    message,
    estLue,
    createdAt,
  ];
}

/// Type d'alerte de stock
enum TypeAlerte { stockBas, expirationProche, stockEpuise }

/// Extension pour obtenir le label lisible d'un type d'alerte
extension TypeAlerteExtension on TypeAlerte {
  String get label {
    switch (this) {
      case TypeAlerte.stockBas:
        return 'Stock bas';
      case TypeAlerte.expirationProche:
        return 'Expiration proche';
      case TypeAlerte.stockEpuise:
        return 'Stock épuisé';
    }
  }

  String get icon {
    switch (this) {
      case TypeAlerte.stockBas:
        return '⚠️';
      case TypeAlerte.expirationProche:
        return '⏰';
      case TypeAlerte.stockEpuise:
        return '🚫';
    }
  }
}
