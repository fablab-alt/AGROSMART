import 'package:flutter/material.dart';
import '../../analytics/domain/entities/analytics_data.dart';

class YieldByCropCard extends StatelessWidget {
  final List<RendementParCulture> rendements;

  const YieldByCropCard({super.key, required this.rendements});

  @override
  Widget build(BuildContext context) {
    if (rendements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rendements par Culture',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.agriculture,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rendements.map((r) => _buildCropRow(context, r)),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRow(BuildContext context, RendementParCulture rendement) {
    final progressPercent = rendement.rendementObjectif > 0
        ? (rendement.rendementActuel / rendement.rendementObjectif).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color performanceColor;
    if (progressPercent >= 0.9) {
      performanceColor = Colors.green;
    } else if (progressPercent >= 0.7) {
      performanceColor = Colors.orange;
    } else {
      performanceColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rendement.culture,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: performanceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rendement.improvement >= 0 ? '+' : ''}${rendement.improvement.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: performanceColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          performanceColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actuel: ${rendement.rendementActuel.toStringAsFixed(1)} t/ha',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              Text(
                'Objectif: ${rendement.rendementObjectif.toStringAsFixed(1)} t/ha',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
