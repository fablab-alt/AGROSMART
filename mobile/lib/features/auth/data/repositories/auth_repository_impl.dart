import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, User>> login(
    String identifier,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.login(identifier, password);
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtp(
    String identifier,
    String code,
  ) async {
    try {
      final user = await remoteDataSource.verifyOtp(identifier, code);
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Erreur inattendue'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Appeler le backend pour invalider le refresh token côté serveur
      try {
        await dioClient.post('/auth/logout');
      } catch (_) {
        // Ne pas bloquer le logout local si l'appel backend échoue
      }
      // Nettoyer le stockage local
      await secureStorage.clearAll();
      return const Right(null);
    } catch (e) {
      // Toujours nettoyer même en cas d'erreur
      await secureStorage.clearAll();
      return const Right(null); // Toujours réussir le logout côté UI
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final hasToken = await secureStorage.hasAccessToken();
      if (!hasToken) {
        return const Right(null);
      }
      final user = await remoteDataSource.getMe();
      return Right(user);
    } on ServerFailure catch (e) {
      // Token expiré ou invalide → nettoyer
      await secureStorage.clearAll();
      return Left(e);
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String nom,
    required String prenoms,
    required String telephone,
    required String password,
    String? email,
    String? adresse,
    String languePreferee = 'fr',
    String role = 'PRODUCTEUR',
    String? typeProducteur,
    String? production3Mois,
    String? superficie,
    String? uniteSuperficie,
    String? systemeIrrigation,
    String? productionMois1,
    String? productionMois2,
    String? productionMois3,
    List<Map<String, dynamic>>? productions,
  }) async {
    try {
      final user = await remoteDataSource.register(
        nom: nom,
        prenoms: prenoms,
        telephone: telephone,
        password: password,
        email: email,
        adresse: adresse,
        languePreferee: languePreferee,
        role: role,
        typeProducteur: typeProducteur,
        production3Mois: production3Mois,
        superficie: superficie,
        uniteSuperficie: uniteSuperficie,
        systemeIrrigation: systemeIrrigation,
        productionMois1: productionMois1,
        productionMois2: productionMois2,
        productionMois3: productionMois3,
        productions: productions,
      );
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(ServerFailure('Erreur lors de l\'inscription'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String nom,
    required String prenoms,
    required String telephone,
    String? email,
    String? typeProducteur,
    String? region,
    File? photo,
    double? superficieExploitee,
    String? uniteSuperficie,
    String? systemeIrrigation,
    double? productionMois1,
    double? productionMois2,
    double? productionMois3,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        nom: nom,
        prenoms: prenoms,
        telephone: telephone,
        email: email,
        typeProducteur: typeProducteur,
        region: region,
        photo: photo,
        superficieExploitee: superficieExploitee,
        uniteSuperficie: uniteSuperficie,
        systemeIrrigation: systemeIrrigation,
        productionMois1: productionMois1,
        productionMois2: productionMois2,
        productionMois3: productionMois3,
      );
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('Erreur lors de la mise à jour du profil'),
      );
    }
  }
}
