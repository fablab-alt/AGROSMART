import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agriculture/core/network/api_client.dart';

/// Langues locales supportées
enum LocalLanguage { francais, baoule, dioula, senoufo, bete, gouro, attie }

extension LocalLanguageExtension on LocalLanguage {
  String get code {
    switch (this) {
      case LocalLanguage.francais:
        return 'fr';
      case LocalLanguage.baoule:
        return 'bci'; // ISO 639-3 for Baoulé
      case LocalLanguage.dioula:
        return 'dyu'; // ISO 639-3 for Dioula
      case LocalLanguage.senoufo:
        return 'sev'; // ISO 639-3 for Sénoufo
      case LocalLanguage.bete:
        return 'bev'; // ISO 639-3 for Bété
      case LocalLanguage.gouro:
        return 'goa'; // ISO 639-3 for Gouro
      case LocalLanguage.attie:
        return 'ati'; // ISO 639-3 for Attié
    }
  }

  String get displayName {
    switch (this) {
      case LocalLanguage.francais:
        return 'Français';
      case LocalLanguage.baoule:
        return 'Baoulé';
      case LocalLanguage.dioula:
        return 'Dioula';
      case LocalLanguage.senoufo:
        return 'Sénoufo';
      case LocalLanguage.bete:
        return 'Bété';
      case LocalLanguage.gouro:
        return 'Gouro';
      case LocalLanguage.attie:
        return 'Attié';
    }
  }

  String get greeting {
    switch (this) {
      case LocalLanguage.francais:
        return 'Bonjour! Comment puis-je vous aider?';
      case LocalLanguage.baoule:
        return 'Aló! Ɔ sɛ man a?'; // Baoulé greeting
      case LocalLanguage.dioula:
        return 'I ni sogoma! N bɛ se ka i dɛmɛ cogo di?'; // Dioula greeting
      case LocalLanguage.senoufo:
        return 'Wali! N kɔ ye i deme?'; // Sénoufo greeting
      case LocalLanguage.bete:
        return 'Ɛjuó! Ɔ jue di?'; // Bété greeting
      case LocalLanguage.gouro:
        return 'Wun! Mi nyan bɔ i?'; // Gouro greeting
      case LocalLanguage.attie:
        return 'Abodè! Ɔ suan mi?'; // Attié greeting
    }
  }
}

/// Message du chatbot
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioUrl;
  final LocalLanguage language;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.audioUrl,
    this.language = LocalLanguage.francais,
  });
}

/// Service de chatbot vocal multilingue agricole
class AgriChatbotService {
  final ApiClient _apiClient;
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  LocalLanguage _currentLanguage = LocalLanguage.francais;
  bool _isSpeechInitialized = false;
  bool _isSpeaking = false;

  final List<ChatMessage> _conversationHistory = [];

  // Phrases pré-enregistrées pour les langues locales (cache local)
  final Map<String, Map<String, String>> _localPhrases = {
    'bci': {
      // Baoulé
      'bonjour': 'Aló',
      'merci': 'Mo nuan',
      'oui': 'Ɛ̃ɛ̃',
      'non': 'Jaaj',
      'météo': 'Ngɔ wula',
      'pluie': 'Nzue',
      'soleil': 'Wia',
      'culture': 'Fie',
      'maladie': 'Tukpacɛ',
      'conseil': 'Afɔtuɛ',
      'récolte': 'Fie ajɛ',
      'engrais': 'Asiɛ nguan',
      'eau': 'Nzue',
      'problème': 'Ndɛ',
    },
    'dyu': {
      // Dioula
      'bonjour': 'I ni sogoma',
      'merci': 'I ni ce',
      'oui': 'Ɔwɔ',
      'non': 'Ayi',
      'météo': 'Waati',
      'pluie': 'Sanjii',
      'soleil': 'Tile',
      'culture': 'Sɛnɛ',
      'maladie': 'Bana',
      'conseil': 'Laadili',
      'récolte': 'Suman',
      'engrais': 'Jiri diya',
      'eau': 'Ji',
      'problème': 'Wahala',
    },
    'sev': {
      // Sénoufo
      'bonjour': 'Wali',
      'merci': 'Barikan',
      'oui': 'Iyoo',
      'non': 'Aan',
      'météo': 'Sangari',
      'pluie': 'Fyɛ',
      'soleil': 'Yiri',
      'culture': 'Fankan',
      'maladie': 'Kɔnɔ',
      'conseil': 'Yɔrɔ',
      'récolte': 'Suman',
      'engrais': 'Dugufara',
      'eau': 'Ji',
      'problème': 'Gere',
    },
  };

