import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/core/services/voice_service.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/injection_container.dart' as di;

/// Page de profil unifiée pour tous les rôles
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _voiceModeEnabled = false;
  String _selectedLanguage = 'Français';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOperationalStats();
    });
  }

  void _loadOperationalStats() {
    context.read<ParcelleBloc>().add(const LoadParcelles());
    context.read<SensorBloc>().add(const LoadSensors());
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _voiceModeEnabled = prefs.getBool('voice_mode_enabled') ?? false;
        _selectedLanguage = prefs.getString('language') ?? 'Français';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Veuillez vous connecter',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = state.user;
        final isProducer = user.role.toUpperCase() != 'ACHETEUR';
        final parcelleState = context.watch<ParcelleBloc>().state;
        final sensorState = context.watch<SensorBloc>().state;

        final liveParcelles = parcelleState is ParcelleLoaded
            ? parcelleState.parcelles
            : <Parcelle>[];
        final liveSensors = sensorState is SensorLoaded
            ? sensorState.sensors
            : <Sensor>[];

        final hasLiveStats = liveParcelles.isNotEmpty || liveSensors.isNotEmpty;

        final parcellesCount = hasLiveStats
            ? liveParcelles.length
            : user.parcellesCount;

        final hectaresTotal = hasLiveStats
            ? liveParcelles.fold<double>(
                0,
                (sum, parcelle) => sum + parcelle.superficie,
              )
            : (user.hectaresTotal > 0
                  ? user.hectaresTotal
                  : (user.superficieExploitee ?? 0));

        final capteursCount = hasLiveStats
            ? liveSensors.length
            : user.capteursCount;

        final production3Mois =
            (user.productionMois1 ?? 0) +
            (user.productionMois2 ?? 0) +
            (user.productionMois3 ?? 0);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, user, isProducer),
                if (isProducer) ...[
                  const SizedBox(height: 16),
                  _buildStatisticsCards(
                    context,
                    parcellesCount: parcellesCount,
                    hectaresTotal: hectaresTotal,
                    capteursCount: capteursCount,
                    production3Mois: production3Mois,
                  ),
                ],
                const SizedBox(height: 20),
                _buildMenuSection(context, isProducer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    bool isProducer,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              isProducer ? Icons.agriculture : Icons.shopping_bag,
              size: 50,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nom ?? 'Utilisateur',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.telephone ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProducer ? 'Producteur' : 'Acheteur',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(
    BuildContext context, {
    required int parcellesCount,
    required double hectaresTotal,
    required int capteursCount,
    required double production3Mois,
  }) {
    final productionText = production3Mois > 0
        ? '${production3Mois.toStringAsFixed(0)} kg'
        : '--';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          value: '$parcellesCount',
                          label: 'Parcelles',
                          color: Colors.green,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: _buildStatItem(
                          value: '${hectaresTotal.toStringAsFixed(1)} ha',
                          label: 'Surface totale',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          value: productionText,
                          label: 'Production (3 mois)',
                          color: Colors.orange,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: _buildStatItem(
                          value: '$capteursCount',
                          label: 'Capteurs',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isProducer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Paramètres
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Paramètres',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                // Notifications push
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications,
                    color: Colors.green[700],
                  ),
                  title: const Text('Notifications push'),
                  value: _notificationsEnabled,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', value);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Notifications activées'
                                : 'Notifications désactivées',
                          ),
                          backgroundColor: value ? Colors.green : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                // Mode vocal
                SwitchListTile(
                  secondary: Icon(
                    _voiceModeEnabled ? Icons.mic : Icons.mic_off,
                    color: _voiceModeEnabled ? Colors.green[700] : Colors.grey,
                  ),
                  title: const Text('Mode vocal'),
                  value: _voiceModeEnabled,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    setState(() {
                      _voiceModeEnabled = value;
                    });

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('voice_mode_enabled', value);

                    final voiceService = di.sl<VoiceService>();
                    if (value) {
                      final initialized = await voiceService.initSpeech();
                      if (!initialized && mounted) {
                        setState(() {
                          _voiceModeEnabled = false;
                        });
                        await prefs.setBool('voice_mode_enabled', false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Impossible d\'activer le mode vocal. '
                              'Vérifiez les permissions du microphone.',
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      if (mounted) {
                        await voiceService.speak(
                          'Mode vocal activé. Je suis votre assistant agricole.',
                        );
                      }
                    } else {
                      await voiceService.stop();
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Mode vocal activé'
                                : 'Mode vocal désactivé',
                          ),
                          backgroundColor: value ? Colors.green : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                // Langue
                ListTile(
                  leading: Icon(Icons.language, color: Colors.green[700]),
                  title: const Text('Langue'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedLanguage,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),
          ),

          // Section Support
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phone, color: Colors.green[700]),
                  ),
                  title: const Text('Contacter le support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.menu_book, color: Colors.blue[700]),
                  ),
                  title: const Text('Guide d\'utilisation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/guide'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('🇫🇷 Français'),
              value: 'Français',
              groupValue: _selectedLanguage,
              activeColor: Colors.green,
              onChanged: (value) {
                Navigator.pop(ctx);
                _changeLanguage(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('🇬🇧 English'),
              value: 'English',
              groupValue: _selectedLanguage,
              activeColor: Colors.green,
              onChanged: (value) {
                Navigator.pop(ctx);
                _changeLanguage(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('🇨🇮 Baoulé'),
              value: 'Baoulé',
              groupValue: _selectedLanguage,
              activeColor: Colors.green,
              onChanged: (value) {
                Navigator.pop(ctx);
                _changeLanguage(value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('🇨🇮 Dioula'),
              value: 'Dioula',
              groupValue: _selectedLanguage,
              activeColor: Colors.green,
              onChanged: (value) {
                Navigator.pop(ctx);
                _changeLanguage(value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(String language) async {
    setState(() {
      _selectedLanguage = language;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Langue changée en $language'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Déconnexion'),
                content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/login');
                    },
                    child: const Text('Déconnexion'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
