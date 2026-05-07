import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class Register implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  Register(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await repository.register(
      nom: params.nom,
      prenoms: params.prenoms,
      telephone: params.telephone,
      password: params.password,
      email: params.email,
      adresse: params.adresse,
      languePreferee: params.languePreferee,
      role: params.role,
      typeProducteur: params.typeProducteur,
      production3Mois: params.production3Mois,
      superficie: params.superficie,
      uniteSuperficie: params.uniteSuperficie,
      systemeIrrigation: params.systemeIrrigation,
      productionMois1: params.productionMois1,
      productionMois2: params.productionMois2,
      productionMois3: params.productionMois3,
      productions: params.productions,
    );
  }
}

class RegisterParams extends Equatable {
  final String nom;
  final String prenoms;
  final String telephone;
  final String password;
  final String? email;
  final String? adresse;
  final String languePreferee;
  final String role; // 'ACHETEUR' ou 'PRODUCTEUR'
  final String? typeProducteur;
  final String? production3Mois;
  final String? superficie;
  final String? uniteSuperficie;
  final String? systemeIrrigation;
  final String? productionMois1;
  final String? productionMois2;
  final String? productionMois3;
  final List<Map<String, dynamic>>? productions;

  const RegisterParams({
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.password,
    this.email,
    this.adresse,
    this.languePreferee = 'fr',
    this.role = 'PRODUCTEUR',
    this.typeProducteur,
    this.production3Mois,
    this.superficie,
    this.uniteSuperficie,
    this.systemeIrrigation,
    this.productionMois1,
    this.productionMois2,
    this.productionMois3,
    this.productions,
  });

  @override
  List<Object?> get props => [
    nom,
    prenoms,
    telephone,
    password,
    email,
    adresse,
    languePreferee,
    role,
    typeProducteur,
    production3Mois,
    superficie,
    uniteSuperficie,
    systemeIrrigation,
    productionMois1,
    productionMois2,
    productionMois3,
    productions,
  ];
}
