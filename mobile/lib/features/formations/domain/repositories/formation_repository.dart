import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/formations/domain/entities/formation.dart';
import 'package:dartz/dartz.dart';

abstract class FormationRepository {
  Future<Either<Failure, List<Formation>>> getFormations();
}
