import 'package:flutter/material.dart';

class DiagnosticDetailPage extends StatelessWidget {
  final Map<String, dynamic> diagnostic;

  const DiagnosticDetailPage({
    super.key,
    required this.diagnostic,
  });

  @override
  Widget build(BuildContext context) {
    // Mock recommendations based on disease
    final recommendations = [
      'Isoler la plante infectée immédiatement',
      'Appliquer un fongicide à base de cuivre',
      'Réduire l\'arrosage pour limiter l\'humidité',
      'Surveiller les plants voisins pendant 7 jours'
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Détails Diagnostic'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.purple.shade200,
              ),
            ),
            const SizedBox(height: 24),

            // Title & Severity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    diagnostic['disease'] ?? 'Maladie inconnue',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildSeverityBadge(diagnostic['severity']),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Culture: ${diagnostic['crop']} • Confiance: ${diagnostic['confidence']}%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Metadata
            _buildInfoRow(Icons.calendar_today, 'Date', diagnostic['date'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Lieu', diagnostic['location'] ?? 'Non spécifié'),
            
            const Divider(height: 48),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette maladie se caractérise par des taches sur les feuilles et une décoloration progressive. Elle peut affecter la productivité si elle n\'est pas traitée rapidement.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Recommendations
            const Text(
              'Recommandations IA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Conseiller contacté !'))
                   );
                },
                icon: const Icon(Icons.support_agent),
                label: const Text('Contacter un expert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String? severity) {
    Color color;
    String text;
    
    switch (severity) {
      case 'critical':
        color = Colors.red;
        text = 'Critique';
        break;
      case 'warning':
        color = Colors.orange;
        text = 'Attention';
        break;
      case 'info':
        color = Colors.blue;
        text = 'Info';
        break;
      default:
        color = Colors.green;
        text = 'Sain';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
