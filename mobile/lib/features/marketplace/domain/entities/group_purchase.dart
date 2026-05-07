import 'package:equatable/equatable.dart';

class GroupPurchase extends Equatable {
  final String id;
  final String organisateurId;
  final String produitType;
  final String description;
  final String categorie;
  final int quantiteObjectif;
  final int quantiteActuelle;
  final String unite;
  final double prixUnitaire;
  final double prixGroupe;
  final double economiePourcentage;
  final DateTime dateLimite;
  final String statut;
  final String localisationLivraison;

  const GroupPurchase({
    required this.id,
    required this.organisateurId,
    required this.produitType,
    required this.description,
    required this.categorie,
    required this.quantiteObjectif,
    required this.quantiteActuelle,
    required this.unite,
    required this.prixUnitaire,
    required this.prixGroupe,
    required this.economiePourcentage,
    required this.dateLimite,
    required this.statut,
    required this.localisationLivraison,
  });

  @override
  List<Object?> get props => [
    id, organisateurId, produitType, description, categorie, 
    quantiteObjectif, quantiteActuelle, unite, prixUnitaire, 
    prixGroupe, economiePourcentage, dateLimite, statut, localisationLivraison
  ];

  double get progressPercentage {
    if (quantiteObjectif == 0) return 0.0;
    return (quantiteActuelle / quantiteObjectif).clamp(0.0, 1.0);
  }
}
