import 'package:flutter/material.dart';
import '../services/voice_assistant_service.dart';
import '../../../injection_container.dart';

class VoiceAssistantButton extends StatefulWidget {
  final Function(String) onResult;

  const VoiceAssistantButton({super.key, required this.onResult});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton>
    with SingleTickerProviderStateMixin {
  final VoiceAssistantService _service = sl<VoiceAssistantService>();
  bool _isListening = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _service.stop();
      setState(() => _isListening = false);
    } else {
      bool avail = await _service.init();
      if (avail) {
        setState(() => _isListening = true);
        _service.startListening(
          onResult: (text) {
            widget.onResult(text);
          },
          onDone: () {
            if (mounted) setState(() => _isListening = false);
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'voice_assistant_fab',
      onPressed: _toggleListening,
      backgroundColor: _isListening ? Colors.red : Colors.green,
      child: _isListening
          ? ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.2).animate(_controller),
              child: const Icon(Icons.mic),
            )
          : const Icon(Icons.mic_none),
    );
  }
}
