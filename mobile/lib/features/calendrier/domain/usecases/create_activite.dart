import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';
import '../repositories/calendrier_repository.dart';

class CreateActivite {
  final CalendrierRepository repository;

  CreateActivite(this.repository);

  Future<Either<Failure, Activite>> call({
    required String titre,
    String? description,
    required TypeActivite typeActivite,
    required DateTime dateDebut,
    DateTime? dateFin,
    String? parcelleId,
    PrioriteActivite priorite = PrioriteActivite.moyenne,
    DateTime? dateRappel,
    double? coutEstime,
    List<String>? produitsUtilises,
    bool estRecurrente = false,
    int? frequenceJours,
    DateTime? dateFinRecurrence,
    String? notesTechniques,
  }) async {
    return await repository.createActivite(
      titre: titre,
      description: description,
      typeActivite: typeActivite,
      dateDebut: dateDebut,
      dateFin: dateFin,
      parcelleId: parcelleId,
      priorite: priorite,
      dateRappel: dateRappel,
      coutEstime: coutEstime,
      produitsUtilises: produitsUtilises,
      estRecurrente: estRecurrente,
      frequenceJours: frequenceJours,
      dateFinRecurrence: dateFinRecurrence,
      notesTechniques: notesTechniques,
    );
  }
}
