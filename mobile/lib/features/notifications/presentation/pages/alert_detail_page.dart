import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/alert.dart';
import '../../../parcelles/presentation/pages/parcelle_detail_page.dart';
import '../../../parcelles/presentation/bloc/parcelle_bloc.dart';
import '../../../capteurs/presentation/pages/capteur_detail_page.dart';
import '../../../capteurs/presentation/bloc/sensor_bloc.dart';

/// Page de détail d'une alerte avec possibilité de navigation vers l'entité source
class AlertDetailPage extends StatefulWidget {
  final Alert alert;

  const AlertDetailPage({super.key, required this.alert});

  @override
  State<AlertDetailPage> createState() => _AlertDetailPageState();
}

class _AlertDetailPageState extends State<AlertDetailPage> {
  @override
  Widget build(BuildContext context) {
    final priorityColor = _getAlertPriorityColor(widget.alert.priority);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'alerte'),
        backgroundColor: priorityColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec couleur de priorité
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    _getAlertIcon(widget.alert.category),
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.alert.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatAlertPriority(widget.alert.priority),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  _buildSection(
                    title: 'Message',
                    icon: Icons.message_outlined,
                    child: Text(
                      widget.alert.message,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Informations générales
                  _buildSection(
                    title: 'Informations',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Date',
                          _formatDate(widget.alert.date),
                          Icons.calendar_today,
                        ),
                        if (widget.alert.deadlineResponse != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Échéance',
                            _formatDate(widget.alert.deadlineResponse!),
                            Icons.timer_outlined,
                            isUrgent: widget.alert.isOverdue,
                          ),
                          if (widget.alert.timeRemaining != null &&
                              !widget.alert.isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Temps restant: ${_formatDuration(widget.alert.timeRemaining!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          'Catégorie',
                          _formatCategory(widget.alert.category),
                          Icons.category_outlined,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Statut',
                          widget.alert.isRead ? 'Lu' : 'Non lu',
                          widget.alert.isRead
                              ? Icons.mark_email_read
                              : Icons.mark_email_unread,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action recommandée
                  if (widget.alert.actionRecommandee != null)
                    _buildSection(
                      title: 'Action recommandée',
                      icon: Icons.lightbulb_outline,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tips_and_updates,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.alert.actionRecommandee!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Valeurs techniques
                  if (widget.alert.valeurDeclencheur != null ||
                      widget.alert.seuilReference != null)
                    _buildSection(
                      title: 'Données techniques',
                      icon: Icons.analytics_outlined,
                      child: Row(
                        children: [
                          if (widget.alert.valeurDeclencheur != null)
                            Expanded(
                              child: _buildMetricCard(
                                'Valeur mesurée',
                                widget.alert.valeurDeclencheur!.toStringAsFixed(
                                  1,
                                ),
                                Colors.orange,
                              ),
                            ),
                          if (widget.alert.valeurDeclencheur != null &&
                              widget.alert.seuilReference != null)
                            const SizedBox(width: 16),
                          if (widget.alert.seuilReference != null)
                            Expanded(
                              child: _buildMetricCard(
                                'Seuil référence',
                                widget.alert.seuilReference!.toStringAsFixed(1),
                                Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Notifications envoyées
                  _buildSection(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNotificationBadge(
                          'SMS',
                          widget.alert.envoyeSMS,
                          Icons.sms,
                        ),
                        _buildNotificationBadge(
                          'WhatsApp',
                          widget.alert.envoyeWhatsApp,
                          Icons.chat,
                        ),
                        _buildNotificationBadge(
                          'Push',
                          widget.alert.envoyePush,
                          Icons.notifications,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Navigation vers les entités liées
                  if (widget.alert.parcelleId != null ||
                      widget.alert.sensorId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Navigation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.alert.parcelleId != null)
                          _buildNavigationCard(
                            title: widget.alert.parcelleName ?? 'Parcelle',
                            subtitle: 'Voir les détails de la parcelle',
                            icon: Icons.landscape,
                            color: Colors.green,
                            onTap: () => _navigateToParcelle(context),
                          ),
                        if (widget.alert.sensorId != null)
                          _buildNavigationCard(
                            title: 'Capteur',
                            subtitle: 'Voir les détails du capteur',
                            icon: Icons.sensors,
                            color: Colors.blue,
                            onTap: () => _navigateToSensor(context),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isUrgent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isUrgent ? Colors.red : Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isUrgent ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(String label, bool sent, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sent
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: sent ? Colors.green : Colors.grey, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: sent ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToParcelle(BuildContext context) {
    final parcelleBloc = context.read<ParcelleBloc>();
    final state = parcelleBloc.state;

    if (state is ParcelleLoaded) {
      final parcelle = state.parcelles.firstWhere(
        (p) => p.id == widget.alert.parcelleId,
        orElse: () => state.parcelles.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParcelleDetailPage(parcelle: parcelle),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement des données de la parcelle...'),
        ),
      );
      parcelleBloc.add(const LoadParcelles());
    }
  }

  void _navigateToSensor(BuildContext context) {
    final sensorBloc = context.read<SensorBloc>();
    final state = sensorBloc.state;

    if (state is SensorLoaded) {
      final sensor = state.sensors.firstWhere(
        (s) => s.id == widget.alert.sensorId,
        orElse: () => state.sensors.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CapteurDetailPage(capteur: sensor),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chargement des données du capteur...')),
      );
      sensorBloc.add(const LoadSensors());
    }
  }

  Color _getAlertPriorityColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.haute:
        return Colors.red;
      case AlertPriority.moyenne:
        return Colors.orange;
      case AlertPriority.basse:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertCategory category) {
    switch (category) {
      case AlertCategory.irrigation:
        return Icons.water_drop;
      case AlertCategory.maladie:
        return Icons.bug_report;
      case AlertCategory.meteo:
        return Icons.cloud;
      case AlertCategory.sol:
        return Icons.grass;
      case AlertCategory.maintenance:
        return Icons.build;
      case AlertCategory.commande:
        return Icons.shopping_cart;
      case AlertCategory.general:
        return Icons.info;
    }
  }

  String _formatAlertPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.haute:
        return 'Priorité Haute';
      case AlertPriority.moyenne:
        return 'Priorité Moyenne';
      case AlertPriority.basse:
        return 'Priorité Basse';
    }
  }

  String _formatCategory(AlertCategory category) {
    switch (category) {
      case AlertCategory.irrigation:
        return 'Irrigation';
      case AlertCategory.maladie:
        return 'Maladie';
      case AlertCategory.meteo:
        return 'Météo';
      case AlertCategory.sol:
        return 'Sol';
      case AlertCategory.maintenance:
        return 'Maintenance';
      case AlertCategory.commande:
        return 'Commande';
      case AlertCategory.general:
        return 'Général';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}
