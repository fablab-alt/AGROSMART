import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/formations/data/datasources/formation_remote_data_source.dart';
import 'package:agriculture/features/formations/domain/entities/formation.dart';
import 'package:agriculture/features/formations/domain/repositories/formation_repository.dart';
import 'package:dartz/dartz.dart';

class FormationRepositoryImpl implements FormationRepository {
  final FormationRemoteDataSource remoteDataSource;

  FormationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Formation>>> getFormations() async {
    try {
      final remoteFormations = await remoteDataSource.getFormations();
      return Right(remoteFormations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
