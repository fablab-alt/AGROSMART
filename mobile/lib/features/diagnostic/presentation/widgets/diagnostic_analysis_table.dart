import 'package:flutter/material.dart';
import '../../data/models/diagnostic_model.dart';

/// Widget affichant un tableau d'analyse détaillé du diagnostic
class DiagnosticAnalysisTable extends StatelessWidget {
  final DiagnosticModel diagnostic;
  final VoidCallback? onSendToRecommendations;

  const DiagnosticAnalysisTable({
    super.key,
    required this.diagnostic,
    this.onSendToRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final _ = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          _buildHeader(context),

          // Tableau d'analyse principal
          _buildMainAnalysisSection(context),

          // Métriques détaillées
          _buildDetailedMetrics(context),

          // Facteurs identifiés
          _buildFactorsSection(context),

          // Recommandations rapides
          _buildQuickRecommendations(context),

          // Actions
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isHealthy = diagnostic.isHealthy;
    final headerColor = isHealthy ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor.withOpacity(0.8), headerColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isHealthy ? Icons.check_circle : Icons.warning_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diagnostic.diseaseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildConfidenceBadge(),
                    const SizedBox(width: 8),
                    _buildSeverityBadge(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = diagnostic.confidenceScore;
    Color badgeColor = Colors.green;
    if (confidence < 70) badgeColor = Colors.orange;
    if (confidence < 50) badgeColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '${confidence.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge() {
    final severity = diagnostic.severity.toLowerCase();
    Color severityColor;
    String label;
    IconData icon;

    switch (severity) {
      case 'low':
      case 'faible':
        severityColor = Colors.green;
        label = 'Faible';
        icon = Icons.trending_down;
        break;
      case 'medium':
      case 'moyen':
        severityColor = Colors.orange;
        label = 'Moyen';
        icon = Icons.remove;
        break;
      case 'high':
      case 'severe':
      case 'élevé':
        severityColor = Colors.red;
        label = 'Sévère';
        icon = Icons.trending_up;
        break;
      default:
        severityColor = Colors.grey;
        label = severity;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAnalysisSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de l\'analyse',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Tableau de données
          Table(
            columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
            children: [
              _buildTableRow(context, 'Culture', diagnostic.cropType),
              _buildTableRow(context, 'Diagnostic', diagnostic.diseaseName),
              _buildTableRow(
                context,
                'Confiance',
                '${diagnostic.confidenceScore}%',
              ),
              _buildTableRow(
                context,
                'Sévérité',
                _getSeverityLabel(diagnostic.severity),
              ),
              _buildTableRow(
                context,
                'Date',
                _formatDate(diagnostic.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics(BuildContext context) {
    // Simuler des métriques détaillées basées sur le diagnostic
    final metrics = _generateMetrics();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Indicateurs clés',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: metrics.map((m) => _buildMetricCard(context, m)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateMetrics() {
    // Générer des métriques basées sur le diagnostic
    final isHealthy = diagnostic.isHealthy;
    final confidence = diagnostic.confidenceScore;

    return [
      {
        'label': 'Score santé',
        'value': isHealthy
            ? '95%'
            : '${(100 - confidence * 0.8).toStringAsFixed(0)}%',
        'icon': Icons.favorite,
        'color': isHealthy ? Colors.green : Colors.red,
      },
      {
        'label': 'Propagation',
        'value': _getPropagationRisk(),
        'icon': Icons.share,
        'color': _getPropagationColor(),
      },
      {
        'label': 'Urgence',
        'value': _getUrgencyLevel(),
        'icon': Icons.schedule,
        'color': _getUrgencyColor(),
      },
      {
        'label': 'Traitement',
        'value': isHealthy ? 'Non requis' : 'Recommandé',
        'icon': Icons.healing,
        'color': isHealthy ? Colors.green : Colors.orange,
      },
    ];
  }

  String _getPropagationRisk() {
    if (diagnostic.isHealthy) return 'Aucun';
    final severity = diagnostic.severity.toLowerCase();
    if (severity.contains('high') || severity.contains('severe'))
      return 'Élevé';
    if (severity.contains('medium') || severity.contains('moyen'))
      return 'Modéré';
    return 'Faible';
  }

  Color _getPropagationColor() {
    if (diagnostic.isHealthy) return Colors.green;
    final severity = diagnostic.severity.toLowerCase();
    if (severity.contains('high') || severity.contains('severe'))
      return Colors.red;
    if (severity.contains('medium') || severity.contains('moyen'))
      return Colors.orange;
    return Colors.yellow.shade700;
  }

  String _getUrgencyLevel() {
    if (diagnostic.isHealthy) return 'Aucune';
    final confidence = diagnostic.confidenceScore;
    if (confidence > 85) return 'Haute';
    if (confidence > 60) return 'Moyenne';
    return 'Faible';
  }

  Color _getUrgencyColor() {
    if (diagnostic.isHealthy) return Colors.green;
    final confidence = diagnostic.confidenceScore;
    if (confidence > 85) return Colors.red;
    if (confidence > 60) return Colors.orange;
    return Colors.yellow.shade700;
  }

  Widget _buildMetricCard(BuildContext context, Map<String, dynamic> metric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (metric['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (metric['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            metric['icon'] as IconData,
            color: metric['color'] as Color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  metric['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  metric['value'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: metric['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorsSection(BuildContext context) {
    if (diagnostic.isHealthy) return const SizedBox.shrink();

    // Générer des facteurs basés sur le diagnostic
    final factors = _generateFactors();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facteurs identifiés',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...factors.map((f) => _buildFactorItem(context, f)).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateFactors() {
    // Générer des facteurs hypothétiques basés sur le type de maladie
    final disease = diagnostic.diseaseName.toLowerCase();

    if (disease.contains('mildiou')) {
      return [
        {
          'name': 'Humidité élevée',
          'impact': 'Facteur principal',
          'severity': 'high',
        },
        {
          'name': 'Température modérée',
          'impact': 'Favorise le développement',
          'severity': 'medium',
        },
        {
          'name': 'Ventilation insuffisante',
          'impact': 'Aggrave la propagation',
          'severity': 'medium',
        },
      ];
    } else if (disease.contains('rouille')) {
      return [
        {
          'name': 'Stress hydrique',
          'impact': 'Affaiblit les défenses',
          'severity': 'high',
        },
        {
          'name': 'Carence nutritive',
          'impact': 'Sensibilité accrue',
          'severity': 'medium',
        },
      ];
    } else if (disease.contains('carence')) {
      return [
        {
          'name': 'Sol appauvri',
          'impact': 'Manque de nutriments',
          'severity': 'high',
        },
        {
          'name': 'pH inadéquat',
          'impact': 'Mauvaise absorption',
          'severity': 'medium',
        },
      ];
    }

    return [
      {
        'name': 'Conditions environnementales',
        'impact': 'À surveiller',
        'severity': 'medium',
      },
    ];
  }

  Widget _buildFactorItem(BuildContext context, Map<String, dynamic> factor) {
    Color severityColor;
    switch (factor['severity']) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.yellow.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  factor['impact'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildQuickRecommendations(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Actions recommandées',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (diagnostic.isHealthy) ...[
            _buildRecommendationItem(
              context,
              'Surveillance préventive',
              'Continuer les inspections régulières',
              Icons.visibility,
              Colors.green,
            ),
            _buildRecommendationItem(
              context,
              'Maintenir les bonnes pratiques',
              'Irrigation et fertilisation optimales',
              Icons.eco,
              Colors.blue,
            ),
          ] else ...[
            if (diagnostic.treatmentSuggestions.isNotEmpty)
              _buildRecommendationItem(
                context,
                'Traitement',
                diagnostic.treatmentSuggestions,
                Icons.medical_services,
                Colors.red,
              ),
            if (diagnostic.recommendations.isNotEmpty)
              _buildRecommendationItem(
                context,
                'Recommandation',
                diagnostic.recommendations,
                Icons.info_outline,
                Colors.orange,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Partager le diagnostic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Diagnostic partagé')),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      onSendToRecommendations ??
                      () {
                        Navigator.pushNamed(context, '/recommandations');
                      },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Voir actions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSeverityLabel(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
      case 'faible':
        return 'Faible';
      case 'medium':
      case 'moyen':
        return 'Moyen';
      case 'high':
      case 'severe':
      case 'élevé':
        return 'Sévère';
      default:
        return severity;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
