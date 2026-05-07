import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nom;
  final String prenoms;
  final String telephone;
  final String role;
  final String? email;
  final String? typeProducteur;
  final String? regionId; // UUID from backend
  final String? regionName; // Name from backend join
  final int parcellesCount;
  final double hectaresTotal;
  final int capteursCount;
  final String? token;
  final String? refreshToken;
  final String? adresse;
  final double? productionMois1;
  final double? productionMois2;
  final double? productionMois3;
  final double? superficieExploitee;
  final String? uniteSuperficie;
  final String? systemeIrrigation;
  final String? preferredLanguage;
  final int points;
  final String? level;
  final String? badge;

  const User({
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.role,
    this.email,
    this.typeProducteur,
    this.regionId,
    this.regionName,
    this.token,
    this.refreshToken,
    this.parcellesCount = 0,
    this.hectaresTotal = 0.0,
    this.capteursCount = 0,
    this.adresse,
    this.productionMois1,
    this.productionMois2,
    this.productionMois3,
    this.superficieExploitee,
    this.uniteSuperficie,
    this.systemeIrrigation,
    this.preferredLanguage,
    this.points = 0,
    this.level = 'Novice',
    this.badge,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        prenoms,
        telephone,
        role,
        email,
        typeProducteur,
        regionId,
        regionName,
        token,
        refreshToken,
        parcellesCount,
        hectaresTotal,
        capteursCount,
        adresse,
        productionMois1,
        productionMois2,
        productionMois3,
        superficieExploitee,
        uniteSuperficie,
        systemeIrrigation,
        preferredLanguage,
        points,
        level,
        badge,
      ];
}
