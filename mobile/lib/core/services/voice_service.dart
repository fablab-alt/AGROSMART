import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechInitialized = false;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<bool> initSpeech() async {
    if (!_isSpeechInitialized) {
      // Demander la permission micro explicitement
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) return false;
      }
      
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (e) {},
        onStatus: (s) {},
      );
    }
    return _isSpeechInitialized;
  }

  Future<void> listen({
    required Function(String) onResult,
    required Function() onListening,
    required Function() onNotListening,
  }) async {
    if (!_isSpeechInitialized) {
      bool initialized = await initSpeech();
      if (!initialized) return;
    }

    if (_speechToText.isNotListening) {
      onListening();
      await _speechToText.listen(
        onResult: (result) {
           if (result.finalResult) {
             onResult(result.recognizedWords);
             onNotListening();
           }
        },
        localeId: "fr_FR",
      );
    } else {
      onNotListening();
      await _speechToText.stop();
    }
  }

  // Support des langues locales (simulation pour l'instant car TTS/STT limités)
  Future<void> setLanguage(String languageCode) async {
    switch (languageCode) {
      case 'fr': // Français
        await _flutterTts.setLanguage("fr-FR");
        break;
      // Note: Baoulé, Malinké, Sénoufo ne sont pas nativement supportés par les moteurs TTS Android/iOS standards.
      // Une solution serait d'utiliser des fichiers audio pré-enregistrés pour les phrases clés
      // ou une API cloud spécialisée. Pour ce prototype, on reste en FR.
      default:
        await _flutterTts.setLanguage("fr-FR");
    }
  }
}
