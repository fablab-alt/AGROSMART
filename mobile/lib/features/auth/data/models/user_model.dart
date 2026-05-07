import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.nom,
    required super.prenoms,
    required super.telephone,
    required super.role,
    super.email,
    super.typeProducteur,
    super.regionId,
    super.regionName,
    super.token,
    super.refreshToken,
    super.parcellesCount,
    super.hectaresTotal,
    super.capteursCount,
    super.adresse,
    super.productionMois1,
    super.productionMois2,
    super.productionMois3,
    super.superficieExploitee,
    super.uniteSuperficie,
    super.systemeIrrigation,
    super.preferredLanguage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      // Backend returns 'prenom' but we use 'prenoms' internally
      prenoms: (json['prenom'] ?? json['prenoms'] ?? '') as String,
      telephone: json['telephone'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      typeProducteur: json['type_producteur'] as String?,
      regionId: json['region_id'] as String?,
      regionName: json['region_name'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      parcellesCount: int.tryParse(json['parcelles_count']?.toString() ?? '0') ?? 0,
      hectaresTotal: double.tryParse(json['hectares_total']?.toString() ?? '0') ?? 0.0,
      capteursCount: int.tryParse(json['capteurs_count']?.toString() ?? '0') ?? 0,
      adresse: json['adresse'] as String?,
      productionMois1: double.tryParse(json['production_mois1_kg']?.toString() ?? '0.0'),
      productionMois2: double.tryParse(json['production_mois2_kg']?.toString() ?? '0.0'),
      productionMois3: double.tryParse(json['production_mois3_kg']?.toString() ?? '0.0'),
      superficieExploitee: double.tryParse(json['superficie_exploitee']?.toString() ?? '0.0'),
      uniteSuperficie: json['unite_superficie'] as String?,
      systemeIrrigation: json['systeme_irrigation'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenoms': prenoms,
      'telephone': telephone,
      'role': role,
      'email': email,
      'type_producteur': typeProducteur,
      'region_id': regionId,
      'region_name': regionName,
      'token': token,
      'refreshToken': refreshToken,
      'parcelles_count': parcellesCount,
      'hectares_total': hectaresTotal,
      'capteurs_count': capteursCount,
      'adresse': adresse,
      'production_mois1_kg': productionMois1,
      'production_mois2_kg': productionMois2,
      'production_mois3_kg': productionMois3,
      'superficie_exploitee': superficieExploitee,
      'unite_superficie': uniteSuperficie,
      'systeme_irrigation': systemeIrrigation,
      'preferred_language': preferredLanguage,
    };
  }
}
