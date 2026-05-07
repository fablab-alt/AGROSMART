import 'package:flutter/material.dart';
import '../../domain/entities/alert.dart';

class AlertPriorityBadge extends StatelessWidget {
  final Alert alert;

  const AlertPriorityBadge({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final String label;
    final IconData icon;

    switch (alert.level) {
      case AlertLevel.critique:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        label = 'CRITIQUE';
        icon = Icons.error;
        break;
      case AlertLevel.important:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        label = 'IMPORTANT';
        icon = Icons.warning;
        break;
      case AlertLevel.info:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        label = 'INFO';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
