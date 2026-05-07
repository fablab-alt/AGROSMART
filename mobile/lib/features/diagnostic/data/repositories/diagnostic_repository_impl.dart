import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/diagnostic/data/datasources/diagnostics_remote_data_source.dart';
import 'package:agriculture/features/diagnostic/data/models/diagnostic_model.dart';

abstract class DiagnosticRepository {
  Future<Either<Failure, DiagnosticModel>> analyzePlant(File image, {String? cropType, String? parcelleId});
  Future<Either<Failure, List<DiagnosticModel>>> getHistory();
}

class DiagnosticRepositoryImpl implements DiagnosticRepository {
  final DiagnosticRemoteDataSource remoteDataSource;

  DiagnosticRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DiagnosticModel>> analyzePlant(File image, {String? cropType, String? parcelleId}) async {
    try {
      final result = await remoteDataSource.analyzePlant(image, cropType: cropType, parcelleId: parcelleId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DiagnosticModel>>> getHistory() async {
    try {
      final result = await remoteDataSource.getHistory();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
