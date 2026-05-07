import 'package:flutter/material.dart';
import '../../features/analytics/domain/entities/analytics_data.dart';

/// Widget affichant les détails de la prédiction de rendement
class YieldPredictionWidget extends StatelessWidget {
  final PredictionDetails prediction;
  final VoidCallback? onTapDetails;

  const YieldPredictionWidget({
    super.key,
    required this.prediction,
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D2137)]
              : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec badge IA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Prédiction IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    prediction.modelVersion,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (onTapDetails != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white70),
                  onPressed: onTapDetails,
                  tooltip: 'Voir les détails',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Valeur principale de rendement
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatYield(prediction.predictedYield),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kg/ha estimé',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          // Fourchette de prédiction
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.greenAccent.shade200,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Fourchette: ${_formatYield(prediction.minYield)} - ${_formatYield(prediction.maxYield)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Facteurs d'influence
          const Text(
            'Facteurs d\'influence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Liste des facteurs
          ...prediction.factors
              .take(3)
              .map((factor) => _buildFactorRow(factor)),

          if (prediction.factors.length > 3) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTapDetails,
              child: Text(
                'Voir tous les facteurs (${prediction.factors.length})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],

          // Données temps réel utilisées
          if (prediction.realTimeInputs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${prediction.realTimeInputs.length} données temps réel analysées',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorRow(PredictionFactor factor) {
    Color statusColor;
    IconData statusIcon;

    switch (factor.status) {
      case FactorStatus.optimal:
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case FactorStatus.warning:
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.warning;
        break;
      case FactorStatus.critical:
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  factor.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: factor.impact >= 0
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${factor.impact >= 0 ? '+' : ''}${factor.impact.toStringAsFixed(0)}%',
              style: TextStyle(
                color: factor.impact >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatYield(double yield) {
    if (yield >= 1000) {
      return '${(yield / 1000).toStringAsFixed(1)}t';
    }
    return yield.toStringAsFixed(0);
  }
}

/// Widget carte compacte pour le dashboard
class YieldPredictionCard extends StatelessWidget {
  final String value;
  final bool isPrediction;
  final double confidence;
  final VoidCallback? onTap;

  const YieldPredictionCard({
    super.key,
    required this.value,
    this.isPrediction = false,
    this.confidence = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isPrediction
              ? const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrediction ? null : const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isPrediction ? Icons.auto_awesome : Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
                if (isPrediction) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPrediction ? 'Rendement\nestimé (IA)' : 'Rendement\nmoyen',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                height: 1.2,
              ),
            ),
            if (isPrediction && confidence < 1.0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Confiance: ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
