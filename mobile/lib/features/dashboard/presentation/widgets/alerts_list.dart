import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_data.dart';

class AlertsList extends StatelessWidget {
  final List<Alert> alerts;

  const AlertsList({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertes Récentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              color: _getAlertColor(alert.level).withValues(alpha: 0.1),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: _getAlertColor(alert.level)),
                title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(alert.message),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getAlertColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }
}
