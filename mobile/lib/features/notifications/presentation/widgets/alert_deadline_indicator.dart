import 'package:flutter/material.dart';
import '../../domain/entities/alert.dart';

class AlertDeadlineIndicator extends StatelessWidget {
  final Alert alert;

  const AlertDeadlineIndicator({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    if (alert.deadlineResponse == null) {
      return const SizedBox.shrink();
    }

    final timeRemaining = alert.timeRemaining;
    if (timeRemaining == null) {
      return const SizedBox.shrink();
    }

    final isOverdue = alert.isOverdue;
    final hours = timeRemaining.inHours.abs();
    final bool isUrgent = hours < 6 && !isOverdue;

    Color color;
    IconData icon;
    String text;

    if (isOverdue) {
      color = Colors.red.shade700;
      icon = Icons.access_time_filled;
      text = 'En retard de ${hours}h';
    } else if (isUrgent) {
      color = Colors.orange.shade700;
      icon = Icons.access_alarm;
      text = 'Reste ${hours}h';
    } else {
      color = Colors.grey.shade600;
      icon = Icons.access_time;
      text = hours < 24 ? '${hours}h restantes' : '${timeRemaining.inDays}j restants';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
