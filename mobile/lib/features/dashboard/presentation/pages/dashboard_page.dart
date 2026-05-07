import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/weather/presentation/bloc/weather_bloc.dart';
import 'package:agriculture/features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'package:agriculture/features/notifications/presentation/bloc/alert_bloc.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/core/theme/theme_cubit.dart';
import 'package:agriculture/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:agriculture/features/recommandations/presentation/bloc/recommandation_bloc.dart';
import 'package:agriculture/injection_container.dart' as di;
import 'package:agriculture/core/services/location_service.dart';
import 'package:agriculture/core/widgets/voice_assistant_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Coordonnées par défaut (Abidjan)
  double _lat = 5.3600;
  double _lon = -4.0083;
  int _selectedParcelleIndex = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Load initial data
    context.read<ParcelleBloc>().add(LoadParcelles());
    context.read<SensorBloc>().add(LoadSensors());
    context.read<AlertBloc>().add(LoadAlerts());
    context.read<RecommandationBloc>().add(LoadRecommandations());
  }

  Future<void> _initLocation() async {
    try {
      final position = await di.sl<LocationService>().determinePosition();
      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
      });
      if (mounted) {
        context.read<WeatherBloc>().add(
          LoadWeatherForecast(latitude: _lat, longitude: _lon),
        );
      }
    } catch (e) {
      debugPrint("Erreur localisation: $e");
      if (mounted) {
        context.read<WeatherBloc>().add(
          LoadWeatherForecast(latitude: _lat, longitude: _lon),
        );
      }
    }
  }

  // Refresh function
  Future<void> _onRefresh() async {
    context.read<ParcelleBloc>().add(LoadParcelles());
    context.read<SensorBloc>().add(LoadSensors());
    context.read<AlertBloc>().add(LoadAlerts());
    context.read<AnalyticsBloc>().add(LoadAnalytics());
    context.read<RecommandationBloc>().add(LoadRecommandations());
    context.read<WeatherBloc>().add(
      LoadWeatherForecast(latitude: _lat, longitude: _lon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            String userName = "Producteur";
            if (authState is AuthAuthenticated) {
              // Handle nullable fields safely
              if (authState.user.prenoms.isNotEmpty) {
                userName = authState.user.prenoms;
              } else {
                userName = authState.user.nom;
              }
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(userName),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recommandations en premier (prioritaire)
                        _buildSectionTitle("Recommandations"),
                        const SizedBox(height: 12),
                        _buildRecommandationsSection(),

                        const SizedBox(height: 24),
                        _buildSectionTitle("Vue d'ensemble"),
                        const SizedBox(height: 12),
                        _buildOverviewCards(),

                        const SizedBox(height: 24),
                        _buildSectionTitle("Mes parcelles"),
                        const SizedBox(height: 12),
                        _buildParcelleSelector(),
                        const SizedBox(height: 16),
                        _buildParcelleDetailCard(),

                        const SizedBox(height: 24),
                        _buildQuickActionsHeader(),
                        const SizedBox(height: 12),
                        _buildActionButtons(context),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: VoiceAssistantButton(
        onResult: (text) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Commande vocale : $text')));
        },
      ),
      // Note: La navigation principale est gérée par MainShellPage
      // Ne pas ajouter de bottomNavigationBar ici pour éviter la superposition
    );
  }

  Widget _buildHeader(String userName) {
    // Current Date Logic
    final now = DateTime.now();
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final dateStr =
        "${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF28A745),
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
              Text(
                "Bonjour, $userName!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        context.read<ThemeCubit>().state == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        final cubit = context.read<ThemeCubit>();
                        cubit.setTheme(
                          cubit.state == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        );
                      },
                    ),
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => context.push('/notifications'),
                      ),
                      BlocBuilder<AlertBloc, AlertState>(
                        builder: (context, state) {
                          if (state is AlertLoaded && state.alerts.isNotEmpty) {
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${state.alerts.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildWeatherCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        String temp = "--°C";
        String condition = "Chargement...";

        if (state is WeatherForecastLoaded && state.forecasts.isNotEmpty) {
          final current = state.forecasts.first;
          temp = "${current.temperatureMoyenne.round()}°C";
          condition = current.conditionMeteo;
        }

        return GestureDetector(
          onTap: () => context.push('/weather'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.2,
              ), // Keep transparent white as it's over green header
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Météo aujourd'hui",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$temp - $condition",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Icon(_getWeatherIcon(condition), color: Colors.white, size: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    // Basic mapping - can be expanded or shared
    final lower = condition.toLowerCase();
    if (lower.contains('ensoleillé') || lower.contains('soleil'))
      return Icons.wb_sunny;
    if (lower.contains('nuage') || lower.contains('couvert'))
      return Icons.cloud;
    if (lower.contains('pluie') || lower.contains('averse'))
      return Icons.water_drop;
    if (lower.contains('orage')) return Icons.thunderstorm;
    if (lower.contains('neige')) return Icons.ac_unit;
    if (lower.contains('brouillard')) return Icons.foggy;
    return Icons.wb_cloudy;
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOverviewCards() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Card 1: Parcelles
          BlocBuilder<ParcelleBloc, ParcelleState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType ||
                (previous is ParcelleLoaded &&
                    current is ParcelleLoaded &&
                    previous.parcelles.length != current.parcelles.length),
            builder: (context, state) {
              int count = 0;
              if (state is ParcelleLoaded) {
                count = state.parcelles.length;
              }
              return _buildInfoCard(
                title: "Parcelles\nactives",
                value: "$count",
                icon: Icons.map_outlined,
                color: const Color(0xFF28A745),
                onTap: () => context.push('/parcelles'),
              );
            },
          ),
          const SizedBox(width: 12),
          // Card 2: Rendement
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType,
            builder: (context, state) {
              String rendement = "N/A";
              bool isPrediction = false;
              if (state is AnalyticsLoaded) {
                rendement = state.data.rendementData.value;
                isPrediction = state.data.rendementData.isPrediction;
              }
              return _buildInfoCard(
                title: isPrediction
                    ? "Rendement\nestimé (IA)"
                    : "Rendement\nmoyen",
                value: rendement,
                icon: isPrediction ? Icons.auto_awesome : Icons.trending_up,
                color: const Color(0xFFFFC107),
                isYellow: true,
                onTap: () => context.push('/analytics'),
              );
            },
          ),
          const SizedBox(width: 12),
          // Card 3: Capteurs / Monitoring
          BlocBuilder<SensorBloc, SensorState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType ||
                (previous is SensorLoaded &&
                    current is SensorLoaded &&
                    previous.sensors.length != current.sensors.length),
            builder: (context, state) {
              int count = 0;
              if (state is SensorLoaded) {
                count = state.sensors
                    .where(
                      (s) =>
                          s.status.toLowerCase() == 'actif' ||
                          s.status.toLowerCase() == 'active',
                    )
                    .length;
              }
              return _buildInfoCard(
                title: "Capteurs\nactifs",
                value: "$count",
                icon: Icons.sensors,
                color: const Color(0xFF2196F3),
                onTap: () => context.push('/capteurs'),
              );
            },
          ),
          const SizedBox(width: 12),
          // Card 4: Alertes
          BlocBuilder<AlertBloc, AlertState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType ||
                (previous is AlertLoaded &&
                    current is AlertLoaded &&
                    previous.alerts.length != current.alerts.length),
            builder: (context, state) {
              int count = 0;
              if (state is AlertLoaded) {
                count = state.alerts.length;
              }
              return _buildInfoCard(
                title: "Alertes\nactives",
                value: "$count",
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFD32F2F),
                onTap: () => context.push('/notifications'),
              );
            },
          ),
          const SizedBox(width: 12),
          // Card 5: Economies
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType,
            builder: (context, state) {
              String value = "0 FCFA";
              if (state is AnalyticsLoaded) {
                // Format with simple K/M suffix if needed, for now just toString
                value = "${state.data.economies.total.toStringAsFixed(0)} F";
              }
              return _buildInfoCard(
                title: "Economies\nréalisées",
                value: value,
                icon: Icons.savings_outlined,
                color: const Color(0xFF8E24AA), // Purple
                onTap: () => context.push('/analytics'),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isYellow = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark
        ? (isYellow
              ? const Color(0xFFFFD54F)
              : const Color(0xFF81C784)) // Lighter for Dark Mode
        : (isYellow
              ? Colors.orange[800]
              : Colors.green[800]); // Darker for Light Mode

    // Accessibilité: description pour lecteurs d'écran
    final semanticLabel = '${title.replaceAll('\n', ' ')}: $value';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.5 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color, size: 24, semanticLabel: null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelleSelector() {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoaded && state.parcelles.isNotEmpty) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(state.parcelles.length, (index) {
                final isSelected = index == _selectedParcelleIndex;
                final parcelle = state.parcelles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedParcelleIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF28A745)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF28A745,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        parcelle.nom.isNotEmpty
                            ? parcelle.nom
                            : "Parcelle ${index + 1}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Aucune parcelle enregistrée",
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildParcelleDetailCard() {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoaded && state.parcelles.isNotEmpty) {
          if (_selectedParcelleIndex >= state.parcelles.length) {
            _selectedParcelleIndex = 0;
          }
          final parcelle = state.parcelles[_selectedParcelleIndex];
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // Logic for status style
          Color statusColor;
          Color statusBgColor;
          String statusText;
          String description;
          Color dotColor;

          // Mapping logic for health status
          // Note: ParcelleHealth is an Enum in domain/entities/parcelle.dart
          // We need robust checking.
          final santeStr = parcelle.sante
              .toString()
              .split('.')
              .last
              .toLowerCase();

          if (santeStr == 'optimal') {
            statusColor = isDark
                ? const Color(0xFF81C784)
                : const Color(0xFF28A745);
            statusBgColor = isDark
                ? const Color(0xFF1B5E20).withOpacity(0.3)
                : const Color(0xFFE8F5E9);
            statusText = "Optimal";
            description =
                "Tout est nickel ! Le sol est en bonne santé, les plantes poussent bien.";
            dotColor = Colors.green;
          } else if (santeStr == 'critique') {
            statusColor = isDark
                ? const Color(0xFFE57373)
                : const Color(0xFFDC3545);
            statusBgColor = isDark
                ? const Color(0xFFB71C1C).withOpacity(0.3)
                : const Color(0xFFFFEBEE);
            statusText = "Critique";
            description =
                "Aïe ! Le sol n'est pas bon du tout. Les plantes peuvent avoir du mal à pousser. Faut réagir vite.";
            dotColor = Colors.red;
          } else {
            statusColor = isDark
                ? const Color(0xFFFFB74D)
                : const Color(0xFFFF9800);
            statusBgColor = isDark
                ? const Color(0xFFE65100).withOpacity(0.3)
                : const Color(0xFFFFF3E0);
            statusText = "Surveillance";
            description =
                "Le sol commence à bouger un peu, certains paramètres sortent des bonnes valeurs.";
            dotColor = Colors.orange;
          }

          return GestureDetector(
            onTap: () => context.pushNamed('parcelle-detail', extra: parcelle),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${parcelle.nom} - ${parcelle.culture}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Appuyer pour voir les détails",
                    style: TextStyle(
                      color: const Color(0xFF28A745),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildQuickActionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Actions rapides",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFFFC107),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) {
                    // Start simulation on build if not started
                    // Use a local variable to track state outside builder if needed, but for simple simulation:
                    // We can auto-trigger logic.
                    // Actually, better to trigger it once.

                    return Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: const SizedBox(),
                    );
                  },
                ),
              );
            },
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/diagnostic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
            ),
            icon: const Icon(Icons.camera_alt_outlined, size: 28),
            label: const Text(
              "Scanner\nmaladie",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/irrigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFFFF9800).withOpacity(0.4),
            ),
            icon: const Icon(Icons.water_drop_outlined, size: 28),
            label: const Text(
              "Programmer\nirrigation",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommandationsSection() {
    return BlocBuilder<RecommandationBloc, RecommandationState>(
      builder: (context, state) {
        if (state is RecommandationLoaded) {
          final recommandations = state.recommandations.take(3).toList();
          if (recommandations.isEmpty) {
            return _buildEmptyCard(
              icon: Icons.check_circle_outline,
              title: "Aucune recommandation",
              subtitle: "Tout est en ordre !",
              color: Colors.green,
            );
          }
          return Column(
            children: [
              ...recommandations.map((r) => _buildRecommandationCard(r)),
              if (state.recommandations.length > 3)
                TextButton.icon(
                  onPressed: () => context.push('/recommandations'),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    "Voir ${state.recommandations.length - 3} autres",
                  ),
                ),
            ],
          );
        }
        if (state is RecommandationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildEmptyCard(
          icon: Icons.lightbulb_outline,
          title: "Recommandations",
          subtitle: "Chargement...",
          color: Colors.orange,
        );
      },
    );
  }

  Widget _buildRecommandationCard(dynamic recommandation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color color;
    String priority = recommandation.priorite?.toLowerCase() ?? 'normale';

    switch (priority) {
      case 'haute':
      case 'urgente':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'moyenne':
        icon = Icons.info_outline;
        color = Colors.orange;
        break;
      default:
        icon = Icons.lightbulb_outline;
        color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommandation.titre ?? 'Recommandation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommandation.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsWithCategories() {
    return BlocBuilder<AlertBloc, AlertState>(
      builder: (context, state) {
        if (state is AlertLoaded) {
          if (state.alerts.isEmpty) {
            return _buildEmptyCard(
              icon: Icons.notifications_off_outlined,
              title: "Aucune alerte",
              subtitle: "Tout fonctionne normalement",
              color: Colors.green,
            );
          }

          // Grouper les alertes par catégorie
          final Map<AlertCategory, List<Alert>> groupedAlerts = {};
          for (var alert in state.alerts) {
            groupedAlerts.putIfAbsent(alert.category, () => []);
            groupedAlerts[alert.category]!.add(alert);
          }

          return Column(
            children: [
              // Filtres par catégorie
              _buildCategoryFilters(groupedAlerts),
              const SizedBox(height: 16),
              // Liste des alertes
              ...state.alerts.take(5).map((alert) => _buildAlertCard(alert)),
              if (state.alerts.length > 5)
                TextButton.icon(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text("Voir ${state.alerts.length - 5} autres alertes"),
                ),
            ],
          );
        }
        if (state is AlertLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildEmptyCard(
          icon: Icons.notifications_outlined,
          title: "Alertes",
          subtitle: "Chargement...",
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildCategoryFilters(Map<AlertCategory, List<Alert>> groupedAlerts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AlertCategory.values.map((category) {
          final count = groupedAlerts[category]?.length ?? 0;
          final isActive = count > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: isActive
                  ? () =>
                        _showCategoryAlerts(category, groupedAlerts[category]!)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _getCategoryColor(category).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? _getCategoryColor(category)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 18,
                      color: isActive
                          ? _getCategoryColor(category)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryName(category),
                      style: TextStyle(
                        color: isActive
                            ? _getCategoryColor(category)
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCategoryAlerts(AlertCategory category, List<Alert> alerts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Alertes ${_getCategoryName(category)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) => _buildAlertCard(alerts[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getAlertLevelColor(alert.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(alert.category),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          alert.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryName(alert.category),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(alert.category),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(alert.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    if (alert.parcelleName != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.parcelleName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                if (alert.actionRecommandee != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.actionRecommandee!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getAlertLevelColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.critique:
        return Colors.red;
      case AlertLevel.important:
        return Colors.orange;
      case AlertLevel.info:
        return Colors.blue;
    }
  }

  Color _getCategoryColor(AlertCategory category) {
    switch (category) {
      case AlertCategory.irrigation:
        return Colors.blue;
      case AlertCategory.maladie:
        return Colors.red;
      case AlertCategory.meteo:
        return Colors.orange;
      case AlertCategory.sol:
        return Colors.brown;
      case AlertCategory.maintenance:
        return Colors.purple;
      case AlertCategory.commande:
        return Colors.teal;
      case AlertCategory.general:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(AlertCategory category) {
    switch (category) {
      case AlertCategory.irrigation:
        return Icons.water_drop_outlined;
      case AlertCategory.maladie:
        return Icons.coronavirus_outlined;
      case AlertCategory.meteo:
        return Icons.wb_sunny_outlined;
      case AlertCategory.sol:
        return Icons.grass_outlined;
      case AlertCategory.maintenance:
        return Icons.build_outlined;
      case AlertCategory.commande:
        return Icons.shopping_cart_outlined;
      case AlertCategory.general:
        return Icons.notifications_outlined;
    }
  }

  String _getCategoryName(AlertCategory category) {
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
}
