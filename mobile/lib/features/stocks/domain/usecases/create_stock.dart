import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stock.dart';
import '../repositories/stock_repository.dart';

/// Use case pour créer un stock
class CreateStock implements UseCase<Stock, CreateStockParams> {
  final StockRepository repository;

  CreateStock(this.repository);

  @override
  Future<Either<Failure, Stock>> call(CreateStockParams params) async {
    return await repository.createStock(
      nom: params.nom,
      categorie: params.categorie,
      type: params.type,
      quantite: params.quantite,
      unite: params.unite,
      seuilAlerte: params.seuilAlerte,
      parcelleId: params.parcelleId,
      prixUnitaire: params.prixUnitaire,
      dateAchat: params.dateAchat,
      dateExpiration: params.dateExpiration,
      fournisseur: params.fournisseur,
      localisation: params.localisation,
      notes: params.notes,
    );
  }
}

/// Paramètres pour le use case CreateStock
class CreateStockParams {
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

  const CreateStockParams({
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
}
