import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../bloc/settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'Français';
  bool _notificationsEnabled = true;
  bool _smsAlertsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Watch current theme mode
    final currentTheme = context.watch<ThemeCubit>().state;
    final isDark = currentTheme == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Langue
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Langue / Language',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                _buildLanguageOption('Français', '🇫🇷'),
                _buildLanguageOption('Baoulé', '🇨🇮'),
                _buildLanguageOption('Dioula', '🇨🇮'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notifications
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Notifications push'),
                  subtitle: const Text('Recevoir les alertes sur le téléphone'),
                  value: _notificationsEnabled,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Alertes SMS'),
                  subtitle: const Text(
                    'Recevoir les alertes critiques par SMS',
                  ),
                  value: _smsAlertsEnabled,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() => _smsAlertsEnabled = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Apparence
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Apparence',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mode sombre'),
                  subtitle: const Text('Activer le thème sombre'),
                  value: isDark,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    context.read<ThemeCubit>().setTheme(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Données
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Données et Stockage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mode économie de données'),
                  subtitle: const Text(
                    'Ne pas charger les images lourdes automatiquement',
                  ),
                  value: context.watch<SettingsCubit>().state.isLowDataMode,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleLowDataMode(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Compte
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Compte',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                _buildListTile(
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.security,
                  title: 'Vérification en 2 étapes',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.download,
                  title: 'Télécharger mes données',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // À propos
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'À propos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                _buildListTile(
                  icon: Icons.description,
                  title: 'Conditions d\'utilisation',
                  onTap: () {},
                ),
                _buildListTile(
                  icon: Icons.privacy_tip,
                  title: 'Politique de confidentialité',
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Version'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Danger zone
          Container(
            color: Theme.of(context).cardColor,
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Supprimer mon compte',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _showDeleteAccountDialog(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLanguageOption(String language, String flag) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(language),
        ],
      ),
      value: language,
      groupValue: _selectedLanguage,
      activeColor: Colors.green,
      onChanged: (value) {
        setState(() => _selectedLanguage = value!);
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
