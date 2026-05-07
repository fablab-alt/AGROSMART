import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';
import '../repositories/calendrier_repository.dart';

class GetActivites {
  final CalendrierRepository repository;

  GetActivites(this.repository);

  Future<Either<Failure, List<Activite>>> call({
    String? parcelleId,
    TypeActivite? typeActivite,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 50,
  }) async {
    return await repository.getActivites(
      parcelleId: parcelleId,
      typeActivite: typeActivite,
      statut: statut,
      priorite: priorite,
      dateDebut: dateDebut,
      dateFin: dateFin,
      page: page,
      limit: limit,
    );
  }
}
