import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock.dart';

/// Interface du repository de stocks
abstract class StockRepository {
  /// Récupère la liste des stocks
  Future<Either<Failure, List<Stock>>> getStocks({
    String? categorie,
    String? parcelleId,
    bool? estActif,
  });

  /// Récupère un stock par son ID
  Future<Either<Failure, Stock>> getStockById(String id);

  /// Crée un nouveau stock
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
  });

  /// Met à jour un stock
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
  });

  /// Supprime un stock
  Future<Either<Failure, void>> deleteStock(String id);

  /// Ajoute un mouvement de stock
  Future<Either<Failure, Map<String, dynamic>>> addMouvement({
    required String stockId,
    required TypeMouvement typeMouvement,
    required double quantite,
    String? motif,
    String? reference,
  });

  /// Récupère les alertes d'un stock
  Future<Either<Failure, List<AlerteStock>>> getAlertes(String stockId);

  /// Marque une alerte comme lue
  Future<Either<Failure, AlerteStock>> marquerAlerteLue(
    String stockId,
    String alerteId,
  );

  /// Récupère les statistiques des stocks
  Future<Either<Failure, Map<String, dynamic>>> getStatistiques();
}
