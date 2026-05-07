import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../analytics/domain/entities/analytics_data.dart';

class RoiCard extends StatelessWidget {
  final AnalyticsData analytics;

  const RoiCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.00', 'fr_FR');

    IconData trendIcon = Icons.trending_flat;

    switch (analytics.roiTrend) {
      case 'up':
        trendIcon = Icons.trending_up;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.orange.shade800, Colors.deepOrange.shade900]
                : [Colors.orange.shade400, Colors.deepOrange.shade600],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Retour sur Investissement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(trendIcon, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${numberFormat.format(analytics.roiPercentage)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.eco,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  analytics.rendement.vsTraditional
                      ? '${analytics.rendement.value} vs Traditionnel'
                      : analytics.rendement.value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Économies intelligentes',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
