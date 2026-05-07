import 'package:flutter/material.dart';
import '../../analytics/domain/entities/analytics_data.dart';

class PerformanceParcellesCard extends StatelessWidget {
  final List<PerformanceParcelle> parcelles;

  const PerformanceParcellesCard({super.key, required this.parcelles});

  @override
  Widget build(BuildContext context) {
    if (parcelles.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by rendement (highest first)
    final sortedParcelles = List<PerformanceParcelle>.from(parcelles)
      ..sort((a, b) => b.rendement.compareTo(a.rendement));

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
                  'Performance des Parcelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.leaderboard,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Classement par rendement',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...sortedParcelles.asMap().entries.map((entry) {
              final index = entry.key;
              final parcelle = entry.value;
              return _buildParcelleRow(context, parcelle, index + 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelleRow(
    BuildContext context,
    PerformanceParcelle parcelle,
    int rank,
  ) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        rankIcon = Icons.emoji_events;
        break;
      case 2:
        rankColor = Colors.grey.shade400;
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = Colors.brown.shade300;
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.grey.shade600;
        rankIcon = Icons.circle;
    }

    final qualityPercent = parcelle.scoreQualite / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: rank == 1
              ? rankColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
        color: rank == 1 ? rankColor.withValues(alpha: 0.05) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(rankIcon, size: 16, color: rankColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcelle.nom,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${parcelle.rendement.toStringAsFixed(1)} t/ha',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qualité Sol',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${parcelle.scoreQualite.toStringAsFixed(0)}/100',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: qualityPercent,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          qualityPercent >= 0.8
                              ? Colors.green
                              : qualityPercent >= 0.6
                              ? Colors.orange
                              : Colors.red,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (parcelle.meilleurePratique.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parcelle.meilleurePratique,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
