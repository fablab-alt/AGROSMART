import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/weather.dart';

class WeatherAlertsCard extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const WeatherAlertsCard({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only active alerts
    final activeAlerts = alerts.where((a) => a.isActive).toList();
    if (activeAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.orange.shade50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alertes Météorologiques',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${activeAlerts.length} ${activeAlerts.length > 1 ? 'alertes actives' : 'alerte active'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...activeAlerts.map((alert) => _buildAlertTile(context, alert)),
        ],
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, WeatherAlert alert) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNiveauColor(alert.niveau),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.niveau.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
            ),
          ),
          if (alert.recommandation != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.recommandation!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Valide jusqu\'au ${DateFormat('dd/MM/yyyy HH:mm', 'fr').format(alert.dateFin)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNiveauColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'danger':
        return Colors.red.shade700;
      case 'alerte':
        return Colors.orange.shade700;
      case 'attention':
        return Colors.amber.shade700;
      case 'info':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
