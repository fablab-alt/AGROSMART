import 'package:equatable/equatable.dart';
import '../../domain/entities/stock.dart';

/// États du StockBloc
abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

/// État initial
class StockInitial extends StockState {}

/// État de chargement
class StockLoading extends StockState {}

/// Liste des stocks chargée avec succès
class StocksLoaded extends StockState {
  final List<Stock> stocks;
  final Map<String, dynamic>? statistics;

  const StocksLoaded(this.stocks, {this.statistics});

  @override
  List<Object?> get props => [stocks, statistics];
}

/// Détails d'un stock chargés avec succès
class StockDetailLoaded extends StockState {
  final Stock stock;
  final List<MouvementStock>? mouvements;
  final List<AlerteStock>? alertes;

  const StockDetailLoaded(
    this.stock, {
    this.mouvements,
    this.alertes,
  });

  @override
  List<Object?> get props => [stock, mouvements, alertes];
}

/// Stock créé avec succès
class StockCreated extends StockState {
  final Stock stock;

  const StockCreated(this.stock);

  @override
  List<Object> get props => [stock];
}

/// Mouvement ajouté avec succès
class MouvementAdded extends StockState {
  final Stock stock;
  final MouvementStock mouvement;

  const MouvementAdded(this.stock, this.mouvement);

  @override
  List<Object> get props => [stock, mouvement];
}

/// Alerte marquée comme lue
class AlerteMarkedAsRead extends StockState {
  final AlerteStock alerte;

  const AlerteMarkedAsRead(this.alerte);

  @override
  List<Object> get props => [alerte];
}

/// Stock supprimé
class StockDeleted extends StockState {}

/// État d'erreur
class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object> get props => [message];
}

/// État de chargement des statistiques
class StockStatisticsLoaded extends StockState {
  final Map<String, dynamic> statistics;

  const StockStatisticsLoaded(this.statistics);

  @override
  List<Object> get props => [statistics];
}
