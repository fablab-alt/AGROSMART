import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stock.dart';
import '../repositories/stock_repository.dart';

/// Use case pour ajouter un mouvement de stock
class AddMouvement
    implements UseCase<Map<String, dynamic>, AddMouvementParams> {
  final StockRepository repository;

  AddMouvement(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
    AddMouvementParams params,
  ) async {
    return await repository.addMouvement(
      stockId: params.stockId,
      typeMouvement: params.typeMouvement,
      quantite: params.quantite,
      motif: params.motif,
      reference: params.reference,
    );
  }
}

/// Paramètres pour le use case AddMouvement
class AddMouvementParams {
  final String stockId;
  final TypeMouvement typeMouvement;
  final double quantite;
  final String? motif;
  final String? reference;

  const AddMouvementParams({
    required this.stockId,
    required this.typeMouvement,
    required this.quantite,
    this.motif,
    this.reference,
  });
}
