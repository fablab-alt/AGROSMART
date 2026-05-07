import 'package:flutter/material.dart';

/// Widget affichant les alertes actives
class AlertsWidget extends StatelessWidget {
  final List<AlertItem> alerts;
  final VoidCallback? onViewAll;

  const AlertsWidget({
    super.key,
    required this.alerts,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.3) : Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aucune alerte active. Vos parcelles sont en bon état !',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Alertes (${alerts.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Voir tout'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.take(3).map((alert) => _buildAlertItem(alert, context)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AlertItem alert, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(alert.level).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getAlertColor(alert.level).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getAlertColor(alert.level).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAlertIcon(alert.type),
              color: _getAlertColor(alert.level),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getAlertColor(alert.level),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert.time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critical:
        return Colors.red;
      case AlertLevel.warning:
        return Colors.orange;
      case AlertLevel.info:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.water:
        return Icons.water_drop;
      case AlertType.disease:
        return Icons.bug_report;
      case AlertType.temperature:
        return Icons.thermostat;
      case AlertType.nutrient:
        return Icons.eco;
      case AlertType.weather:
        return Icons.cloud;
      case AlertType.general:
        return Icons.info;
    }
  }
}

enum AlertLevel { critical, warning, info }

enum AlertType { water, disease, temperature, nutrient, weather, general }

class AlertItem {
  final String title;
  final String message;
  final AlertLevel level;
  final AlertType type;
  final String time;
  final String? parcelleName;

  AlertItem({
    required this.title,
    required this.message,
    required this.level,
    required this.type,
    required this.time,
    this.parcelleName,
  });
}