  // Réponses agricoles en langues locales
  final Map<String, Map<String, String>> _agriculturalResponses = {
    'bci': {
      'irrigation':
          'Fie su nzue yilɛ ti cinnjin. Lika nzue i wie su nglɛmun su annzɛ nnɔsu su kpa.',
      'engrais': 'Asiɛ nguan yilɛ ti kpa. Fa NPK annzɛ fumie sie i fie su.',
      'maladie': 'Sɛ ɔ wun tukpacɛ wie su, fa foto, min fá klɛ wɔ.',
      'météo': 'Andɛ, wia su nglo kpa. Man fɔ sa nzue yolɛ su.',
    },
    'dyu': {
      'irrigation':
          'Ji bɔli ka i sɛnɛ kan, o ka ɲi kosɔbɛ. A ka kan ka ji bɔ sɔgɔma joona.',
      'engrais': 'Jiri diya fɛɛrɛ ka dugukolo ɲi. NPK ni fumie bɛɛ ka ɲi.',
      'maladie': 'Ni i ye bana ye i sɛnɛ kan, a ka foto ta ka n bila.',
      'météo': 'Bi tile bɛ ɲi. Sanjii tɛna na.',
    },
    'sev': {
      'irrigation':
          'Ji feli fankan na ti cinnjin. Feli ji yiri na annzɛ fyɛ tuma.',
      'engrais': 'Dugufara ti kpa fankan ye. NPK ni fumie ye wolo ye.',
      'maladie': 'Ni i ye kɔnɔ ye fankan na, ta foto ka n ci.',
      'météo': 'Bi, yiri ye. Fyɛ tɛ na.',
    },
  };

  AgriChatbotService({required ApiClient apiClient}) : _apiClient = apiClient {
    _initTts();
  }

