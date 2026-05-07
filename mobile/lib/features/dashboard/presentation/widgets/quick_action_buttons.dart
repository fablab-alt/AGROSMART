import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Quick action buttons for dashboard (scan disease, irrigation, etc.)
class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: "Scanner\nmaladie",
            color: const Color(0xFF2196F3),
            onPressed: () => context.push('/diagnostic'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.water_drop_outlined,
            label: "Programmer\nirrigation",
            color: const Color(0xFFFF9800),
            onPressed: () => context.push('/irrigation'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
      ),
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Extended quick actions header with voice assistant
class QuickActionsHeader extends StatelessWidget {
  final VoidCallback? onVoiceAssistantTap;

  const QuickActionsHeader({super.key, this.onVoiceAssistantTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Actions rapides",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (onVoiceAssistantTap != null)
          _VoiceAssistantButton(onTap: onVoiceAssistantTap!),
      ],
    );
  }
}

class _VoiceAssistantButton extends StatelessWidget {
  final VoidCallback onTap;

  const _VoiceAssistantButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF28A745), Color(0xFF20C997)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF28A745).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 24),
      ),
    );
  }
}
