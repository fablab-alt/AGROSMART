import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/notifications/data/datasources/alert_remote_data_source.dart';
import 'package:agriculture/features/notifications/data/repositories/alert_repository_impl.dart';
import 'package:agriculture/features/notifications/presentation/bloc/alert_bloc.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/recommandations/presentation/bloc/recommandation_bloc.dart';
import 'package:agriculture/features/recommandations/domain/entities/recommandation.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/injection_container.dart' as di;
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AlertBloc _alertBloc;
  late RecommandationBloc _recommandationBloc;
  late TabController _tabController;
  int _selectedFilterIndex = 0;

  // Filtres selon le rôle
  List<String> _filters = [];
  bool _isProducer = true;

  @override
  void initState() {
    super.initState();

    // Déterminer le rôle de l'utilisateur
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final role = authState.user.role.toUpperCase();
      _isProducer =
          role == 'PRODUCTEUR' || role == 'FARMER' || role == 'PRODUCER';
    }

    // Filtres différents selon le rôle
    if (_isProducer) {
      _filters = ["Tout", "Maladies", "Irrigation", "Sol", "Météo", "Récolte"];
      _tabController = TabController(
        length: 2,
        vsync: this,
      ); // Alertes + Conseils
    } else {
      _filters = ["Tout", "Commandes", "Promotions", "Livraisons"];
      _tabController = TabController(
        length: 2,
        vsync: this,
      ); // Notifications + Offres
    }

    // Init AlertBloc
    final dataSource = AlertRemoteDataSourceImpl(dio: dioClient);
    final repository = AlertRepositoryImpl(remoteDataSource: dataSource);
    _alertBloc = AlertBloc(repository: repository)..add(LoadAlerts());

    // Init RecommandationBloc seulement pour les producteurs
    if (_isProducer) {
      try {
        _recommandationBloc = di.sl<RecommandationBloc>()
          ..add(LoadRecommandations());
      } catch (e) {
        debugPrint("RecommandationBloc retrieval failed: $e");
      }
    }
  }

  @override
  void dispose() {
    _alertBloc.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _alertBloc),
        if (_isProducer) BlocProvider.value(value: _recommandationBloc),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _isProducer
                    ? [_buildAlertsTab(), _buildRecommendationsTab()]
                    : [_buildBuyerNotificationsTab(), _buildBuyerOffersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final headerColor = _isProducer
        ? const Color(0xFFD32F2F)
        : Colors.green[700];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 0),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                _isProducer ? "Alertes Producteur" : "Mes Notifications",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: _isProducer
                ? const [Tab(text: "Alertes"), Tab(text: "Conseils")]
                : const [Tab(text: "Notifications"), Tab(text: "Offres")],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ======== ONGLETS PRODUCTEUR ========
  Widget _buildAlertsTab() {
    return BlocBuilder<AlertBloc, AlertState>(
      builder: (context, state) {
        List<Alert> alerts = [];
        if (state is AlertLoaded) {
          alerts = state.alerts;
        }

        // Filter logic
        if (_selectedFilterIndex != 0) {
          alerts = alerts.where((a) {
            switch (_selectedFilterIndex) {
              case 1:
                return a.category == AlertCategory.maladie;
              case 2:
                return a.category == AlertCategory.irrigation;
              case 3:
                return a.category == AlertCategory.sol;
              case 4:
                return a.category == AlertCategory.meteo;
              case 5:
                return a.category == AlertCategory.general;
              default:
                return true;
            }
          }).toList();
        }

        return Column(
          children: [
            // Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      checkmarkColor: Colors.red,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.red : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // List
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune alerte pour ce filtre",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_selectedFilterIndex == 0) ...[
                            // Timeline Alertes (Small Cards) - Only on 'All' view for summary
                            ...alerts
                                .take(3)
                                .map((alert) => _buildSmallAlertCard(alert)),
                            const SizedBox(height: 24),
                          ],

                          // Detailed Cards
                          ...alerts.map((a) {
                            if (a.category == AlertCategory.maladie)
                              return _buildDiseaseAlertCard(a);
                            if (a.category == AlertCategory.irrigation)
                              return _buildIrrigationCard(a);
                            if (a.category == AlertCategory.sol)
                              return _buildPhCard(a);
                            // Fallback
                            return _buildSmallAlertCard(a);
                          }),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    return BlocBuilder<RecommandationBloc, RecommandationState>(
      builder: (context, state) {
        if (state is RecommandationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Recommandation> recs = [];
        if (state is RecommandationLoaded) {
          recs = state.recommandations;
        }

        if (recs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 60,
                  color: Colors.green.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tout est optimal !",
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
                const Text(
                  "Aucun conseil pour le moment.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recs.length,
          itemBuilder: (context, index) {
            final rec = recs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconForType(rec.type), color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (rec.impactEstime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              "Impact: ${rec.impactEstime}",
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(RecommandationType type) {
    switch (type) {
      case RecommandationType.irrigation:
        return Icons.water_drop;
      case RecommandationType.fertilisation:
        return Icons.science;
      case RecommandationType.traitement:
        return Icons.healing;
      case RecommandationType.recolte:
        return Icons.agriculture;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Widget _buildSmallAlertCard(Alert alert) {
    Color barColor = Colors.orange;
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = Colors.orange;

    if (alert.category == AlertCategory.irrigation) {
      barColor = Colors.green;
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else if (alert.category == AlertCategory.maladie) {
      barColor = Colors.red;
      icon = Icons.error_outline;
      iconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: barColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(alert.date),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseAlertCard(Alert alert) {
    return InkWell(
      onTap: () {
        // Rediriger vers les recommandations
        context.push('/recommendations');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bug_report_outlined,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Alerte Maladie - IA",
                    style: TextStyle(
                      color: Color(0xFFB71C1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB71C1C)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.message,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/recommandations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Voir\nRecommandations",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/community'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Contacter un\nexpert",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationCard(Alert alert) {
    return InkWell(
      onTap: () {
        // Rediriger vers l'interface d'irrigation
        context.push('/irrigation');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Irrigation Programmée",
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF0D47A1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.message,
              style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/irrigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Modifier la programmation"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhCard(Alert alert) {
    return InkWell(
      onTap: () {
        // Rediriger vers les capteurs/monitoring
        context.push('/monitoring');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  "pH Acide",
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.actionRecommandee ??
                  "Mets un peu de chaux ou de cendre de bois pour remonter le pH.",
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======== ONGLETS ACHETEUR ========
  Widget _buildBuyerNotificationsTab() {
    // Notifications d'achat pour les acheteurs
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBuyerNotificationCard(
            icon: Icons.local_shipping,
            iconColor: Colors.blue,
            title: 'Commande en cours de livraison',
            subtitle: 'Votre commande #CMD-2024-001 est en route',
            time: 'Il y a 2h',
          ),
          _buildBuyerNotificationCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            title: 'Paiement confirmé',
            subtitle: 'Paiement de 25 000 FCFA reçu avec succès',
            time: 'Hier',
          ),
          _buildBuyerNotificationCard(
            icon: Icons.star,
            iconColor: Colors.orange,
            title: 'Donnez votre avis',
            subtitle: 'Que pensez-vous de votre dernière commande ?',
            time: 'Il y a 2 jours',
          ),
          _buildBuyerNotificationCard(
            icon: Icons.storefront,
            iconColor: Colors.purple,
            title: 'Nouveau vendeur vérifié',
            subtitle: 'Coopérative de Yamoussoukro maintenant disponible',
            time: 'Il y a 3 jours',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBuyerNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerOffersTab() {
    // Offres et promotions pour les acheteurs
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOfferCard(
            title: '🎉 -20% sur les semences',
            description:
                'Profitez de 20% de réduction sur toutes les semences jusqu\'au 15 février',
            validUntil: 'Valable jusqu\'au 15/02/2026',
            color: Colors.green,
          ),
          _buildOfferCard(
            title: '🚚 Livraison gratuite',
            description:
                'Livraison offerte pour toute commande supérieure à 50 000 FCFA',
            validUntil: 'Offre permanente',
            color: Colors.blue,
          ),
          _buildOfferCard(
            title: '🌾 Pack Producteur',
            description:
                'Engrais + Semences + Outils à prix réduit pour démarrer la saison',
            validUntil: 'Stock limité',
            color: Colors.orange,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String description,
    required String validUntil,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  validUntil,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Voir plus →',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
