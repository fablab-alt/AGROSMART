import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/calendrier_repository.dart';

class DeleteActivite {
  final CalendrierRepository repository;

  DeleteActivite(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteActivite(id);
  }
}
