import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';

abstract class CalendrierRepository {
  Future<Either<Failure, List<Activite>>> getActivites({
    String? parcelleId,
    TypeActivite? typeActivite,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 50,
  });

  Future<Either<Failure, Activite>> getActiviteById(String id);

  Future<Either<Failure, Activite>> createActivite({
    String? parcelleId,
    required String titre,
    String? description,
    required TypeActivite typeActivite,
    PrioriteActivite priorite = PrioriteActivite.moyenne,
    required DateTime dateDebut,
    DateTime? dateFin,
    DateTime? dateRappel,
    bool estRecurrente = false,
    int? frequenceJours,
    DateTime? dateFinRecurrence,
    double? coutEstime,
    String? notesTechniques,
    List<String>? produitsUtilises,
  });

  Future<Either<Failure, Activite>> updateActivite({
    required String id,
    String? titre,
    String? description,
    TypeActivite? typeActivite,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateRappel,
    double? coutEstime,
    String? notesTechniques,
    List<String>? produitsUtilises,
  });

  Future<Either<Failure, void>> deleteActivite(String id);

  Future<Either<Failure, List<Activite>>> getActivitesProchaines(int jours);

  Future<Either<Failure, Activite>> marquerTerminee(String id);
}
