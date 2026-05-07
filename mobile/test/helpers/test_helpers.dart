/// Test helper utilities for AgriSmart CI mobile application
///
/// This file provides common utilities, mocks, and fixtures
/// used across different test files.
library;

import 'package:agriculture/features/auth/domain/entities/user.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

/// Test fixtures for User entity
class TestUsers {
  static User get producteur => const User(
    id: 'user-1',
    nom: 'Koné',
    prenoms: 'Amadou',
    telephone: '+22507000001',
    email: 'amadou@example.com',
    role: 'PRODUCTEUR',
    regionId: 'region-1',
    preferredLanguage: 'fr',
  );

  static User get agronome => const User(
    id: 'user-2',
    nom: 'Diallo',
    prenoms: 'Fatou',
    telephone: '+22507000002',
    email: 'fatou@example.com',
    role: 'AGRONOME',
    regionId: 'region-2',
  );

  static User get admin => const User(
    id: 'user-admin',
    nom: 'Admin',
    prenoms: 'System',
    telephone: '+22500000000',
    email: 'admin@agrismart.ci',
    role: 'ADMIN',
  );

  static User get inactiveUser => const User(
    id: 'user-inactive',
    nom: 'Test',
    prenoms: 'Inactif',
    telephone: '+22507000099',
    role: 'PRODUCTEUR',
  );
}

/// Test fixtures for Parcelle entity
class TestParcelles {
  static Parcelle get active => const Parcelle(
    id: 'parcelle-1',
    nom: 'Parcelle Manioc Nord',
    superficie: 2.5,
    status: 'ACTIVE',
    typeSol: 'argileux',
    cultureLegacy: 'Manioc',
    latitude: 7.539989,
    longitude: -5.547080,
    sante: ParcelleHealth.optimal,
  );

  static Parcelle get enRepos => const Parcelle(
    id: 'parcelle-2',
    nom: 'Parcelle Sud',
    superficie: 1.0,
    status: 'EN_REPOS',
    typeSol: 'sableux',
    cultureLegacy: null,
    sante: ParcelleHealth.surveillance,
  );

  static Parcelle get ensemencee => const Parcelle(
    id: 'parcelle-3',
    nom: 'Parcelle Riz Est',
    superficie: 3.5,
    status: 'ENSEMENCEE',
    typeSol: 'limoneux',
    cultureLegacy: 'Riz',
    sante: ParcelleHealth.optimal,
  );

  static List<Parcelle> get sampleList => [active, enRepos, ensemencee];
}

/// Common test response data for API mocks
class TestResponses {
  static Map<String, dynamic> get loginSuccessResponse => {
    'success': true,
    'data': {
      'user': {
        'id': 'user-1',
        'nom': 'Koné',
        'prenoms': 'Amadou',
        'telephone': '+22507000001',
        'email': 'amadou@example.com',
        'role': 'PRODUCTEUR',
        'statut': 'ACTIF',
      },
      'token': 'test-jwt-token-123',
    },
    'message': 'Connexion réussie',
  };

  static Map<String, dynamic> get loginOtpRequiredResponse => {
    'success': true,
    'data': {'requiresOtp': true, 'identifier': '+22507000001'},
    'message': 'Code OTP envoyé',
  };

  static Map<String, dynamic> get errorResponse => {
    'success': false,
    'message': 'Une erreur est survenue',
    'errors': [],
  };

  static Map<String, dynamic> get parcellesListResponse => {
    'success': true,
    'data': [
      {
        'id': 'parcelle-1',
        'nom': 'Parcelle Test',
        'superficie': 2.5,
        'statut': 'ACTIVE',
        'type_sol': 'argileux',
        'culture_actuelle': 'Manioc',
      },
    ],
    'pagination': {'page': 1, 'limit': 20, 'total': 1},
  };
}

/// Delay helper for testing async operations
Future<void> pump([Duration duration = const Duration(milliseconds: 100)]) {
  return Future.delayed(duration);
}

/// Extension for easier testing
extension StringTestExtension on String {
  /// Vérifie si c'est un UUID valide
  bool get isValidUUID {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(this);
  }

  /// Vérifie si c'est un numéro de téléphone ivoirien valide
  bool get isValidIvorianPhone {
    final phoneRegex = RegExp(r'^\+225[0-9]{10}$');
    return phoneRegex.hasMatch(this);
  }
}
