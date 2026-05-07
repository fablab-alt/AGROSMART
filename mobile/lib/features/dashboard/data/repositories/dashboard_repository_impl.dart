import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../models/dashboard_data_model.dart';
import '../models/cached_dashboard_data.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, DashboardData>> getDashboardData() async {
    try {
      final remoteData = await remoteDataSource.getDashboardData();
      // Cache the remote data as JSON in Isar
      final cached = CachedDashboardData()
        ..key = 'dashboard_summary'
        ..json = jsonEncode(remoteData.toJson())
        ..lastUpdated = DateTime.now();
      await localDataSource.cacheDashboardData(cached);
      return Right(remoteData);
    } on ServerException catch (e) {
      return _fallbackToCache(e.message ?? 'Erreur serveur');
    } catch (e) {
      return _fallbackToCache('Erreur inattendue et pas de cache');
    }
  }

  Future<Either<Failure, DashboardData>> _fallbackToCache(
    String errorMsg,
  ) async {
    try {
      final localData = await localDataSource.getLastDashboardData();
      if (localData?.json != null) {
        final parsed = DashboardDataModel.fromJson(
          jsonDecode(localData!.json!),
        );
        return Right(parsed);
      }
      return Left(ServerFailure(errorMsg));
    } catch (_) {
      return Left(ServerFailure(errorMsg));
    }
  }
}
