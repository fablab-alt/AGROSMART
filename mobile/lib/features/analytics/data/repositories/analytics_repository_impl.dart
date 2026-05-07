import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AnalyticsData>> getStats() async {
    try {
      final remoteData = await remoteDataSource.getStats();
      return Right(remoteData);
    } catch (e) {
      return Left(ServerFailure('Erreur lors du chargement des analytics: ${e.toString()}'));
    }
  }
}
