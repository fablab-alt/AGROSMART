import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';
import '../repositories/calendrier_repository.dart';

class UpdateActivite {
  final CalendrierRepository repository;

  UpdateActivite(this.repository);

  Future<Either<Failure, Activite>> call({
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
  }) async {
    return await repository.updateActivite(
      id: id,
      titre: titre,
      description: description,
      typeActivite: typeActivite,
      statut: statut,
      priorite: priorite,
      dateDebut: dateDebut,
      dateFin: dateFin,
      dateRappel: dateRappel,
      coutEstime: coutEstime,
      notesTechniques: notesTechniques,
      produitsUtilises: produitsUtilises,
    );
  }
}
