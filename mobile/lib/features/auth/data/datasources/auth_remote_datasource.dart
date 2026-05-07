import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../models/user_model.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/config/environment_config.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String identifier, String password);
  Future<UserModel> verifyOtp(String identifier, String code);
  Future<UserModel> getMe();
  Future<UserModel> register({
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
  Future<UserModel> updateProfile({
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

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final SecureStorageService _secureStorage;

  // Helper pour les logs conditionnels (seulement en dev)
  void _log(String message) {
    if (EnvironmentConfig.enableDebugLogs) {
      debugPrint(message);
    }
  }

  AuthRemoteDataSourceImpl({
    required this.dio,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<UserModel> login(String identifier, String password) async {
    try {
      _log('[AUTH] Tentative de connexion');

      final response = await dio.post(
        '/auth/login',
        data: {'identifier': identifier, 'password': password},
      );

      _log('[AUTH] Response status: ${response.statusCode}');

      final data = response.data['data'];

      // Sauvegarde sécurisée du token (support accessToken et token pour rétrocompatibilité)
      final accessToken = data['accessToken'] ?? data['token'];
      if (accessToken != null) {
        _log('[AUTH] Token reçu, sauvegarde sécurisée');
        await _secureStorage.saveAccessToken(accessToken);
      }

      // Sauvegarde du refresh token s'il existe
      if (data['refreshToken'] != null) {
        await _secureStorage.saveRefreshToken(data['refreshToken']);
      }

      UserModel user = UserModel.fromJson(data['user']);

      try {
        final enrichedUser = await getMe();
        user = UserModel.fromJson({...user.toJson(), ...enrichedUser.toJson()});
        _log('[AUTH] Profil enrichi via /auth/me');
      } catch (e) {
        _log('[AUTH] Impossible de récupérer /auth/me après login: $e');
      }

      _log('[AUTH] Connexion réussie');

      // Sauvegarder les données utilisateur pour la restauration de session
      await _secureStorage.saveUserData(user.toJson().toString());
      if (user.id.isNotEmpty) {
        await _secureStorage.saveUserId(user.id);
      }

      return user;
    } on DioException catch (e) {
      _log('[AUTH ERROR] DioException: ${e.message}');
      final message = _extractErrorMessage(e);
      throw ServerFailure(message);
    } catch (e, stackTrace) {
      _log('[AUTH ERROR] Exception inattendue: $e');
      _log('[AUTH ERROR] StackTrace: $stackTrace');
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> verifyOtp(String identifier, String code) async {
    try {
      final response = await dio.post(
        '/auth/verify-otp',
        data: {'identifier': identifier, 'otp': code},
      );
      final data = response.data['data'];

      // Sauvegarde sécurisée du token (support accessToken et token pour rétrocompatibilité)
      final accessToken = data['accessToken'] ?? data['token'];
      if (accessToken != null) {
        _log('[AUTH] OTP vérifié, sauvegarde du token');
        await _secureStorage.saveAccessToken(accessToken);
      }

      // Sauvegarde du refresh token s'il existe
      if (data['refreshToken'] != null) {
        await _secureStorage.saveRefreshToken(data['refreshToken']);
      }

      UserModel user = UserModel.fromJson(data['user']);

      // Enrichir le profil utilisateur
      try {
        final enrichedUser = await getMe();
        user = UserModel.fromJson({...user.toJson(), ...enrichedUser.toJson()});
        _log('[AUTH] Profil enrichi via /auth/me après OTP');
      } catch (e) {
        _log('[AUTH] Impossible de récupérer /auth/me après OTP: $e');
      }

      // Sauvegarder les données utilisateur
      await _secureStorage.saveUserData(user.toJson().toString());
      if (user.id.isNotEmpty) {
        await _secureStorage.saveUserId(user.id);
      }

      return user;
    } on DioException catch (e) {
      _log('[AUTH ERROR] verifyOtp DioException: ${e.message}');
      final message = _extractErrorMessage(e);
      throw ServerFailure(message);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      _log('[AUTH ERROR] verifyOtp Exception: $e');
      throw ServerFailure(
        'Erreur lors de la vérification OTP: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw const ServerFailure('Pas de token disponible');
      }

      _log('[AUTH] Appel GET /auth/me');

      // L'intercepteur Dio ajoute déjà le header Authorization automatiquement
      final response = await dio.get('/auth/me');

      _log('[AUTH] getMe response: ${response.statusCode}');

      final data = response.data['data'];
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      _log('[AUTH ERROR] getMe DioException: ${e.message}');
      final message = _extractErrorMessage(e);
      throw ServerFailure(message);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      _log('[AUTH ERROR] getMe Exception: $e');
      throw ServerFailure(
        'Erreur lors de la récupération du profil: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserModel> register({
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
      final response = await dio.post(
        '/auth/register',
        data: {
          'nom': nom,
          'prenoms': prenoms,
          'telephone': telephone,
          'password': password,
          'role': role, // Envoyer le rôle au backend
          if (email != null && email.isNotEmpty) 'email': email,
          if (adresse != null && adresse.isNotEmpty) 'adresse': adresse,
          'langue_preferee': languePreferee,
          if (typeProducteur != null) 'type_producteur': typeProducteur,
          if (production3Mois != null)
            'production_3_mois_precedents_kg': production3Mois,
          if (superficie != null) 'superficie_exploitee': superficie,
          if (uniteSuperficie != null) 'unite_superficie': uniteSuperficie,
          if (systemeIrrigation != null)
            'systeme_irrigation': systemeIrrigation,
          if (productionMois1 != null) 'production_mois1_kg': productionMois1,
          if (productionMois2 != null) 'production_mois2_kg': productionMois2,
          if (productionMois3 != null) 'production_mois3_kg': productionMois3,
          if (productions != null) 'productions': productions,
        },
      );

      final data = response.data['data'];

      // Sauvegarde sécurisée du token (support accessToken et token pour rétrocompatibilité)
      final accessToken = data['accessToken'] ?? data['token'];
      if (accessToken != null) {
        _log('[AUTH] Inscription réussie, sauvegarde du token');
        await _secureStorage.saveAccessToken(accessToken);
      }

      // Sauvegarde du refresh token s'il existe
      if (data['refreshToken'] != null) {
        await _secureStorage.saveRefreshToken(data['refreshToken']);
      }

      UserModel user = UserModel.fromJson(data['user']);

      // Enrichir le profil utilisateur
      try {
        final enrichedUser = await getMe();
        user = UserModel.fromJson({...user.toJson(), ...enrichedUser.toJson()});
        _log('[AUTH] Profil enrichi via /auth/me après inscription');
      } catch (e) {
        _log('[AUTH] Impossible de récupérer /auth/me après inscription: $e');
      }

      // Sauvegarder les données utilisateur
      await _secureStorage.saveUserData(user.toJson().toString());
      if (user.id.isNotEmpty) {
        await _secureStorage.saveUserId(user.id);
      }

      return user;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ServerFailure(message);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      _log('[AUTH ERROR] register Exception: $e');
      throw ServerFailure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
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
      final token = await _getToken();

      final Map<String, dynamic> dataMap = {
        'nom': nom,
        'prenoms': prenoms,
        'telephone': telephone,
        if (typeProducteur != null) 'type_producteur': typeProducteur,
        if (region != null) 'region': region,
        if (email != null) 'email': email,
        if (superficieExploitee != null)
          'superficie_exploitee': superficieExploitee,
        if (uniteSuperficie != null) 'unite_superficie': uniteSuperficie,
        if (systemeIrrigation != null) 'systeme_irrigation': systemeIrrigation,
        if (productionMois1 != null) 'production_mois1_kg': productionMois1,
        if (productionMois2 != null) 'production_mois2_kg': productionMois2,
        if (productionMois3 != null) 'production_mois3_kg': productionMois3,
      };

      FormData formData;
      if (photo != null) {
        formData = FormData.fromMap({
          ...dataMap,
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.path.split('/').last,
          ),
        });
      } else {
        formData = FormData.fromMap(dataMap);
      }

      final response = await dio.put(
        '/auth/me',
        data: formData, // Use formData
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Dio handles Content-Type for FormData automatically
          },
        ),
      );

      final data = response.data['data'];
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ServerFailure(message);
    }
  }

  Future<String?> _getToken() async {
    return await _secureStorage.getAccessToken();
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      // Check for specific error messages
      if (data['message'] != null) {
        final msg = data['message'].toString();
        // Handle duplicate user
        if (msg.contains('existe déjà')) {
          return 'Ce numéro de téléphone ou email est déjà utilisé';
        }
        // Handle validation errors with details
        if (data['errors'] != null && data['errors'] is List) {
          final errors = data['errors'] as List;
          final messages = errors
              .map((e) => e['message']?.toString() ?? '')
              .where((m) => m.isNotEmpty)
              .join('\n');
          if (messages.isNotEmpty) return messages;
        }
        return msg;
      }
    }
    return 'Erreur de connexion au serveur';
  }
}
