import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/stock.dart';
import '../repositories/stock_repository.dart';

/// Use case pour récupérer la liste des stocks
class GetStocks implements UseCase<List<Stock>, GetStocksParams> {
  final StockRepository repository;

  GetStocks(this.repository);

  @override
  Future<Either<Failure, List<Stock>>> call(GetStocksParams params) async {
    return await repository.getStocks(
      categorie: params.categorie,
      parcelleId: params.parcelleId,
      estActif: params.estActif,
    );
  }
}

/// Paramètres pour le use case GetStocks
class GetStocksParams {
  final String? categorie;
  final String? parcelleId;
  final bool? estActif;

  const GetStocksParams({this.categorie, this.parcelleId, this.estActif});
}
