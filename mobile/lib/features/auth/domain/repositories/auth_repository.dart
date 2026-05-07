import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String identifier, String password);
  Future<Either<Failure, User>> verifyOtp(String identifier, String code);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, User>> register({
    required String nom,
    required String prenoms,
    required String telephone,
    required String password,
    String? email,
    String? adresse,
    String languePreferee,
    String role, // 'ACHETEUR' ou 'PRODUCTEUR'
    String? typeProducteur,
    String? production3Mois,
    String? superficie,
    String? uniteSuperficie,
    String? systemeIrrigation,
    String? productionMois1,
    String? productionMois2,
    String? productionMois3,
    List<Map<String, dynamic>>? productions,
  });
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
  });
}
