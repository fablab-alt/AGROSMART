import 'dart:io';

import 'package:dio/dio.dart';
import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/core/config/environment_config.dart';

/// Service centralisé pour la gestion des erreurs
///
/// Fournit des méthodes pour :
/// - Convertir les exceptions en Failures typées
/// - Générer des messages d'erreur utilisateur-friendly
/// - Logger les erreurs de manière sécurisée
class ErrorHandler {
  /// Convertit une exception en Failure typée
  static Failure handleException(dynamic exception, {String? context}) {
    if (EnvironmentConfig.enableDebugLogs) {
      // ignore: avoid_print
      print('[ErrorHandler] Exception: $exception (context: $context)');
    }

    if (exception is DioException) {
      return _handleDioException(exception);
    }

    if (exception is SocketException) {
      return const NetworkFailure('Pas de connexion internet');
    }

    if (exception is FormatException) {
      return ServerFailure('Données invalides reçues du serveur');
    }

    if (exception is TypeError) {
      return ServerFailure('Erreur de format de données');
    }

    if (exception is Failure) {
      return exception;
    }

    // Fallback générique
    return ServerFailure(_sanitizeErrorMessage(exception.toString()));
  }

  /// Gère les erreurs Dio (HTTP)
  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Délai de connexion dépassé');

      case DioExceptionType.connectionError:
        return const NetworkFailure('Impossible de se connecter au serveur');

      case DioExceptionType.badResponse:
        return _handleHttpError(exception.response);

      case DioExceptionType.cancel:
        return const ServerFailure('Requête annulée');

      default:
        return NetworkFailure(
          'Erreur réseau: ${_sanitizeErrorMessage(exception.message ?? 'Inconnue')}',
        );
    }
  }

  /// Gère les erreurs HTTP par code de statut
  static Failure _handleHttpError(Response? response) {
    if (response == null) {
      return const ServerFailure('Aucune réponse du serveur');
    }

    final statusCode = response.statusCode ?? 0;
    final message = _extractErrorMessage(response.data);

    switch (statusCode) {
      case 400:
        return ServerFailure(message ?? 'Requête invalide');
      case 401:
        return const AuthFailure('Session expirée, veuillez vous reconnecter');
      case 403:
        return const AuthFailure('Accès non autorisé');
      case 404:
        return ServerFailure(message ?? 'Ressource non trouvée');
      case 409:
        return ServerFailure(message ?? 'Conflit de données');
      case 422:
        return ServerFailure(message ?? 'Données de validation invalides');
      case 429:
        return const ServerFailure('Trop de requêtes, veuillez patienter');
      case 500:
        return const ServerFailure('Erreur interne du serveur');
      case 502:
      case 503:
      case 504:
        return const ServerFailure('Service temporairement indisponible');
      default:
        return ServerFailure(message ?? 'Erreur HTTP $statusCode');
    }
  }

  /// Extrait le message d'erreur de la réponse API
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Essayer différentes clés courantes
      return data['message'] as String? ??
          data['error'] as String? ??
          data['msg'] as String? ??
          (data['errors'] as List?)?.first?.toString();
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return null;
  }

  /// Nettoie le message d'erreur pour l'affichage utilisateur
  static String _sanitizeErrorMessage(String message) {
    // Supprimer les informations techniques sensibles
    if (message.contains('Exception:')) {
      message = message.replaceAll(RegExp(r'Exception:\s*'), '');
    }

    // Limiter la longueur
    if (message.length > 200) {
      message = '${message.substring(0, 197)}...';
    }

    // Message par défaut si vide
    if (message.trim().isEmpty) {
      return 'Une erreur inattendue s\'est produite';
    }

    return message;
  }

  /// Génère un message utilisateur-friendly à partir d'une Failure
  static String getUserMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Vérifiez votre connexion internet';
    }

    if (failure is AuthFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Problème d\'authentification';
    }

    if (failure is CacheFailure) {
      return 'Erreur de cache local';
    }

    return failure.message.isNotEmpty
        ? failure.message
        : 'Une erreur s\'est produite';
  }

  /// Log une erreur de manière sécurisée
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    if (!EnvironmentConfig.enableDebugLogs) return;

    final sanitizedError = _sanitizeErrorMessage(error.toString());
    // ignore: avoid_print
    print('[ERROR] ${context ?? 'Unknown'}: $sanitizedError');

    if (stackTrace != null &&
        EnvironmentConfig.currentEnvironment == Environment.development) {
      // ignore: avoid_print
      print('[STACK] $stackTrace');
    }
  }
}

/// Extension pour faciliter l'utilisation
extension ExceptionHandling on Object {
  Failure toFailure({String? context}) {
    return ErrorHandler.handleException(this, context: context);
  }
}
