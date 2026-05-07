
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class VoiceAssistantContent extends StatefulWidget {
  const VoiceAssistantContent({super.key});

  @override
  State<VoiceAssistantContent> createState() => _VoiceAssistantContentState();
}

class _VoiceAssistantContentState extends State<VoiceAssistantContent> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  String _status = "Initialisation...";
  Color _iconColor = Colors.grey;
  IconData _icon = Icons.mic_off;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (errorNotification) {
        setState(() {
          _status = "Erreur: ${errorNotification.errorMsg}";
          _iconColor = Colors.red;
          _icon = Icons.error;
        });
      },
      onStatus: (status) {
         if (status == 'done' || status == 'notListening') {
           // If we stopped listening, verify command
           if (_lastWords.isNotEmpty) {
             _processCommand(_lastWords);
           }
         }
      }
    );
    
    if (_speechEnabled) {
      setState(() {
        _status = "Je vous écoute...";
        _iconColor = const Color(0xFF28A745);
        _icon = Icons.mic;
      });
      _startListening();
    } else {
      setState(() {
        _status = "Microphone non disponible";
        _iconColor = Colors.red;
      });
    }
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: "fr_FR", // Clean French input preferred
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _status = _lastWords; // Show what is being heard
    });
  }

  Future<void> _processCommand(String command) async {
    final cmd = command.toLowerCase();
    
    // Feedback UI
    setState(() {
      _status = "Traitement: $_lastWords";
      _icon = Icons.psychology;
      _iconColor = Colors.blue;
    });

    await Future.delayed(const Duration(seconds: 1)); // UX delay

    if (!mounted) return;

    if (cmd.contains("météo") || cmd.contains("climat") || cmd.contains("temps")) {
      _navigateAndClose('/weather', "Météo");
    } else if (cmd.contains("marché") || cmd.contains("prix") || cmd.contains("vendre") || cmd.contains("produit")) {
      _navigateAndClose('/marketplace', "Marketplace");
    } else if (cmd.contains("diagnostic") || cmd.contains("maladie") || cmd.contains("photo") || cmd.contains("plante")) {
      _navigateAndClose('/diagnostic', "Diagnostic");
    } else if (cmd.contains("profil") || cmd.contains("compte")) {
      _navigateAndClose('/profile', "Profil");
    } else if (cmd.contains("parcelle") || cmd.contains("champ")) {
      _navigateAndClose('/parcelles', "Parcelles");
    } else if (cmd.contains("conseil") || cmd.contains("aide")) {
      _navigateAndClose('/recommandations', "Recommandations");
    } else {
      setState(() {
        _status = "Commande non comprise. Réessayez.";
        _icon = Icons.help_outline;
        _iconColor = Colors.orange;
      });
      // Restart listening after a delay?
      await Future.delayed(const Duration(seconds: 2));
      _startListening();
    }
  }

  void _navigateAndClose(String route, String featureName) {
    if (!mounted) return;
    setState(() {
      _status = "Navigation vers $featureName...";
      _icon = Icons.check_circle;
      _iconColor = Colors.green;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
        context.push(route);
      }
    });
  }
  
  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }



  Widget _buildSuggestions() {
    final commands = [
      {"label": "Météo", "cmd": "météo"},
      {"label": "Marketplace", "cmd": "marché"},
      {"label": "Diagnostic", "cmd": "diagnostic"},
      {"label": "Profil", "cmd": "profil"},
      {"label": "Parcelles", "cmd": "parcelle"},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: commands.map((item) {
        return ActionChip(
          label: Text(item["label"]!),
          avatar: const Icon(Icons.touch_app, size: 16),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
          onPressed: () {
             setState(() {
               _lastWords = item["cmd"]!;
             });
             _processCommand(item["cmd"]!);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _speechToText.isNotListening ? _startListening : _speechToText.stop,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: _speechToText.isListening 
                    ? Border.all(color: _iconColor, width: 2) 
                    : null,
              ),
              child: Icon(_icon, size: 64, color: _iconColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: _iconColor == Colors.red ? Colors.red : Theme.of(context).textTheme.titleLarge?.color
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _speechToText.isListening ? "Parlez maintenant..." : "Appuyez pour parler ou choisissez une option :",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (!_speechToText.isListening && !_status.startsWith("Nav"))
             _buildSuggestions(),
        ],
      ),
    );
  }
}
