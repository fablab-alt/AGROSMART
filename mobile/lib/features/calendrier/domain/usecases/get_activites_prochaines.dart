import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';
import '../repositories/calendrier_repository.dart';

class GetActivitesProchaines {
  final CalendrierRepository repository;

  GetActivitesProchaines(this.repository);

  Future<Either<Failure, List<Activite>>> call(int jours) async {
    return await repository.getActivitesProchaines(jours);
  }
}
