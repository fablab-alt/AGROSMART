import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:agriculture/core/theme/theme_cubit.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/parcelles/presentation/pages/parcelle_detail_page.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/notifications/presentation/bloc/alert_bloc.dart';
import 'package:agriculture/features/notifications/presentation/pages/alert_detail_page.dart';
import 'package:agriculture/features/capteurs/presentation/pages/capteur_detail_page.dart';
import 'package:agriculture/features/capteurs/presentation/pages/npk_detail_page_v2.dart';
import 'package:agriculture/features/weather/domain/entities/weather.dart';
import 'package:agriculture/features/weather/presentation/bloc/weather_bloc.dart';

/// Page de monitoring qui consolide toutes les informations agricoles
/// - Parcelles avec leurs détails
/// - Capteurs et données IoT
/// - Alertes et notifications
/// - Météo et prévisions
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  void _loadAllData() {
    context.read<ParcelleBloc>().add(const LoadParcelles());
    context.read<SensorBloc>().add(const LoadSensors());
    context.read<AlertBloc>().add(const LoadAlerts());
    // Note: WeatherBloc needs coordinates, will load on weather tab tap
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isDarkMode() {
    final themeState = context.watch<ThemeCubit>().state;
    return themeState == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitoring IoT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Surveillance en temps réel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.landscape), text: 'Parcelles'),
                    Tab(icon: Icon(Icons.sensors), text: 'Capteurs'),
                    Tab(icon: Icon(Icons.warning_amber), text: 'Alertes'),
                    Tab(icon: Icon(Icons.cloud), text: 'Météo'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParcellesTab(isDark, colorScheme),
                _buildCapteursTab(isDark, colorScheme),
                _buildAlertesTab(isDark, colorScheme),
                _buildMeteoTab(isDark, colorScheme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'monitoring_refresh_fab',
        onPressed: _loadAllData,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildParcellesTab(bool isDark, ColorScheme colorScheme) {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ParcelleError) {
          return _buildErrorWidget(state.message, () {
            context.read<ParcelleBloc>().add(const LoadParcelles());
          });
        }

        if (state is ParcelleLoaded) {
          final parcelles = state.parcelles;
          if (parcelles.isEmpty) {
            return _buildEmptyWidget(
              icon: Icons.landscape_outlined,
              title: 'Aucune parcelle',
              subtitle: 'Vous n\'avez pas encore de parcelles enregistrées',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ParcelleBloc>().add(const LoadParcelles());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parcelles.length,
              itemBuilder: (context, index) {
                final parcelle = parcelles[index];
                return _buildParcelleCard(parcelle, isDark, colorScheme);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildParcelleCard(
    Parcelle parcelle,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.landscape, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcelle.nom,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${parcelle.superficie.toStringAsFixed(2)} ha • ${parcelle.cultureActuelle?.nom ?? parcelle.cultureLegacy ?? 'Non défini'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.thermostat,
                    label: 'Température',
                    value: '--°C',
                    color: Colors.orange,
                  ),
                  _buildStatItem(
                    icon: Icons.water_drop,
                    label: 'Humidité',
                    value: '--%',
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.eco,
                    label: 'Sol',
                    value: 'Bon',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCapteursTab(bool isDark, ColorScheme colorScheme) {
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SensorBloc>().add(const LoadSensors());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return _buildSensorCard(sensor, isDark, colorScheme);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSensorCard(Sensor sensor, bool isDark, ColorScheme colorScheme) {
    final isActive = sensor.status == 'actif' || sensor.status == 'active';
    final statusColor = isActive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (sensor.type.toLowerCase().contains('npk')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NpkDetailPageV2(capteur: sensor),
              ),
            ).then((_) => _loadAllData());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CapteurDetailPage(capteur: sensor),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSensorIcon(sensor.type),
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.nom,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${sensor.type}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.battery_full,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${sensor.niveauBatterie.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (sensor.lastValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sensor.lastValue!.toStringAsFixed(1)}${sensor.unit ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSensorIcon(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
      case 'température':
        return Icons.thermostat;
      case 'humidity':
      case 'humidité':
        return Icons.water_drop;
      case 'soil':
      case 'sol':
        return Icons.grass;
      case 'light':
      case 'lumière':
        return Icons.light_mode;
      case 'ph':
        return Icons.science;
      default:
        return Icons.sensors;
    }
  }

  Widget _buildAlertesTab(bool isDark, ColorScheme colorScheme) {
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

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AlertBloc>().add(const LoadAlerts());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(alert, isDark, colorScheme);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAlertCard(Alert alert, bool isDark, ColorScheme colorScheme) {
    final priorityColor = _getAlertPriorityColor(alert.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAlertIcon(alert.category),
                      color: priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatAlertPriority(alert.priority),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(alert.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nouveau',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              if (alert.actionRecommandee != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.actionRecommandee!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Navigation indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Voir détails',
                    style: TextStyle(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: priorityColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatAlertPriority(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.haute:
        return 'Priorité haute';
      case AlertPriority.moyenne:
        return 'Priorité moyenne';
      case AlertPriority.basse:
        return 'Priorité basse';
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

  Widget _buildMeteoTab(bool isDark, ColorScheme colorScheme) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is WeatherError) {
          return _buildErrorWidget(state.message, () {
            // Reload weather with default coords (Abidjan)
            context.read<WeatherBloc>().add(
              LoadWeatherForecast(
                latitude: 5.3600,
                longitude: -4.0083,
                location: 'Abidjan',
              ),
            );
          });
        }

        if (state is WeatherForecastLoaded) {
          final forecasts = state.forecasts;
          if (forecasts.isEmpty) {
            return _buildEmptyWidget(
              icon: Icons.cloud_off,
              title: 'Aucune donnée météo',
              subtitle: 'Les prévisions météo ne sont pas disponibles',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WeatherBloc>().add(
                LoadWeatherForecast(
                  latitude: 5.3600,
                  longitude: -4.0083,
                  location: 'Abidjan',
                ),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: forecasts.length,
              itemBuilder: (context, index) {
                final forecast = forecasts[index];
                return _buildWeatherCard(forecast, isDark, colorScheme);
              },
            ),
          );
        }

        // Initial state - show button to load weather
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_outlined,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Prévisions météo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Chargez les prévisions pour votre région',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<WeatherBloc>().add(
                    LoadWeatherForecast(
                      latitude: 5.3600,
                      longitude: -4.0083,
                      location: 'Abidjan',
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download),
                label: const Text('Charger les prévisions'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherCard(
    WeatherForecast forecast,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getWeatherIcon(forecast.conditionMeteo),
                  size: 48,
                  color: _getWeatherColor(forecast.conditionMeteo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(forecast.date),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        forecast.conditionMeteo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${forecast.temperatureMax.toStringAsFixed(0)}°',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                    ),
                    Text(
                      '${forecast.temperatureMin.toStringAsFixed(0)}°',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  icon: Icons.water_drop,
                  label: 'Humidité',
                  value: '${forecast.humidite}%',
                  color: Colors.blue,
                ),
                _buildWeatherDetail(
                  icon: Icons.air,
                  label: 'Vent',
                  value: '${forecast.vitesseVent.toStringAsFixed(0)} km/h',
                  color: Colors.grey,
                ),
                _buildWeatherDetail(
                  icon: Icons.umbrella,
                  label: 'Pluie',
                  value:
                      '${(forecast.precipitationProbabilite * 100).toStringAsFixed(0)}%',
                  color: Colors.indigo,
                ),
              ],
            ),
            if (forecast.hasAlert) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alerte: ${forecast.alertType ?? "Conditions météo"}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('soleil') ||
        lowerCondition.contains('ensoleill')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('nuage')) {
      return Icons.cloud;
    } else if (lowerCondition.contains('pluv') ||
        lowerCondition.contains('pluie')) {
      return Icons.water_drop;
    } else if (lowerCondition.contains('orage')) {
      return Icons.thunderstorm;
    }
    return Icons.cloud;
  }

  Color _getWeatherColor(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('soleil') ||
        lowerCondition.contains('ensoleill')) {
      return Colors.orange;
    } else if (lowerCondition.contains('pluv') ||
        lowerCondition.contains('pluie')) {
      return Colors.blue;
    } else if (lowerCondition.contains('orage')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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
            Text('Erreur', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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
            Icon(
              icon,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
