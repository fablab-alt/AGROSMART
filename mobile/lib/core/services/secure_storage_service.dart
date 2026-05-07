/// Service de stockage sécurisé pour les données sensibles
///
/// Utilise FlutterSecureStorage pour stocker les tokens et autres données sensibles
/// de manière chiffrée sur l'appareil.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // Clés de stockage
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserData = 'user_data';

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  // ============================================
  // Token Management
  // ============================================

  /// Sauvegarde le token d'accès
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  /// Récupère le token d'accès
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Sauvegarde le refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Récupère le refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Sauvegarde les deux tokens en une fois
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Supprime tous les tokens (déconnexion)
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Vérifie si un token d'accès existe
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ============================================
  // User Data
  // ============================================

  /// Sauvegarde l'ID utilisateur
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Récupère l'ID utilisateur
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Sauvegarde les données utilisateur (JSON string)
  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _keyUserData, value: userData);
  }

  /// Récupère les données utilisateur
  Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  // ============================================
  // Generic Storage
  // ============================================

  /// Sauvegarde une valeur avec une clé personnalisée
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lit une valeur avec une clé personnalisée
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Supprime une valeur
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Vérifie si une clé existe
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Efface tout le stockage sécurisé (déconnexion complète)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Récupère toutes les clés stockées
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
