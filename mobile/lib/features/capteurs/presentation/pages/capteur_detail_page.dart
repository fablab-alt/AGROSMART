import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';
import '../../domain/entities/sensor.dart';
import '../widgets/sensor_history_chart.dart';
import '../utils/sensor_insights.dart';
import '../../../../injection_container.dart' as di;

class CapteurDetailPage extends StatefulWidget {
  final Sensor capteur;

  const CapteurDetailPage({super.key, required this.capteur});

  @override
  State<CapteurDetailPage> createState() => _CapteurDetailPageState();
}

class _CapteurDetailPageState extends State<CapteurDetailPage> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final statusLower = widget.capteur.status.toLowerCase();
    _isActive = statusLower == 'actif' || statusLower == 'active';
  }

  void _toggleSensorStatus() {
    final newStatus = _isActive ? 'INACTIF' : 'ACTIF';

    debugPrint('[CAPTEUR_DETAIL] Toggle sensor: ${widget.capteur.id}');
    debugPrint('[CAPTEUR_DETAIL] Current status: ${widget.capteur.status}');
    debugPrint('[CAPTEUR_DETAIL] New status: $newStatus');

    // Appeler l'API pour activer/désactiver le capteur
    context.read<SensorBloc>().add(
      ToggleSensorStatus(widget.capteur.id, newStatus),
    );

    // Mettre à jour l'état local pour un feedback immédiat
    setState(() {
      _isActive = !_isActive;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isActive
              ? 'Capteur ${widget.capteur.nom} activé'
              : 'Capteur ${widget.capteur.nom} désactivé',
        ),
        backgroundColor: _isActive ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSensorMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _isActive ? Icons.pause_circle : Icons.play_circle,
                color: _isActive ? Colors.orange : Colors.green,
              ),
              title: Text(
                _isActive ? 'Désactiver le capteur' : 'Activer le capteur',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleSensorStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Calibrer le capteur'),
              onTap: () {
                Navigator.pop(context);
                _calibrateSensor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.purple),
              title: const Text('Configurer les seuils'),
              onTap: () {
                Navigator.pop(context);
                _configureThresholds();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer le capteur'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _calibrateSensor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.blue),
            SizedBox(width: 8),
            Text('Calibrer le capteur'),
          ],
        ),
        content: const Text(
          'Le processus de calibration va réinitialiser les valeurs de référence du capteur. Cela peut prendre quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calibration en cours...'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _configureThresholds() {
    // TODO: Implémenter la configuration des seuils
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration des seuils à venir...')),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le capteur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le capteur "${widget.capteur.nom}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Retourner à la liste
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Capteur supprimé'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = getSensorInsight(widget.capteur);

    return BlocProvider(
      create: (_) =>
          di.sl<SensorBloc>()..add(LoadSensorHistory(widget.capteur.id)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.capteur.nom),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showSensorMenu,
              tooltip: 'Options',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        _getTypeIcon(widget.capteur.type),
                        size: 64,
                        color: _getTypeColor(widget.capteur.type),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.capteur.lastValue?.toStringAsFixed(1) ?? '--'} ${widget.capteur.unit ?? getUnite(widget.capteur.type)}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(widget.capteur.type),
                        ),
                      ),
                      Text(
                        widget.capteur.nom,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusBadge(_isActive ? 'ACTIVE' : 'INACTIVE'),
                      const SizedBox(height: 16),
                      // Bouton d'activation/désactivation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleSensorStatus,
                          icon: Icon(
                            _isActive ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_isActive ? 'Désactiver' : 'Activer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isActive
                                ? Colors.orange
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Interprétation terrain
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: insight.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: insight.color.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights, color: insight.color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lecture terrain • ${insight.label}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: insight.color,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(insight.message, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      'Conseil: ${insight.recommendation}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // History Chart
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Historique',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                  child: BlocBuilder<SensorBloc, SensorState>(
                    builder: (context, state) {
                      if (state is SensorLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is SensorHistoryLoaded) {
                        if (state.history.isEmpty) {
                          return const Center(
                            child: Text('Aucune donnée disponible'),
                          );
                        }
                        return SensorHistoryChart(
                          data: _mapHistoryToChart(state.history),
                          color: _getTypeColor(widget.capteur.type),
                          unit:
                              widget.capteur.unit ??
                              getUnite(widget.capteur.type),
                        );
                      } else if (state is SensorError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Info Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildGridItem(
                    Icons.battery_full,
                    '${widget.capteur.niveauBatterie.toStringAsFixed(0)}%',
                    'Batterie',
                  ),
                  _buildGridItem(
                    Icons.location_on,
                    widget.capteur.parcelleNom ?? 'Non assigné',
                    'Localisation',
                  ),
                  _buildGridItem(
                    Icons.update,
                    _formatDate(widget.capteur.lastUpdate),
                    'Mise à jour',
                  ),
                  _buildGridItem(
                    Icons.wifi,
                    widget.capteur.signalForce,
                    'Signal',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ChartDataPoint> _mapHistoryToChart(List<SensorMeasure> history) {
    if (history.isEmpty) return [];
    // Sort by timestamp asc
    history.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Take last 20 points if too many
    final points = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    return points
        .map(
          (m) => ChartDataPoint(
            '${m.timestamp.day}/${m.timestamp.month} ${m.timestamp.hour}h',
            m.value,
          ),
        )
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String getUnite(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('temp')) return '°C';
    if (normalized.contains('humid')) return '%';
    if (normalized.contains('ph')) return 'pH';
    if (normalized.contains('uv')) return 'UV';
    return '';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status.toLowerCase().contains('actif') ||
        status.toLowerCase() == 'normal') {
      color = Colors.green;
    } else if (status.toLowerCase().contains('warning')) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'humidite':
        return Colors.blue;
      case 'temperature':
        return Colors.orange;
      case 'ph':
        return Colors.purple;
      case 'npk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'humidite':
        return Icons.water_drop;
      case 'temperature':
        return Icons.thermostat;
      case 'ph':
        return Icons.science;
      case 'npk':
        return Icons.eco;
      default:
        return Icons.sensors;
    }
  }
}
