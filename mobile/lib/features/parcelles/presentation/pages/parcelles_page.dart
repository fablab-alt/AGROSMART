import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';
import 'package:geolocator/geolocator.dart';
import 'parcelle_map_page.dart';

class ParcellesPage extends StatefulWidget {
  const ParcellesPage({super.key});

  @override
  State<ParcellesPage> createState() => _ParcellesPageState();
}

class _ParcellesPageState extends State<ParcellesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mes Parcelles',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              final state = context.read<ParcelleBloc>().state;
              if (state is ParcelleLoaded) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ParcelleMapPage(parcelles: state.parcelles),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Veuillez attendre le chargement des parcelles',
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ParcelleBloc>().add(LoadParcelles());
            },
          ),
        ],
      ),
      body: BlocBuilder<ParcelleBloc, ParcelleState>(
        builder: (context, state) {
          if (state is ParcelleLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ParcelleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Erreur: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ParcelleBloc>().add(LoadParcelles()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          } else if (state is ParcelleLoaded) {
            final parcelles = state.parcelles;
            if (parcelles.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune parcelle trouvée.\nAjoutez-en une !',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // Calculate stats
            final totalSuperficie = parcelles.fold(
              0.0,
              (sum, p) => sum + p.superficie,
            );
            final healthyCount = parcelles
                .where((p) => p.status == 'active' || p.status == 'healthy')
                .length;

            return Column(
              children: [
                // Stats résumé
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('${parcelles.length}', 'Parcelles'),
                      _buildStat(
                        '${totalSuperficie.toStringAsFixed(1)} ha',
                        'Surface',
                      ),
                      _buildStat('$healthyCount', 'Actives'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Liste des parcelles
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: parcelles.length,
                    itemBuilder: (context, index) {
                      final parcelle = parcelles[index];
                      return _buildParcelleCard(parcelle);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddParcelleDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelleCard(Parcelle parcelle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.pushNamed('parcelle-detail', extra: parcelle),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCultureIcon(parcelle.culture),
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcelle.nom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${parcelle.culture} • ${parcelle.superficie} ha',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(parcelle.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    Icons.water_drop,
                    '${parcelle.humidite}%',
                    'Humidité',
                    Colors.blue,
                  ),
                  _buildMetric(
                    Icons.thermostat,
                    '${parcelle.temperature}°C',
                    'Température',
                    Colors.orange,
                  ),
                  _buildMetric(
                    Icons.terrain,
                    parcelle.typeSol,
                    'Type sol',
                    Colors.brown,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dernière mise à jour: ${parcelle.lastUpdate != null ? _formatTime(parcelle.lastUpdate!) : "N/A"}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => context.push('/capteurs'),
                        icon: const Icon(Icons.sensors, size: 16),
                        label: const Text('Capteurs'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'healthy':
      case 'active':
        color = Colors.green;
        label = 'Bon';
        break;
      case 'warning':
        color = Colors.orange;
        label = 'Attention';
        break;
      case 'critical':
        color = Colors.red;
        label = 'Critique';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  IconData _getCultureIcon(String culture) {
    switch (culture.toLowerCase()) {
      case 'maïs':
        return Icons.grass;
      case 'riz':
        return Icons.rice_bowl;
      case 'tomate':
        return Icons.local_florist;
      case 'manioc':
        return Icons.nature;
      default:
        return Icons.eco;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else {
      return 'Il y a ${diff.inDays} jour(s)';
    }
  }

  void _showAddParcelleDialog() {
    final nomController = TextEditingController();
    final superficieController = TextEditingController();
    String selectedCulture = 'Maïs';
    String selectedTypeSol = 'Argileux';
    double? latitude;
    double? longitude;
    bool isLocating = false;
    bool isSubmitting = false;

    Future<void> fetchLocation(StateSetter setModalState) async {
      setModalState(() => isLocating = true);
      try {
        final position = await _getCurrentLocation();
        if (position != null) {
          setModalState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Position GPS récupérée avec succès.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setModalState(() => isLocating = false);
        }
      }
    }

    Future<void> submitParcelle(StateSetter setModalState) async {
      if (nomController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le nom de la parcelle est requis.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setModalState(() => isSubmitting = true);
      try {
        if (latitude == null || longitude == null) {
          await fetchLocation(setModalState);
        }

        if (latitude == null || longitude == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de créer sans position GPS.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Map UI values to Backend values
        String typeSolBackend = selectedTypeSol.toLowerCase();
        if (typeSolBackend == 'limono-argileux') {
          typeSolBackend = 'limono_argileux';
        }

        context.read<ParcelleBloc>().add(
          CreateParcelle({
            'nom': nomController.text.trim(),
            'superficie': double.tryParse(superficieController.text) ?? 0.0,
            'latitude': latitude,
            'longitude': longitude,
            'description': 'Culture de $selectedCulture',
            'type_sol': typeSolBackend,
          }),
        );

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Création en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
      } finally {
        if (mounted) {
          setModalState(() => isSubmitting = false);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nouvelle Parcelle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: 'Nom de la parcelle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.landscape),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: superficieController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Superficie (hectares)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.square_foot),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCulture,
                decoration: InputDecoration(
                  labelText: 'Culture',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.eco),
                ),
                items: ['Maïs', 'Riz', 'Tomate', 'Manioc', 'Arachide']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => selectedCulture = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedTypeSol,
                decoration: InputDecoration(
                  labelText: 'Type de sol',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.terrain),
                ),
                items: ['Argileux', 'Sablonneux', 'Limono-argileux']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => selectedTypeSol = value!,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localisation GPS',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (latitude != null && longitude != null)
                          ? 'Latitude: ${latitude!.toStringAsFixed(6)} | Longitude: ${longitude!.toStringAsFixed(6)}'
                          : 'La position sera récupérée automatiquement avant la création.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: isLocating
                    ? null
                    : () => fetchLocation(setModalState),
                icon: isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isLocating
                      ? 'Récupération de votre position...'
                      : 'Utiliser ma position actuelle',
                ),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => submitParcelle(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Créer la parcelle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Les permissions de localisation sont définitivement refusées.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }
}
