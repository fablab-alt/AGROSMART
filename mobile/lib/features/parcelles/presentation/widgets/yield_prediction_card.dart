import 'package:flutter/material.dart';

class YieldPredictionCard extends StatelessWidget {
  final double prediction; // Tonnes
  final double confidence; // 0.0 to 1.0
  final List<String> factors;

  const YieldPredictionCard({
    super.key,
    required this.prediction,
    required this.confidence,
    required this.factors,
  });

  void _showExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Comment est calculé le rendement ?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calcul basé sur l\'analyse IA',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Le système analyse en temps réel :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              _ExplanationItem(
                icon: Icons.science,
                title: 'Données NPK',
                description:
                    'Niveaux d\'azote, phosphore et potassium dans le sol',
              ),
              _ExplanationItem(
                icon: Icons.water_drop,
                title: 'Humidité du sol',
                description: 'Taux d\'hydratation optimal pour la culture',
              ),
              _ExplanationItem(
                icon: Icons.thermostat,
                title: 'Température',
                description: 'Conditions climatiques ambiantes',
              ),
              _ExplanationItem(
                icon: Icons.cloud,
                title: 'Données météo',
                description: 'Prévisions et historique des précipitations',
              ),
              SizedBox(height: 16),
              Text('Formule :', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Card(
                color: Color(0xFFF5F5F5),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Rendement = (Rendement de base × Multiplicateurs)',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Les multiplicateurs dépendent de l\'état optimal de chaque facteur (+10% si optimal, -20% si critique).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Prédiction de Rendement",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Analyse IA",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.grey),
                  onPressed: () => _showExplanation(context),
                  tooltip: 'Comment ça marche ?',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${prediction.toStringAsFixed(1)} Tonnes",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      "Estimation totale",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: confidence,
                        backgroundColor: Colors.grey.shade200,
                        color: confidence > 0.8 ? Colors.green : Colors.orange,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${(confidence * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Facteurs clés :",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: factors
                  .map(
                    (f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.green.shade200),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ExplanationItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
