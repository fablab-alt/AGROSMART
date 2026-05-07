import 'package:agriculture/features/recommandations/domain/entities/recommandation.dart';
import 'package:agriculture/features/recommandations/presentation/bloc/recommandation_bloc.dart';
import 'package:agriculture/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecommandationsPage extends StatefulWidget {
  const RecommandationsPage({super.key});

  @override
  State<RecommandationsPage> createState() => _RecommandationsPageState();
}

class _RecommandationsPageState extends State<RecommandationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecommandationBloc>()..add(LoadRecommandations()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Recommandations IA'),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.lightbulb_outline), text: 'Générales'),
              Tab(
                icon: Icon(Icons.medical_services_outlined),
                text: 'Diagnostics',
              ),
            ],
          ),
        ),
        body: BlocBuilder<RecommandationBloc, RecommandationState>(
          builder: (context, state) {
            if (state is RecommandationLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RecommandationError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else if (state is RecommandationLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Recommandations générales
                  _buildGeneralRecommandations(context, state.recommandations),
                  // Tab 2: Recommandations diagnostics
                  _buildDiagnosticRecommandations(
                    context,
                    state.diagnosticRecommandations,
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildGeneralRecommandations(
    BuildContext context,
    List<Recommandation> recommandations,
  ) {
    if (recommandations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune recommandation pour le moment.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Vos cultures semblent en bonne santé !',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommandations.length,
      itemBuilder: (context, index) {
        return _RecommandationCard(rec: recommandations[index]);
      },
    );
  }

  Widget _buildDiagnosticRecommandations(
    BuildContext context,
    List<DiagnosticRecommandation> diagnosticRecos,
  ) {
    if (diagnosticRecos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun diagnostic enregistré',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Les résultats de vos scans de maladies\napparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/diagnostic');
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scanner une plante'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diagnosticRecos.length,
      itemBuilder: (context, index) {
        return _DiagnosticRecommandationCard(reco: diagnosticRecos[index]);
      },
    );
  }
}

class _DiagnosticRecommandationCard extends StatelessWidget {
  final DiagnosticRecommandation reco;
  const _DiagnosticRecommandationCard({required this.reco});

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(reco.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec le nom de la maladie
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  severityColor.withValues(alpha: 0.2),
                  severityColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bug_report,
                        color: severityColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reco.diseaseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reco.parcelleNom,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSeverityBadge(reco.severity, severityColor),
                  ],
                ),
                const SizedBox(height: 12),
                // Barre de confiance
                Row(
                  children: [
                    const Text(
                      'Confiance: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: reco.confidenceScore / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            severityColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reco.confidenceScore}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(reco.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),

                // Traitements recommandés
                if (reco.treatments.isNotEmpty) ...[
                  _buildSectionHeader(
                    icon: Icons.healing,
                    title: 'Traitements recommandés',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  ...reco.treatments
                      .take(3)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                ],

                // Préventions
                if (reco.preventions.isNotEmpty) ...[
                  _buildSectionHeader(
                    icon: Icons.shield,
                    title: 'Mesures préventives',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  ...reco.preventions
                      .take(3)
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],

                const SizedBox(height: 16),
                const Divider(),

                // Footer avec date et actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(reco.dateCreation),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _showDetailDialog(context, reco);
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Détails'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Traitement pour "${reco.diseaseName}" marqué comme appliqué',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Traité'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: severityColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(String severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critique':
        return Colors.red.shade700;
      case 'élevée':
        return Colors.orange.shade700;
      case 'moyenne':
        return Colors.amber.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour(s)';
  }

  void _showDetailDialog(BuildContext context, DiagnosticRecommandation reco) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report, color: _getSeverityColor(reco.severity)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reco.diseaseName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Parcelle', reco.parcelleNom),
              _buildInfoRow('Confiance', '${reco.confidenceScore}%'),
              _buildInfoRow('Sévérité', reco.severity),
              _buildInfoRow('Date', _formatFullDate(reco.dateCreation)),
              const Divider(height: 24),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(reco.description),
              if (reco.treatments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tous les traitements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...reco.treatments.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• $t'),
                  ),
                ),
              ],
              if (reco.preventions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Toutes les préventions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...reco.preventions.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• $p'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime time) {
    return '${time.day}/${time.month}/${time.year} à ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _RecommandationCard extends StatelessWidget {
  final Recommandation rec;
  const _RecommandationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(rec.type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(rec.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(rec.type),
                    color: _getTypeColor(rec.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rec.titre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildPriorityBadge(rec.priorite),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.parcelleNom,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.description),
                const SizedBox(height: 16),

                // Détails
                ...rec.details.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${e.key}:',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(rec.dateCreation),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.thumb_down, size: 16),
                          label: const Text('Pas utile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Recommandation "${rec.titre}" appliquée',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Appliquer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getTypeColor(rec.type),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priorite) {
    Color color;
    switch (priorite.toLowerCase()) {
      case 'haute':
        color = Colors.red;
        break;
      case 'moyenne':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priorite.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTypeColor(RecommandationType type) {
    switch (type) {
      case RecommandationType.irrigation:
        return Colors.blue;
      case RecommandationType.fertilisation:
        return Colors.green;
      case RecommandationType.culture:
        return Colors.purple;
      case RecommandationType.phytosanitaire:
        return Colors.orange;
      case RecommandationType.traitement:
        return Colors.red;
      case RecommandationType.recolte:
        return Colors.brown;
    }
  }

  IconData _getTypeIcon(RecommandationType type) {
    switch (type) {
      case RecommandationType.irrigation:
        return Icons.water_drop;
      case RecommandationType.fertilisation:
        return Icons.science;
      case RecommandationType.culture:
        return Icons.grass;
      case RecommandationType.phytosanitaire:
        return Icons.medical_services;
      case RecommandationType.traitement:
        return Icons.healing;
      case RecommandationType.recolte:
        return Icons.agriculture;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour(s)';
  }
}
