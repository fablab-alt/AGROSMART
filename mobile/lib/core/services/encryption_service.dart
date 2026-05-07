/// Service de chiffrement pour données sensibles
///
/// Utilise FlutterSecureStorage qui gère nativement le chiffrement
/// via le Keychain (iOS) et EncryptedSharedPreferences (Android).
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage sécurisé avec chiffrement natif
///
/// FlutterSecureStorage utilise:
/// - iOS: Keychain Services avec encryption matérielle
/// - Android: EncryptedSharedPreferences (AES-256)
class EncryptionService {
  static const String _keyPrefix = 'encrypted_';

  final FlutterSecureStorage _secureStorage;
  bool _initialized = false;

  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  /// Initialise le service
  Future<void> initialize() async {
    _initialized = true;
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _initialized;

  /// Stocke une chaîne de manière sécurisée
  Future<void> storeSecurely(String key, String value) async {
    _ensureInitialized();
    await _secureStorage.write(key: '$_keyPrefix$key', value: value);
  }

  /// Récupère une chaîne stockée de manière sécurisée
  Future<String?> retrieveSecurely(String key) async {
    _ensureInitialized();
    return await _secureStorage.read(key: '$_keyPrefix$key');
  }

  /// Supprime une valeur stockée
  Future<void> deleteSecurely(String key) async {
    _ensureInitialized();
    await _secureStorage.delete(key: '$_keyPrefix$key');
  }

  /// Stocke des données JSON de manière sécurisée
  Future<void> storeJsonSecurely(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await storeSecurely(key, jsonString);
  }

  /// Récupère des données JSON stockées de manière sécurisée
  Future<Map<String, dynamic>?> retrieveJsonSecurely(String key) async {
    final jsonString = await retrieveSecurely(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Génère un identifiant unique sécurisé
  String generateSecureId({int length = 32}) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes).substring(0, length);
  }

  /// Masque une donnée sensible pour affichage
  ///
  /// Exemple: "1234567890" → "123****890"
  String maskSensitiveData(String data, {int visibleChars = 3}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }

    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final maskLength = data.length - (visibleChars * 2);

    return '$start${'*' * maskLength}$end';
  }

  /// Comparaison sécurisée de chaînes (constant-time)
  /// Protège contre les attaques timing
  bool secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError(
        'EncryptionService not initialized. Call initialize() first.',
      );
    }
  }

  /// Supprime toutes les données chiffrées
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }

  /// Vérifie si une clé existe
  Future<bool> containsKey(String key) async {
    final value = await retrieveSecurely(key);
    return value != null;
  }
}

/// Extension pour faciliter le stockage de données de localisation
extension LocationEncryption on EncryptionService {
  static const String _locationKey = 'user_location';

  /// Stocke les données de localisation de manière sécurisée
  Future<void> storeLocation({
    required double latitude,
    required double longitude,
  }) async {
    await storeJsonSecurely(_locationKey, {
      'lat': latitude,
      'lon': longitude,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Récupère les données de localisation
  Future<({double latitude, double longitude})?> retrieveLocation() async {
    final data = await retrieveJsonSecurely(_locationKey);
    if (data == null) return null;
    return (
      latitude: (data['lat'] as num).toDouble(),
      longitude: (data['lon'] as num).toDouble(),
    );
  }

  /// Supprime les données de localisation
  Future<void> deleteLocation() async {
    await deleteSecurely(_locationKey);
  }
}

/// Extension pour stocker des tokens de manière sécurisée
extension TokenEncryption on EncryptionService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Stocke les tokens d'authentification
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await storeSecurely(_accessTokenKey, accessToken);
    await storeSecurely(_refreshTokenKey, refreshToken);
  }

  /// Récupère le token d'accès
  Future<String?> getAccessToken() async {
    return await retrieveSecurely(_accessTokenKey);
  }

  /// Récupère le token de refresh
  Future<String?> getRefreshToken() async {
    return await retrieveSecurely(_refreshTokenKey);
  }

  /// Supprime tous les tokens
  Future<void> clearTokens() async {
    await deleteSecurely(_accessTokenKey);
    await deleteSecurely(_refreshTokenKey);
  }
}
