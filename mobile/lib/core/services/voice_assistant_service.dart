import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class VoiceAssistantService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (e) => debugPrint('Error: $e'),
        onStatus: (s) => debugPrint('Status: $s'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Voice init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isInitialized) await init();
    
    if (_isInitialized) {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            onDone();
          }
        },
        localeId: 'fr_FR', // Default to French
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
