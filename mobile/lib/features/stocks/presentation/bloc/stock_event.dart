import 'package:equatable/equatable.dart';
import '../../domain/entities/stock.dart';

/// Événements du StockBloc
abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

/// Charger la liste des stocks
class LoadStocks extends StockEvent {
  final String? categorie;
  final String? parcelleId;
  final bool? estActif;

  const LoadStocks({this.categorie, this.parcelleId, this.estActif});

  @override
  List<Object?> get props => [categorie, parcelleId, estActif];
}

/// Charger un stock spécifique
class LoadStockDetail extends StockEvent {
  final String stockId;

  const LoadStockDetail(this.stockId);

  @override
  List<Object> get props => [stockId];
}

/// Créer un nouveau stock
class CreateNewStock extends StockEvent {
  final String nom;
  final StockCategory categorie;
  final String type;
  final double quantite;
  final String unite;
  final double seuilAlerte;
  final String? parcelleId;
  final double? prixUnitaire;
  final DateTime? dateAchat;
  final DateTime? dateExpiration;
  final String? fournisseur;
  final String? localisation;
  final String? notes;

  const CreateNewStock({
    required this.nom,
    required this.categorie,
    required this.type,
    required this.quantite,
    required this.unite,
    required this.seuilAlerte,
    this.parcelleId,
    this.prixUnitaire,
    this.dateAchat,
    this.dateExpiration,
    this.fournisseur,
    this.localisation,
    this.notes,
  });

  @override
  List<Object?> get props => [
    nom,
    categorie,
    type,
    quantite,
    unite,
    seuilAlerte,
    parcelleId,
    prixUnitaire,
    dateAchat,
    dateExpiration,
    fournisseur,
    localisation,
    notes,
  ];
}

/// Ajouter un mouvement de stock
class AddStockMouvement extends StockEvent {
  final String stockId;
  final TypeMouvement typeMouvement;
  final double quantite;
  final String? motif;
  final String? reference;

  const AddStockMouvement({
    required this.stockId,
    required this.typeMouvement,
    required this.quantite,
    this.motif,
    this.reference,
  });

  @override
  List<Object?> get props => [
    stockId,
    typeMouvement,
    quantite,
    motif,
    reference,
  ];
}

/// Marquer une alerte comme lue
class MarkAlerteAsRead extends StockEvent {
  final String stockId;
  final String alerteId;

  const MarkAlerteAsRead({required this.stockId, required this.alerteId});

  @override
  List<Object> get props => [stockId, alerteId];
}

/// Supprimer un stock
class DeleteStockEvent extends StockEvent {
  final String stockId;

  const DeleteStockEvent(this.stockId);

  @override
  List<Object> get props => [stockId];
}

/// Charger les statistiques
class LoadStockStatistics extends StockEvent {
  const LoadStockStatistics();
}

/// Rafraîchir la liste des stocks
class RefreshStocks extends StockEvent {
  const RefreshStocks();
}
