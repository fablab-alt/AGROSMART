import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_remote_datasource.dart';

/// Implémentation du repository de stocks
class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remoteDataSource;

  StockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Stock>>> getStocks({
    String? categorie,
    String? parcelleId,
    bool? estActif,
  }) async {
    try {
      final stocks = await remoteDataSource.getStocks(
        categorie: categorie,
        parcelleId: parcelleId,
        estActif: estActif,
      );
      return Right(stocks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stock>> getStockById(String id) async {
    try {
      final stock = await remoteDataSource.getStockById(id);
      return Right(stock);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stock>> createStock({
    required String nom,
    required StockCategory categorie,
    required String type,
    required double quantite,
    required String unite,
    required double seuilAlerte,
    String? parcelleId,
    double? prixUnitaire,
    DateTime? dateAchat,
    DateTime? dateExpiration,
    String? fournisseur,
    String? localisation,
    String? notes,
  }) async {
    try {
      final stockData = {
        'nom': nom,
        'categorie': categorie.name,
        'type': type,
        'quantite': quantite,
        'unite': unite,
        'seuilAlerte': seuilAlerte,
        if (parcelleId != null) 'parcelleId': parcelleId,
        if (prixUnitaire != null) 'prixUnitaire': prixUnitaire,
        if (dateAchat != null)
          'dateAchat': dateAchat.toIso8601String().split('T')[0],
        if (dateExpiration != null)
          'dateExpiration': dateExpiration.toIso8601String().split('T')[0],
        if (fournisseur != null) 'fournisseur': fournisseur,
        if (localisation != null) 'localisation': localisation,
        if (notes != null) 'notes': notes,
      };

      final stock = await remoteDataSource.createStock(stockData);
      return Right(stock);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stock>> updateStock({
    required String id,
    String? nom,
    String? type,
    double? quantite,
    String? unite,
    double? seuilAlerte,
    String? parcelleId,
    double? prixUnitaire,
    DateTime? dateAchat,
    DateTime? dateExpiration,
    String? fournisseur,
    String? localisation,
    String? notes,
  }) async {
    try {
      final stockData = <String, dynamic>{};
      if (nom != null) stockData['nom'] = nom;
      if (type != null) stockData['type'] = type;
      if (quantite != null) stockData['quantite'] = quantite;
      if (unite != null) stockData['unite'] = unite;
      if (seuilAlerte != null) stockData['seuilAlerte'] = seuilAlerte;
      if (parcelleId != null) stockData['parcelleId'] = parcelleId;
      if (prixUnitaire != null) stockData['prixUnitaire'] = prixUnitaire;
      if (dateAchat != null)
        stockData['dateAchat'] = dateAchat.toIso8601String().split('T')[0];
      if (dateExpiration != null)
        stockData['dateExpiration'] = dateExpiration.toIso8601String().split(
          'T',
        )[0];
      if (fournisseur != null) stockData['fournisseur'] = fournisseur;
      if (localisation != null) stockData['localisation'] = localisation;
      if (notes != null) stockData['notes'] = notes;

      final stock = await remoteDataSource.updateStock(id, stockData);
      return Right(stock);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStock(String id) async {
    try {
      await remoteDataSource.deleteStock(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> addMouvement({
    required String stockId,
    required TypeMouvement typeMouvement,
    required double quantite,
    String? motif,
    String? reference,
  }) async {
    try {
      final mouvementData = {
        'typeMouvement': typeMouvement.name,
        'quantite': quantite,
        if (motif != null) 'motif': motif,
        if (reference != null) 'reference': reference,
      };

      final result = await remoteDataSource.addMouvement(
        stockId,
        mouvementData,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AlerteStock>>> getAlertes(String stockId) async {
    try {
      final alertes = await remoteDataSource.getAlertes(stockId);
      return Right(alertes);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AlerteStock>> marquerAlerteLue(
    String stockId,
    String alerteId,
  ) async {
    try {
      final alerte = await remoteDataSource.marquerAlerteLue(stockId, alerteId);
      return Right(alerte);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getStatistiques() async {
    try {
      final stats = await remoteDataSource.getStatistiques();
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
