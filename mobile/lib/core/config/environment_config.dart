/// Configuration de l'environnement pour l'application AgroSmart
///
/// Ce fichier centralise toutes les configurations environnementales
/// pour supporter les environnements de développement, staging et production.
library;

enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static Environment get currentEnvironment => _currentEnvironment;

  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
  }

  static void initFromDartDefine() {
    switch (_appEnv.toLowerCase()) {
      case 'production':
      case 'prod':
        _currentEnvironment = Environment.production;
        break;
      case 'staging':
      case 'stage':
        _currentEnvironment = Environment.staging;
        break;
      default:
        _currentEnvironment = Environment.development;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  CONFIGURATION DE TEST LOCAL — à adapter selon votre appareil
  // ═══════════════════════════════════════════════════════════════
  //
  //  Émulateur Android        → '10.0.2.2'
  //  Simulateur iOS           → '127.0.0.1'
  //  Appareil physique (USB/WiFi) → IP locale de votre Mac
  //                               (ex: 192.168.50.40)
  //
  //  Commande pour connaître votre IP : ifconfig | grep 'inet 192'
  // ═══════════════════════════════════════════════════════════════
  static const String _devHost = String.fromEnvironment(
    'DEV_HOST',
    defaultValue: '10.0.2.2', // Émulateur Android -> localhost machine hôte
  );
  static const int _devPort = int.fromEnvironment(
    'DEV_PORT',
    defaultValue: 3600,
  );

  /// URL de base de l'API selon l'environnement
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://$_devHost:$_devPort/api/v1';
      case Environment.staging:
        return 'https://staging-api.agrosmart.ci/api/v1';
      case Environment.production:
        return 'https://api.agrosmart.voisilab.online/api/v1';
    }
  }

  /// URL WebSocket selon l'environnement
  static String get wsBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'ws://$_devHost:$_devPort';
      case Environment.staging:
        return 'wss://staging-api.agrosmart.ci';
      case Environment.production:
        return 'wss://api.agrosmart.voisilab.online';
    }
  }

  /// Base backend origin without API version path, used for static assets URLs.
  static String get backendOrigin {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'http://$_devHost:$_devPort';
      case Environment.staging:
        return 'https://staging-api.agrosmart.ci';
      case Environment.production:
        return 'https://api.agrosmart.voisilab.online';
    }
  }

  /// Activer les logs de debug
  static bool get enableDebugLogs {
    return _currentEnvironment == Environment.development;
  }

  /// Activer les logs réseau
  static bool get enableNetworkLogs {
    return _currentEnvironment != Environment.production;
  }

  /// Timeout de connexion (secondes)
  static int get connectionTimeout {
    switch (_currentEnvironment) {
      case Environment.development:
        return 30;
      case Environment.staging:
        return 15;
      case Environment.production:
        return 10;
    }
  }

  /// Timeout de réception (secondes)
  static int get receiveTimeout {
    switch (_currentEnvironment) {
      case Environment.development:
        return 30;
      case Environment.staging:
        return 15;
      case Environment.production:
        return 10;
    }
  }

  /// Activer le certificate pinning (production uniquement)
  static bool get enableCertificatePinning {
    return _currentEnvironment == Environment.production;
  }

  /// SHA256 des certificats pour le pinning
  static List<String> get certificateSha256Fingerprints {
    return [
      // À remplacer par les vrais fingerprints du certificat SSL de production
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    ];
  }

  /// Nom de l'environnement pour l'affichage
  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Développement';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Indique si c'est un environnement de développement
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;

  /// Indique si c'est un environnement de production
  static bool get isProduction => _currentEnvironment == Environment.production;
}
