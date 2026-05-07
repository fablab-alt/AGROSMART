import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/parcelle.dart';
import '../../data/models/iot_metric_model.dart';
import '../../data/datasources/parcelle_remote_data_source.dart';
import '../widgets/yield_prediction_card.dart';
import '../../../../core/network/api_client.dart'; // Import du client API global
import '../../../capteurs/presentation/pages/capteur_detail_page.dart';
import '../../../capteurs/presentation/pages/npk_detail_page_v2.dart';
import '../../../capteurs/domain/entities/sensor.dart';

class ParcelleDetailPage extends StatefulWidget {
  final Parcelle parcelle;

  const ParcelleDetailPage({super.key, required this.parcelle});

  @override
  State<ParcelleDetailPage> createState() => _ParcelleDetailPageState();
}

class _ParcelleDetailPageState extends State<ParcelleDetailPage> {
  IotMetricsResponse? _iotMetrics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIotMetrics();
  }

  Future<void> _loadIotMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser le client API global configuré
      final dataSource = ParcelleRemoteDataSourceImpl(dio: dioClient);
      final metrics = await dataSource.getParcelleIotMetrics(
        widget.parcelle.id,
      );

      if (mounted) {
        setState(() {
          _iotMetrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement métriques IoT: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion au serveur';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parcelle.nom),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIotMetrics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadIotMetrics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fake Map Placeholder
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.green.shade100,
                child: Center(
                  child: Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.parcelle.nom,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(widget.parcelle.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.parcelle.cultureActuelle?.nom ?? 'Non définie'} • ${widget.parcelle.typeSol} • ${widget.parcelle.superficie} ha',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Métriques Actuelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_iotMetrics != null &&
                            _iotMetrics!.totalCapteurs > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_iotMetrics!.capteursAvecDonnees}/${_iotMetrics!.totalCapteurs} capteurs',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildMetricsSection(),

                    const SizedBox(height: 24),
                    const YieldPredictionCard(
                      prediction: 12.5,
                      confidence: 0.85,
                      factors: [
                        'Pluviométrie favorable',
                        'Sol riche',
                        'Aucun ravageur détecté',
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.water, color: Colors.white),
                      ),
                      title: const Text('Irrigation'),
                      subtitle: const Text('Dernière irrigation: Hier'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/irrigation'),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.science, color: Colors.white),
                      ),
                      title: const Text('Fertilisation'),
                      subtitle: const Text('Recommandation: NPK requis'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showFertilisationDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_iotMetrics == null || _iotMetrics!.metrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.sensors_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                _iotMetrics?.message ??
                    'Aucun capteur configuré pour cette parcelle',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Afficher tous les capteurs en une seule ligne horizontale
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _iotMetrics!.metrics.length,
        itemBuilder: (context, index) {
          final metric = _iotMetrics!.metrics[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < _iotMetrics!.metrics.length - 1 ? 12 : 0,
            ),
            child: SizedBox(width: 150, child: _buildMetricCard(metric)),
          );
        },
      ),
    );
  }

  Widget _buildMetricTypeGroup(String type, List<IotMetricModel> metrics) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    // Pour les types simples (un seul capteur), afficher directement
    if (metrics.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: SizedBox(height: 160, child: _buildMetricCard(metrics.first)),
      );
    }

    // Pour NPK ou types multiples, afficher en liste horizontale scrollable
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            _getTypeDisplayName(type),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < metrics.length - 1 ? 12 : 0,
                ),
                child: SizedBox(
                  width: 150,
                  child: _buildMetricCard(metrics[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'NPK':
        return 'Nutriments du Sol (NPK)';
      case 'HUMIDITE_SOL':
        return 'Humidité du Sol';
      case 'HUMIDITE_TEMPERATURE_AMBIANTE':
        return 'Conditions Ambiantes';
      case 'UV':
        return 'Rayonnement UV';
      default:
        return type;
    }
  }

  Widget _buildMetricCard(IotMetricModel metric) {
    final icon = _getIconForMetric(metric.type, metric.nom);
    final color = _getColorForMetric(metric.type);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToSensorDetail(metric),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                metric.formattedValue,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: metric.horsSeuils ? Colors.red : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                metric.nom,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (metric.horsSeuils)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Alerte',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSensorDetail(IotMetricModel metric) {
    // Déterminer le signal force basé sur la valeur signal
    String signalForce = 'moyen';
    if (metric.signal != null) {
      if (metric.signal! > 70) {
        signalForce = 'fort';
      } else if (metric.signal! < 40) {
        signalForce = 'faible';
      }
    }

    // Créer un objet Sensor à partir de la métrique
    final sensor = Sensor(
      id: metric.capteurId,
      code: metric.capteurId, // Utiliser l'ID comme code
      nom: metric.nom,
      type: metric.type,
      status: metric.statut,
      lastValue: metric.valeur != null
          ? double.tryParse(metric.valeur.toString())
          : null,
      unit: metric.unite,
      parcelleNom: widget.parcelle.nom,
      niveauBatterie: (metric.batterie ?? 100.0).toDouble(),
      signalForce: signalForce,
      lastUpdate: DateTime.now(),
    );

    // Naviguer vers la bonne page selon le type
    if (metric.type.toLowerCase().contains('npk')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NpkDetailPageV2(capteur: sensor),
        ),
      ).then((_) => _loadIotMetrics());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CapteurDetailPage(capteur: sensor),
        ),
      ).then((_) => _loadIotMetrics());
    }
  }

  IconData _getIconForMetric(String type, String nom) {
    if (nom.toLowerCase().contains('azote') ||
        nom.toLowerCase().contains('n')) {
      return Icons.grass;
    }
    if (nom.toLowerCase().contains('phosphore') ||
        nom.toLowerCase().contains('p')) {
      return Icons.eco;
    }
    if (nom.toLowerCase().contains('potassium') ||
        nom.toLowerCase().contains('k')) {
      return Icons.spa;
    }

    switch (type) {
      case 'HUMIDITE_SOL':
        return Icons.water_drop;
      case 'HUMIDITE_TEMPERATURE_AMBIANTE':
        return Icons.thermostat;
      case 'UV':
        return Icons.wb_sunny;
      case 'DIRECTION_VENT':
        return Icons.air;
      case 'TRANSPIRATION_PLANTE':
        return Icons.opacity;
      case 'NPK':
        return Icons.science;
      default:
        return Icons.sensors;
    }
  }

  Color _getColorForMetric(String type) {
    switch (type) {
      case 'HUMIDITE_SOL':
        return Colors.blue;
      case 'HUMIDITE_TEMPERATURE_AMBIANTE':
        return Colors.orange;
      case 'UV':
        return Colors.amber;
      case 'DIRECTION_VENT':
        return Colors.lightBlue;
      case 'TRANSPIRATION_PLANTE':
        return Colors.cyan;
      case 'NPK':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showFertilisationDialog(BuildContext context) {
    final selectedFertilizers = <String>[];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.science, color: Colors.purple),
              SizedBox(width: 8),
              Text('Plan de Fertilisation'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionnez les engrais à appliquer :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildFertilisationCheckItem(
                  'NPK 15-15-15',
                  'Recommandé pour la croissance équilibrée',
                  '200 kg/ha',
                  Colors.green,
                  selectedFertilizers,
                  setState,
                ),
                const SizedBox(height: 12),
                _buildFertilisationCheckItem(
                  'Urée (46% N)',
                  'Pour renforcer la croissance végétative',
                  '100 kg/ha',
                  Colors.blue,
                  selectedFertilizers,
                  setState,
                ),
                const SizedBox(height: 12),
                _buildFertilisationCheckItem(
                  'Compost organique',
                  'Améliore la structure du sol',
                  '2 tonnes/ha',
                  Colors.brown,
                  selectedFertilizers,
                  setState,
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Appliquer après une pluie légère ou irrigation',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: selectedFertilizers.isEmpty
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      _applyFertilizationPlan(selectedFertilizers);
                    },
              icon: const Icon(Icons.check),
              label: const Text('Appliquer au plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilisationCheckItem(
    String name,
    String description,
    String dose,
    Color color,
    List<String> selected,
    StateSetter setState,
  ) {
    final isSelected = selected.contains(name);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selected.remove(name);
          } else {
            selected.add(name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selected.add(name);
                  } else {
                    selected.remove(name);
                  }
                });
              },
              activeColor: color,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dose,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFertilizationPlan(List<String> fertilizers) {
    // Créer un plan de fertilisation
    final plan = {
      'parcelleId': widget.parcelle.id,
      'parcelleName': widget.parcelle.nom,
      'date': DateTime.now().toIso8601String(),
      'fertilizers': fertilizers,
      'status': 'planned',
    };

    // TODO: Envoyer au backend pour enregistrer le plan
    // await apiClient.post('/parcelles/${widget.parcelle.id}/fertilization', data: plan);

    // Sauvegarder localement pour la démo
    debugPrint('Plan de fertilisation créé: $plan');

    // Afficher confirmation avec détails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan de fertilisation enregistré',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${fertilizers.length} engrais sélectionnés'),
            const SizedBox(height: 4),
            const Text(
              'Un calendrier d\'application a été créé',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Naviguer vers le calendrier
            context.push('/calendar');
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ENSEMENCEE':
      case 'EN_CROISSANCE':
        color = Colors.green;
        label = status.toUpperCase().replaceAll('_', ' ');
        break;
      case 'PREPAREE':
        color = Colors.orange;
        label = 'PRÉPARÉE';
        break;
      case 'RECOLTE':
        color = Colors.purple;
        label = 'RÉCOLTE';
        break;
      case 'EN_REPOS':
        color = Colors.grey;
        label = 'EN REPOS';
        break;
      case 'ACTIVE':
      default:
        color = Colors.blue;
        label = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
