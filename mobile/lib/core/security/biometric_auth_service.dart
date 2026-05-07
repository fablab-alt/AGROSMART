import 'dart:developer' as developer;
import 'package:local_auth/local_auth.dart';
import '../config/environment_config.dart';

/// Service pour gérer l'authentification biométrique (Face ID, Touch ID, empreinte digitale)
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  void _log(String message) {
    if (EnvironmentConfig.isDevelopment) {
      developer.log(message, name: 'BiometricAuthService');
    }
  }

  /// Vérifie si l'appareil supporte l'authentification biométrique
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _log('Error checking biometric availability - $e');
      return false;
    }
  }

  /// Récupère la liste des types biométriques disponibles
  /// Ex: [BiometricType.face, BiometricType.fingerprint]
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _log('Error getting available biometrics - $e');
      return [];
    }
  }

  /// Authentifie l'utilisateur avec la biométrie
  ///
  /// [localizedReason] : Raison affichée à l'utilisateur (iOS uniquement)
  /// [useErrorDialogs] : Afficher les dialogues d'erreur système
  /// [stickyAuth] : Garder l'authentification active pendant l'exécution
  /// [sensitiveTransaction] : Pour transactions sensibles (plus strict)
  ///
  /// Retourne true si l'authentification réussit
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Veuillez vous authentifier pour continuer',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      // Vérifier la disponibilité
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          errorMessage: 'Authentification biométrique non disponible',
        );
      }

      // Tenter l'authentification
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: true, // Force biometric only (no PIN fallback)
        ),
      );

      if (authenticated) {
        return BiometricAuthResult(
          success: true,
          errorType: null,
          errorMessage: null,
        );
      } else {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.authenticationFailed,
          errorMessage: 'Authentification échouée',
        );
      }
    } catch (e) {
      _log('Authentication error - $e');

      // Analyser le type d'erreur
      BiometricErrorType errorType;
      String errorMessage;

      if (e.toString().contains('PermanentlyLockedOut')) {
        errorType = BiometricErrorType.permanentlyLocked;
        errorMessage = 'Trop de tentatives. Utilisez votre code PIN.';
      } else if (e.toString().contains('LockedOut')) {
        errorType = BiometricErrorType.temporarilyLocked;
        errorMessage = 'Temporairement bloqué. Réessayez plus tard.';
      } else if (e.toString().contains('NotEnrolled') ||
          e.toString().contains('PasscodeNotSet')) {
        errorType = BiometricErrorType.notEnrolled;
        errorMessage = 'Aucune biométrie configurée sur cet appareil';
      } else if (e.toString().contains('UserCancel')) {
        errorType = BiometricErrorType.userCanceled;
        errorMessage = 'Authentification annulée par l\'utilisateur';
      } else {
        errorType = BiometricErrorType.unknown;
        errorMessage = 'Erreur lors de l\'authentification biométrique';
      }

      return BiometricAuthResult(
        success: false,
        errorType: errorType,
        errorMessage: errorMessage,
      );
    }
  }

  /// Authentification simplifiée pour connexion rapide
  Future<bool> authenticateForLogin() async {
    final result = await authenticate(
      localizedReason: 'Authentifiez-vous pour vous connecter à AgroSmart',
      useErrorDialogs: true,
      stickyAuth: true,
      sensitiveTransaction: false,
    );
    return result.success;
  }

  /// Authentification renforcée pour transactions sensibles
  /// (paiements, modifications de données critiques)
  Future<bool> authenticateForTransaction() async {
    final result = await authenticate(
      localizedReason: 'Confirmez cette transaction',
      useErrorDialogs: true,
      stickyAuth: true,
      sensitiveTransaction: true,
    );
    return result.success;
  }

  /// Arrête l'authentification en cours (si sticky)
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e) {
      _log('Error stopping authentication - $e');
      return false;
    }
  }

  /// Obtient une description conviviale du type biométrique
  String getBiometricTypeDescription(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Reconnaissance faciale';
      case BiometricType.fingerprint:
        return 'Empreinte digitale';
      case BiometricType.iris:
        return 'Reconnaissance iris';
      case BiometricType.strong:
        return 'Biométrie forte';
      case BiometricType.weak:
        return 'Biométrie faible';
    }
  }
}

/// Résultat d'une tentative d'authentification biométrique
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'BiometricAuthResult(success: true)';
    }
    return 'BiometricAuthResult(success: false, errorType: $errorType, errorMessage: $errorMessage)';
  }
}

/// Types d'erreur possibles lors de l'authentification biométrique
enum BiometricErrorType {
  /// Biométrie non disponible sur cet appareil
  notAvailable,

  /// Aucune biométrie configurée
  notEnrolled,

  /// Authentification échouée (biométrie non reconnue)
  authenticationFailed,

  /// Utilisateur a annulé l'authentification
  userCanceled,

  /// Temporairement bloqué (trop de tentatives)
  temporarilyLocked,

  /// Définitivement bloqué (nécessite code PIN)
  permanentlyLocked,

  /// Erreur inconnue
  unknown,
}
