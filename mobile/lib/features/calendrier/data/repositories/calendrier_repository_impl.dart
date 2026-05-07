import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/activite.dart';
import '../../domain/repositories/calendrier_repository.dart';
import '../datasources/calendrier_remote_datasource.dart';

class CalendrierRepositoryImpl implements CalendrierRepository {
  final CalendrierRemoteDataSource remoteDataSource;

  CalendrierRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Activite>>> getActivites({
    String? parcelleId,
    TypeActivite? typeActivite,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final activites = await remoteDataSource.getActivites(
        parcelleId: parcelleId,
        typeActivite: typeActivite,
        statut: statut,
        priorite: priorite,
        dateDebut: dateDebut,
        dateFin: dateFin,
        page: page,
        limit: limit,
      );
      return Right(activites);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Activite>> getActiviteById(String id) async {
    try {
      final activite = await remoteDataSource.getActiviteById(id);
      return Right(activite);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Activite>> createActivite({
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
    try {
      final data = <String, dynamic>{
        'titre': titre,
        'typeActivite': typeActivite.apiValue,
        'dateDebut': dateDebut.toIso8601String(),
        'priorite': priorite.apiValue,
      };

      if (description != null) data['description'] = description;
      if (dateFin != null) data['dateFin'] = dateFin.toIso8601String();
      if (parcelleId != null) data['parcelleId'] = parcelleId;
      if (dateRappel != null) data['dateRappel'] = dateRappel.toIso8601String();
      if (coutEstime != null) data['coutEstime'] = coutEstime;
      if (produitsUtilises != null) data['produitsUtilises'] = produitsUtilises;
      if (estRecurrente) {
        data['estRecurrente'] = true;
        if (frequenceJours != null) data['frequenceJours'] = frequenceJours;
        if (dateFinRecurrence != null) {
          data['dateFinRecurrence'] = dateFinRecurrence.toIso8601String();
        }
      }
      if (notesTechniques != null) data['notesTechniques'] = notesTechniques;

      final activite = await remoteDataSource.createActivite(data);
      return Right(activite);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Activite>> updateActivite({
    required String id,
    String? titre,
    String? description,
    TypeActivite? typeActivite,
    DateTime? dateDebut,
    DateTime? dateFin,
    DateTime? dateRappel,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    double? coutEstime,
    List<String>? produitsUtilises,
    String? notesTechniques,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (titre != null) updates['titre'] = titre;
      if (description != null) updates['description'] = description;
      if (typeActivite != null) updates['typeActivite'] = typeActivite.apiValue;
      if (dateDebut != null) updates['dateDebut'] = dateDebut.toIso8601String();
      if (dateFin != null) updates['dateFin'] = dateFin.toIso8601String();
      if (dateRappel != null)
        updates['dateRappel'] = dateRappel.toIso8601String();
      if (statut != null) updates['statut'] = statut.apiValue;
      if (priorite != null) updates['priorite'] = priorite.apiValue;
      if (coutEstime != null) updates['coutEstime'] = coutEstime;
      if (produitsUtilises != null)
        updates['produitsUtilises'] = produitsUtilises;
      if (notesTechniques != null) updates['notesTechniques'] = notesTechniques;

      final activite = await remoteDataSource.updateActivite(id, updates);
      return Right(activite);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteActivite(String id) async {
    try {
      await remoteDataSource.deleteActivite(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Activite>>> getActivitesProchaines(
    int jours,
  ) async {
    try {
      final activites = await remoteDataSource.getActivitesProchaines(jours);
      return Right(activites);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }

  @override
  Future<Either<Failure, Activite>> marquerTerminee(String id) async {
    try {
      final activite = await remoteDataSource.marquerTerminee(id);
      return Right(activite);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur serveur'));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure('Erreur inattendue: $e'));
    }
  }
}
