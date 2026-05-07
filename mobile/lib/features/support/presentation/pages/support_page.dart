import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Aide et Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact direct
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contactez-nous',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildContactOption(
                    icon: Icons.phone,
                    title: 'Téléphone',
                    subtitle: '+225 07 00 00 00 01',
                    color: Colors.green,
                    onTap: () => _launchUrl('tel:+2250700000001'),
                  ),
                  const Divider(),
                  _buildContactOption(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'support@agrosmart.ci',
                    color: Colors.blue,
                    onTap: () => _launchUrl('mailto:support@agrosmart.ci'),
                  ),
                  const Divider(),
                  _buildContactOption(
                    icon: Icons.chat,
                    title: 'WhatsApp',
                    subtitle: 'Chat en direct',
                    color: Colors.green,
                    onTap: () => _launchUrl('https://wa.me/2250700000001'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FAQ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Questions Fréquentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    question: 'Comment ajouter un capteur ?',
                    answer:
                        'Allez dans "Capteurs" > "+" > Scannez le QR code du capteur ou entrez son code manuellement.',
                  ),
                  _buildFAQItem(
                    question: 'Comment diagnostiquer une maladie ?',
                    answer:
                        'Utilisez l\'onglet "Diagnostic" > Prenez une photo de la plante malade > L\'IA analysera l\'image automatiquement.',
                  ),
                  _buildFAQItem(
                    question: 'Comment vendre sur le marketplace ?',
                    answer:
                        'Allez dans "Marketplace" > "Mes annonces" > "+" > Remplissez les informations du produit.',
                  ),
                  _buildFAQItem(
                    question: 'Mes données sont-elles sécurisées ?',
                    answer:
                        'Oui, toutes vos données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais vos informations.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Guides
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.orange),
              title: const Text('Guides d\'utilisation'),
              subtitle: const Text('Tutoriels vidéo et PDF'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to guides
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Guides disponibles dans Formations'),
                  ),
                );
              },
            ),
          ),

          // Feedback
          Card(
            child: ListTile(
              leading: const Icon(Icons.feedback, color: Colors.purple),
              title: const Text('Envoyer un feedback'),
              subtitle: const Text('Aidez-nous à nous améliorer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showFeedbackDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Votre Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Partagez vos suggestions ou remarques...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send feedback to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merci pour votre feedback !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
