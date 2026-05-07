import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activite.dart';
import '../repositories/calendrier_repository.dart';

class MarquerActiviteTerminee {
  final CalendrierRepository repository;

  MarquerActiviteTerminee(this.repository);

  Future<Either<Failure, Activite>> call(String id) async {
    return await repository.marquerTerminee(id);
  }
}
