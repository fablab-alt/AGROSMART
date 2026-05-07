import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfile {
  final AuthRepository repository;

  UpdateProfile(this.repository);

  Future<Either<Failure, User>> call({
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
    return await repository.updateProfile(
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
  }
}
