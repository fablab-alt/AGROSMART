/// Service de langues locales ivoiriennes
/// AgroSmart - Application Mobile
///
/// Support des langues:
/// - Français (par défaut)
/// - Baoulé (bci)
/// - Dioula/Malinké (dyu)
/// - Sénoufo (sef)
///
/// Note: Les langues locales utilisent des fichiers audio pré-enregistrés
/// car les moteurs TTS standard ne les supportent pas.
library;

import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langues supportées
enum LocalLanguage {
  french('fr', 'Français', true),
  baoule('bci', 'Baoulé', false),
  dioula('dyu', 'Dioula/Malinké', false),
  senoufo('sef', 'Sénoufo', false);

  final String code;
  final String displayName;
  final bool hasTTSSupport;

  const LocalLanguage(this.code, this.displayName, this.hasTTSSupport);

  static LocalLanguage fromCode(String code) {
    return LocalLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => LocalLanguage.french,
    );
  }
}

/// Catégories de phrases audio
enum AudioCategory {
  greetings('greetings'),
  alerts('alerts'),
  weather('weather'),
  parcelles('parcelles'),
  diagnostics('diagnostics'),
  marketplace('marketplace'),
  navigation('navigation'),
  common('common');

  final String folder;
  const AudioCategory(this.folder);
}

/// Service de gestion des langues locales
class LocalLanguageService {
  static final LocalLanguageService _instance =
      LocalLanguageService._internal();
  factory LocalLanguageService() => _instance;
  LocalLanguageService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  LocalLanguage _currentLanguage = LocalLanguage.french;
  bool _isInitialized = false;
  final Map<String, Map<String, String>> _translations = {};

  /// Langue actuelle
  LocalLanguage get currentLanguage => _currentLanguage;

  /// Code de langue actuel
  String get languageCode => _currentLanguage.code;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Charger la langue sauvegardée
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('app_language') ?? 'fr';
    _currentLanguage = LocalLanguage.fromCode(savedCode);

    // Charger les traductions
    await _loadTranslations();

    _isInitialized = true;
    developer.log(
      '[LocalLanguage] Initialized with language: ${_currentLanguage.displayName}',
      name: 'Language',
    );
  }

  /// Change la langue de l'application
  Future<void> setLanguage(LocalLanguage language) async {
    _currentLanguage = language;

    // Sauvegarder le choix
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.code);

    developer.log(
      '[LocalLanguage] Language changed to: ${language.displayName}',
      name: 'Language',
    );
  }

  /// Charge les traductions depuis les fichiers JSON
  Future<void> _loadTranslations() async {
    for (final lang in LocalLanguage.values) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/${lang.code}.json',
        );
        // Parse JSON manually to avoid dart:convert issues
        _translations[lang.code] = _parseSimpleJson(jsonString);
      } catch (e) {
        developer.log(
          '[LocalLanguage] Failed to load translations for ${lang.code}: $e',
          name: 'Language',
        );
        _translations[lang.code] = {};
      }
    }
  }

  /// Parse simple JSON (clé: valeur strings uniquement)
  Map<String, String> _parseSimpleJson(String jsonString) {
    final result = <String, String>{};
    // Simplistic parsing - in production use dart:convert
    final lines = jsonString.split('\n');
    for (final line in lines) {
      final match = RegExp(r'"(\w+)":\s*"([^"]*)"').firstMatch(line);
      if (match != null) {
        result[match.group(1)!] = match.group(2)!;
      }
    }
    return result;
  }

  /// Traduit une clé
  String translate(String key, {Map<String, String>? params}) {
    final langTranslations = _translations[_currentLanguage.code] ?? {};
    String text = langTranslations[key] ?? _translations['fr']?[key] ?? key;

    // Remplacer les paramètres
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }

    return text;
  }

  /// Alias court pour translate
  String t(String key, {Map<String, String>? params}) =>
      translate(key, params: params);

  /// Joue un fichier audio pour une phrase donnée
  Future<void> playAudio(String phraseKey, {AudioCategory? category}) async {
    if (_currentLanguage.hasTTSSupport) {
      // Utiliser TTS pour le français
      developer.log(
        '[LocalLanguage] TTS would speak: ${translate(phraseKey)}',
        name: 'Language',
      );
      return;
    }

    // Pour les langues locales, utiliser les fichiers audio
    final cat = category ?? AudioCategory.common;
    final audioPath =
        'assets/audio/${_currentLanguage.code}/${cat.folder}/$phraseKey.mp3';

    try {
      // Vérifier si le fichier existe
      final exists = await _audioExists(audioPath);
      if (!exists) {
        developer.log(
          '[LocalLanguage] Audio file not found: $audioPath',
          name: 'Language',
        );
        return;
      }

      await _audioPlayer.play(
        AssetSource(
          'audio/${_currentLanguage.code}/${cat.folder}/$phraseKey.mp3',
        ),
      );

      developer.log(
        '[LocalLanguage] Playing audio: $audioPath',
        name: 'Language',
      );
    } catch (e) {
      developer.log(
        '[LocalLanguage] Failed to play audio: $e',
        name: 'Language',
      );
    }
  }

  /// Vérifie si un fichier audio existe
  Future<bool> _audioExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Arrête la lecture audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  /// Joue une salutation selon l'heure
  Future<void> playGreeting() async {
    final hour = DateTime.now().hour;
    String greetingKey;

    if (hour < 12) {
      greetingKey = 'good_morning';
    } else if (hour < 18) {
      greetingKey = 'good_afternoon';
    } else {
      greetingKey = 'good_evening';
    }

    await playAudio(greetingKey, category: AudioCategory.greetings);
  }

  /// Joue une alerte vocale
  Future<void> playAlert(AlertType type) async {
    final alertKey = type.audioKey;
    await playAudio(alertKey, category: AudioCategory.alerts);
  }

  /// Dispose le service
  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Types d'alertes avec leurs clés audio
enum AlertType {
  critical('alert_critical'),
  warning('alert_warning'),
  info('alert_info'),
  disease('alert_disease'),
  irrigation('alert_irrigation'),
  weather('alert_weather');

  final String audioKey;
  const AlertType(this.audioKey);
}

/// Phrases communes prédéfinies
class LocalPhrases {
  static const String welcomeBack = 'welcome_back';
  static const String goodMorning = 'good_morning';
  static const String goodAfternoon = 'good_afternoon';
  static const String goodEvening = 'good_evening';

  // Alertes
  static const String alertCritical = 'alert_critical';
  static const String alertWarning = 'alert_warning';
  static const String diseaseDetected = 'disease_detected';
  static const String irrigationNeeded = 'irrigation_needed';
  static const String weatherAlert = 'weather_alert';

  // Navigation
  static const String goToHome = 'go_to_home';
  static const String goToParcelles = 'go_to_parcelles';
  static const String goToMarketplace = 'go_to_marketplace';
  static const String goToProfile = 'go_to_profile';

  // Météo
  static const String weatherSunny = 'weather_sunny';
  static const String weatherRainy = 'weather_rainy';
  static const String weatherCloudy = 'weather_cloudy';
  static const String weatherHot = 'weather_hot';

  // Parcelles
  static const String parcelleHealthy = 'parcelle_healthy';
  static const String parcelleWarning = 'parcelle_warning';
  static const String parcelleCritical = 'parcelle_critical';

  // Commandes
  static const String yes = 'yes';
  static const String no = 'no';
  static const String confirm = 'confirm';
  static const String cancel = 'cancel';
  static const String back = 'back';
  static const String next = 'next';
}