  LocalLanguage get currentLanguage => _currentLanguage;
  List<ChatMessage> get conversationHistory => _conversationHistory;
  bool get isSpeaking => _isSpeaking;

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.85);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  /// Change la langue du chatbot
  Future<void> setLanguage(LocalLanguage language) async {
    _currentLanguage = language;

    // Pour le français, utiliser le TTS natif
    if (language == LocalLanguage.francais) {
      await _flutterTts.setLanguage("fr-FR");
    }
    // Pour les langues locales, on utilisera l'API cloud ou des fichiers audio
  }

  /// Initialise la reconnaissance vocale
  Future<bool> initSpeechRecognition() async {
    if (_isSpeechInitialized) return true;

    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    _isSpeechInitialized = await _speechToText.initialize(
      onError: (e) => debugPrint('Speech error: ${e.errorMsg}'),
      onStatus: (s) => debugPrint('Speech status: $s'),
    );

    return _isSpeechInitialized;
  }

  /// Démarre l'écoute vocale
  Future<void> startListening({
    required Function(String) onResult,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
  }) async {
    if (!_isSpeechInitialized) {
      bool initialized = await initSpeechRecognition();
      if (!initialized) return;
    }

    if (_speechToText.isNotListening) {
      onListeningStarted();

      // Utiliser le français pour la transcription (plus fiable)
      // puis traduire si nécessaire
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            onListeningStopped();
          }
        },
        localeId: "fr_FR",
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Envoie un message et obtient une réponse
  Future<ChatMessage> sendMessage(String userMessage) async {
    // Ajouter le message utilisateur
    final userMsg = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
      language: _currentLanguage,
    );
    _conversationHistory.add(userMsg);

    try {
      // Appel API pour obtenir la réponse du chatbot
      final response = await _apiClient.post(
        '/chatbot/message',
        data: {
          'message': userMessage,
          'langue': _currentLanguage.code,
          'historique': _conversationHistory
              .take(10)
              .map((m) => {'texte': m.text, 'isUser': m.isUser})
              .toList(),
          'contexte': 'agriculture_ci',
        },
      );

      String botResponse;
      String? audioUrl;

      if (response.data['success'] == true) {
        botResponse =
            response.data['data']['reponse'] ?? _getLocalResponse(userMessage);
        audioUrl = response.data['data']['audioUrl'];
      } else {
        botResponse = _getLocalResponse(userMessage);
      }

      final botMsg = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
        audioUrl: audioUrl,
        language: _currentLanguage,
      );
      _conversationHistory.add(botMsg);

      return botMsg;
    } catch (e) {
      // Fallback local en cas d'erreur réseau
      final botResponse = _getLocalResponse(userMessage);
      final botMsg = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
        language: _currentLanguage,
      );
      _conversationHistory.add(botMsg);
      return botMsg;
    }
  }

  /// Synthèse vocale du message
  Future<void> speak(String text, {String? audioUrl}) async {
    _isSpeaking = true;

    if (_currentLanguage == LocalLanguage.francais) {
      // Utiliser TTS natif pour le français
      await _flutterTts.speak(text);
    } else if (audioUrl != null) {
      // Utiliser l'audio pré-généré pour les langues locales
      // TODO: Implémenter la lecture audio via just_audio ou audioplayers
      // Pour l'instant, on utilise le TTS français
      await _flutterTts.speak(text);
    } else {
      // Fallback: TTS français avec adaptation phonétique
      await _flutterTts.speak(text);
    }
  }

  /// Arrête la synthèse vocale
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _flutterTts.stop();
  }

  /// Génère une réponse locale basée sur les mots-clés
  String _getLocalResponse(String input) {
    final inputLower = input.toLowerCase();
    final langCode = _currentLanguage.code;

    // Détection d'intention
    if (_containsAny(inputLower, [
      'météo',
      'temps',
      'pluie',
      'soleil',
      'climat',
    ])) {
      return _getResponseForTopic('météo', langCode);
    } else if (_containsAny(inputLower, [
      'arroser',
      'irrigation',
      'eau',
      'pompe',
    ])) {
      return _getResponseForTopic('irrigation', langCode);
    } else if (_containsAny(inputLower, [
      'engrais',
      'fertiliser',
      'npk',
      'fumier',
    ])) {
      return _getResponseForTopic('engrais', langCode);
    } else if (_containsAny(inputLower, [
      'maladie',
      'malade',
      'feuille',
      'parasite',
    ])) {
      return _getResponseForTopic('maladie', langCode);
    } else if (_containsAny(inputLower, [
      'récolte',
      'moissonner',
      'cueillir',
    ])) {
      return _getResponseForTopic('récolte', langCode);
    } else if (_containsAny(inputLower, [
      'prix',
      'marché',
      'vendre',
      'acheter',
    ])) {
      return _getResponseForTopic('marché', langCode);
    } else if (_containsAny(inputLower, ['bonjour', 'salut', 'allo'])) {
      return _currentLanguage.greeting;
    } else if (_containsAny(inputLower, ['merci', 'remercie'])) {
      return _getThankYouResponse(langCode);
    }

    // Réponse par défaut
    return _getDefaultResponse(langCode);
  }

  String _getResponseForTopic(String topic, String langCode) {
    if (langCode == 'fr') {
      switch (topic) {
        case 'météo':
          return 'Selon les prévisions, le temps sera favorable pour vos cultures. '
              'Consultez la section météo pour plus de détails.';
        case 'irrigation':
          return 'L\'irrigation est essentielle. Pour vos cultures, je recommande '
              'd\'arroser tôt le matin ou en fin d\'après-midi pour éviter l\'évaporation.';
        case 'engrais':
          return 'Pour une bonne fertilisation, utilisez un engrais NPK adapté à votre culture. '
              'Le compost et le fumier sont aussi excellents pour enrichir le sol.';
        case 'maladie':
          return 'Si vous observez des symptômes sur vos plantes, prenez une photo et utilisez '
              'le diagnostic IA. Je peux vous aider à identifier le problème.';
        case 'récolte':
          return 'La période de récolte dépend de votre culture. Vérifiez les indicateurs de maturité '
              'et planifiez en fonction de la météo.';
        case 'marché':
          return 'Les prix du marché varient. Consultez la section Marketplace pour voir '
              'les cours actuels et trouver les meilleurs acheteurs.';
        default:
          return 'Je suis là pour vous aider avec vos questions agricoles.';
      }
    }

    // Réponses en langues locales
    final responses = _agriculturalResponses[langCode];
    if (responses != null && responses.containsKey(topic)) {
      return responses[topic]!;
    }

    return _getDefaultResponse(langCode);
  }

  String _getThankYouResponse(String langCode) {
    switch (langCode) {
      case 'bci':
        return 'Ɔ ti kpa! N klo wɔ uka.';
      case 'dyu':
        return 'A ni ce! N bɛ yen i ka dɛmɛ la.';
      case 'sev':
        return 'Barikan! N ye yen i deme ye.';
      default:
        return 'Je vous en prie! N\'hésitez pas si vous avez d\'autres questions.';
    }
  }

  String _getDefaultResponse(String langCode) {
    switch (langCode) {
      case 'bci':
        return 'N ti wun sa wie man srɛ wɔ. Man kle sa i bo?';
      case 'dyu':
        return 'N ma o faamu. I bɛ se ka o lakana n ye?';
      case 'sev':
        return 'N te o faamu. I bɛ se ka o fɔ tugun?';
      default:
        return 'Je n\'ai pas bien compris. Pouvez-vous reformuler votre question? '
            'Je peux vous aider avec la météo, l\'irrigation, les maladies, et plus.';
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Traduit un texte vers la langue sélectionnée
  String translateToLocal(String frenchText) {
    if (_currentLanguage == LocalLanguage.francais) return frenchText;

    final langCode = _currentLanguage.code;
    final phrases = _localPhrases[langCode];
    if (phrases == null) return frenchText;

    // Traduction simple par remplacement de mots-clés
    String translated = frenchText.toLowerCase();
    phrases.forEach((french, local) {
      translated = translated.replaceAll(french, local);
    });

    return translated;
  }

  /// Efface l'historique de conversation
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Libère les ressources
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
  }
}
