import 'package:flutter/material.dart';
import '../../analytics/domain/entities/analytics_data.dart';

class EconomicMetricsCard extends StatelessWidget {
  final AnalyticsData analytics;

  const EconomicMetricsCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Économies Réalisées',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              label: 'Eau Économisée',
              value: analytics.eauEconomisee,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              context,
              icon: Icons.eco,
              iconColor: Colors.green,
              label: 'Réduction Engrais',
              value: analytics.engraisReduction,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              context,
              icon: Icons.shield,
              iconColor: Colors.orange,
              label: 'Pertes Évitées (Maladies)',
              value: analytics.pertesMaladies,
            ),
            if (analytics.economies.total > 0) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.savings,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Économisé',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${analytics.economies.total.toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
