import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/presentation/pages/capteur_detail_page.dart';
import 'package:agriculture/features/capteurs/presentation/pages/npk_detail_page_v2.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:agriculture/features/parcelles/presentation/pages/parcelle_detail_page.dart';
import 'package:agriculture/features/notifications/presentation/bloc/alert_bloc.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/notifications/presentation/pages/alert_detail_page.dart';
import 'package:agriculture/features/capteurs/presentation/utils/sensor_insights.dart';

class CapteursPage extends StatefulWidget {
  const CapteursPage({super.key});

  @override
  State<CapteursPage> createState() => _CapteursPageState();
}

class _CapteursPageState extends State<CapteursPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  void _loadAllData() {
    context.read<SensorBloc>().add(const LoadSensors());
    context.read<ParcelleBloc>().add(const LoadParcelles());
    context.read<AlertBloc>().add(const LoadAlerts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParcellesTab(),
                _buildCapteursTab(),
                _buildAlertesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monitoring IoT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Surveillance en temps réel",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadAllData,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.landscape, size: 20), text: 'Parcelles'),
              Tab(icon: Icon(Icons.sensors, size: 20), text: 'Capteurs'),
              Tab(icon: Icon(Icons.warning_amber, size: 20), text: 'Alertes'),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // TAB 1: Parcelles avec capteurs et métriques IoT
  // ──────────────────────────────────────────────────────────────
  Widget _buildParcellesTab() {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, parcelleState) {
        return BlocBuilder<SensorBloc, SensorState>(
          builder: (context, sensorState) {
            if (parcelleState is ParcelleLoading ||
                sensorState is SensorLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (parcelleState is ParcelleError) {
              return _buildErrorWidget(parcelleState.message, () {
                context.read<ParcelleBloc>().add(const LoadParcelles());
              });
            }

            List<Parcelle> parcelles = [];
            List<Sensor> allSensors = [];

            if (parcelleState is ParcelleLoaded) {
              parcelles = parcelleState.parcelles;
            }
            if (sensorState is SensorLoaded) {
              allSensors = sensorState.sensors;
            }

            if (parcelles.isEmpty) {
              return _buildEmptyWidget(
                icon: Icons.landscape_outlined,
                title: 'Aucune parcelle',
                subtitle: 'Vous n\'avez pas encore de parcelles enregistrées',
              );
            }

            // Group sensors by parcelle name
            final Map<String, List<Sensor>> sensorsByParcelle = {};
            for (var s in allSensors) {
              final key = s.parcelleNom ?? "Non assigné";
              sensorsByParcelle.putIfAbsent(key, () => []).add(s);
            }

            return RefreshIndicator(
              onRefresh: () async => _loadAllData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: parcelles.length,
                itemBuilder: (context, index) {
                  final parcelle = parcelles[index];
                  final sensors = sensorsByParcelle[parcelle.nom] ?? [];
                  return _buildParcelleMonitoringCard(parcelle, sensors);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParcelleMonitoringCard(Parcelle parcelle, List<Sensor> sensors) {
    // Determine health status
    bool hasCritical = sensors.any(
      (s) =>
          s.status == 'critical' ||
          s.status == 'defaillant' ||
          s.status == 'erreur',
    );
    bool hasWarning =
        !hasCritical &&
        sensors.any((s) => s.status == 'warning' || s.status == 'maintenance');
    Color statusColor = hasCritical
        ? Colors.red
        : (hasWarning ? Colors.orange : Colors.green);
    String statusText = hasCritical
        ? 'Critique'
        : (hasWarning ? 'Attention' : 'Normal');

    // Get metric values from sensors
    String temperature = '--';
    String humidity = '--';
    String ph = '--';
    String npk = '--';

    for (var sensor in sensors) {
      final type = sensor.type.toLowerCase();
      if (type.contains('temperature') || type.contains('température')) {
        temperature = sensor.lastValue != null
            ? '${sensor.lastValue!.toStringAsFixed(1)}°C'
            : '--°C';
      } else if (type.contains('humid') || type.contains('humidité')) {
        humidity = sensor.lastValue != null
            ? '${sensor.lastValue!.toStringAsFixed(1)}%'
            : '--%';
      } else if (type.contains('ph')) {
        ph = sensor.lastValue != null
            ? 'pH ${sensor.lastValue!.toStringAsFixed(1)}'
            : 'pH --';
      } else if (type.contains('npk') || type.contains('nutriment')) {
        if (sensor.nitrogen != null) {
          npk = 'N:${sensor.nitrogen!.toStringAsFixed(0)}';
        } else {
          npk = sensor.lastValue != null
              ? sensor.lastValue!.toStringAsFixed(1)
              : '--';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Parcelle header - clickable to detail
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParcelleDetailPage(parcelle: parcelle),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.landscape,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcelle.nom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${parcelle.culture} • ${parcelle.typeSol} • ${parcelle.superficie.toStringAsFixed(2)} ha',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),

          // Metrics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricChip(
                  Icons.thermostat,
                  temperature,
                  Colors.redAccent,
                ),
                _buildMetricChip(Icons.water_drop, humidity, Colors.blue),
                _buildMetricChip(Icons.flash_on, ph, Colors.orange),
                _buildMetricChip(Icons.eco, npk, Colors.green),
              ],
            ),
          ),

          // Sensor list for this parcelle
          if (sensors.isNotEmpty) ...[
            Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.sensors, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${sensors.length} capteur${sensors.length > 1 ? 's' : ''} connecté${sensors.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            ...sensors.map((sensor) => _buildSensorRow(sensor)),
            const SizedBox(height: 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucun capteur connecté',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(Sensor sensor) {
    final isActive = sensor.status == 'actif' || sensor.status == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    final colorScheme = Theme.of(context).colorScheme;
    final insight = getSensorInsight(sensor);

    return InkWell(
      onTap: () {
        if (sensor.type.toLowerCase().contains('npk')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NpkDetailPageV2(capteur: sensor)),
          ).then((_) => _loadAllData());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CapteurDetailPage(capteur: sensor),
            ),
          ).then((_) => _loadAllData());
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getSensorIcon(sensor.type),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(fontSize: 11, color: statusColor),
                      ),
                      const SizedBox(width: 8),
                      _buildBatteryIndicator(sensor.niveauBatterie),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: insight.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (sensor.lastValue != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sensor.lastValue!.toStringAsFixed(1)}${sensor.unit ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // TAB 2: Tous les capteurs
  // ──────────────────────────────────────────────────────────────
  Widget _buildCapteursTab() {
    return BlocBuilder<SensorBloc, SensorState>(
      builder: (context, state) {
        if (state is SensorLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SensorError) {
          return _buildErrorWidget(state.message, () {
            context.read<SensorBloc>().add(const LoadSensors());
          });
        }

        if (state is SensorLoaded) {
          final sensors = state.sensors;
          if (sensors.isEmpty) {
            return _buildEmptyWidget(
              icon: Icons.sensors_off,
              title: 'Aucun capteur',
              subtitle:
                  'Connectez vos capteurs IoT pour commencer le monitoring',
            );
          }

          final activeSensors = sensors
              .where((s) => s.status == 'actif' || s.status == 'active')
              .toList();
          final inactiveSensors = sensors
              .where((s) => s.status != 'actif' && s.status != 'active')
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SensorBloc>().add(const LoadSensors());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSensorSummaryCard(sensors),
                const SizedBox(height: 20),
                if (activeSensors.isNotEmpty) ...[
                  _buildSectionLabel(
                    'Actifs (${activeSensors.length})',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  ...activeSensors.map((s) => _buildSensorDetailCard(s)),
                  const SizedBox(height: 20),
                ],
                if (inactiveSensors.isNotEmpty) ...[
                  _buildSectionLabel(
                    'Inactifs (${inactiveSensors.length})',
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  ...inactiveSensors.map((s) => _buildSensorDetailCard(s)),
                ],
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSensorSummaryCard(List<Sensor> sensors) {
    final active = sensors
        .where((s) => s.status == 'actif' || s.status == 'active')
        .length;
    final inactive = sensors.length - active;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${sensors.length}', 'Total', Icons.sensors),
          _buildSummaryItem('$active', 'Actifs', Icons.check_circle),
          _buildSummaryItem('$inactive', 'Inactifs', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSensorDetailCard(Sensor sensor) {
    final isActive = sensor.status == 'actif' || sensor.status == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;
    final insight = getSensorInsight(sensor);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (sensor.type.toLowerCase().contains('npk')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NpkDetailPageV2(capteur: sensor),
              ),
            ).then((_) => _loadAllData());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CapteurDetailPage(capteur: sensor),
              ),
            ).then((_) => _loadAllData());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getSensorIcon(sensor.type),
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sensor.type} • ${sensor.parcelleNom ?? "Non assigné"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.insights, size: 13, color: insight.color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            insight.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: insight.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildBatteryIndicator(sensor.niveauBatterie),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.wifi,
                          size: 14,
                          color: _getSignalColor(sensor.signalForce),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sensor.signalForce,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (sensor.lastValue != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${sensor.lastValue!.toStringAsFixed(1)}${sensor.unit ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator(double level) {
    Color batteryColor;
    IconData batteryIcon;
    if (level > 60) {
      batteryColor = Colors.green;
      batteryIcon = Icons.battery_full;
    } else if (level > 30) {
      batteryColor = Colors.orange;
      batteryIcon = Icons.battery_3_bar;
    } else {
      batteryColor = Colors.red;
      batteryIcon = Icons.battery_1_bar;
    }
    return Row(
      children: [
        Icon(batteryIcon, size: 14, color: batteryColor),
        const SizedBox(width: 2),
        Text(
          '${level.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: batteryColor),
        ),
      ],
    );
  }

  Color _getSignalColor(String signal) {
    switch (signal.toLowerCase()) {
      case 'fort':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'faible':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // TAB 3: Alertes
  // ──────────────────────────────────────────────────────────────
  Widget _buildAlertesTab() {
    return BlocBuilder<AlertBloc, AlertState>(
      builder: (context, state) {
        if (state is AlertLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AlertError) {
          return _buildErrorWidget(state.message, () {
            context.read<AlertBloc>().add(const LoadAlerts());
          });
        }

        if (state is AlertLoaded) {
          final alerts = state.alerts;
          if (alerts.isEmpty) {
            return _buildEmptyWidget(
              icon: Icons.check_circle_outline,
              title: 'Aucune alerte',
              subtitle: 'Tout va bien ! Aucune alerte à signaler.',
            );
          }

          // Sort by priority then date
          final sortedAlerts = List<Alert>.from(alerts);
          sortedAlerts.sort((a, b) {
            final priorityOrder = {
              AlertPriority.haute: 0,
              AlertPriority.moyenne: 1,
              AlertPriority.basse: 2,
            };
            final cmp = (priorityOrder[a.priority] ?? 2).compareTo(
              priorityOrder[b.priority] ?? 2,
            );
            if (cmp != 0) return cmp;
            return b.date.compareTo(a.date);
          });

          final critical = sortedAlerts
              .where((a) => a.priority == AlertPriority.haute)
              .length;
          final warning = sortedAlerts
              .where((a) => a.priority == AlertPriority.moyenne)
              .length;
          final info = sortedAlerts
              .where((a) => a.priority == AlertPriority.basse)
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AlertBloc>().add(const LoadAlerts());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAlertSummaryCard(critical, warning, info),
                const SizedBox(height: 16),
                ...sortedAlerts.map((a) => _buildAlertCard(a)),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAlertSummaryCard(int critical, int warning, int info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAlertCountBadge(critical, 'Critiques', Colors.red),
          _buildAlertCountBadge(warning, 'Moyennes', Colors.orange),
          _buildAlertCountBadge(info, 'Infos', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAlertCountBadge(int count, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final priorityColor = _getAlertPriorityColor(alert.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: priorityColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlertDetailPage(alert: alert),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAlertIcon(alert.category),
                  color: priorityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatAlertPriority(alert.priority),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (alert.parcelleName != null)
                          Row(
                            children: [
                              Icon(
                                Icons.landscape,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                alert.parcelleName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        if (!alert.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  IconData _getSensorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
      case 'température':
        return Icons.thermostat;
      case 'humidity':
      case 'humidité':
      case 'humidite':
        return Icons.water_drop;
      case 'soil':
      case 'sol':
        return Icons.grass;
      case 'light':
      case 'lumière':
        return Icons.light_mode;
      case 'ph':
        return Icons.science;
      case 'npk':
        return Icons.eco;
      default:
        return Icons.sensors;
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
        return Icons.water;
      case AlertCategory.maladie:
        return Icons.bug_report;
      case AlertCategory.meteo:
        return Icons.thunderstorm;
      case AlertCategory.sol:
        return Icons.grass;
      case AlertCategory.maintenance:
        return Icons.build;
      case AlertCategory.commande:
        return Icons.shopping_bag;
      case AlertCategory.general:
        return Icons.warning_amber;
    }
  }

  String _formatAlertPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.haute:
        return 'Haute';
      case AlertPriority.moyenne:
        return 'Moyenne';
      case AlertPriority.basse:
        return 'Basse';
    }
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Erreur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
