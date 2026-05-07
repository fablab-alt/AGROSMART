import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/core/widgets/cached_image.dart';
import '../../domain/entities/equipment.dart';
import '../bloc/equipment_bloc.dart';

class EquipmentListPage extends StatefulWidget {
  const EquipmentListPage({super.key});

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  String? _selectedCategorie;

  final Map<String, String> _categories = {
    'tous': 'Tous',
    'tracteur': 'Tracteurs',
    'moissonneuse': 'Moissonneuses',
    'pulverisateur': 'Pulvérisateurs',
    'charrue': 'Charrues',
    'semoir': 'Semoirs',
    'autre': 'Autres',
  };

  @override
  void initState() {
    super.initState();
    context.read<EquipmentBloc>().add(LoadEquipments());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Location d\'Équipements',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            color: isDark ? Colors.grey.shade900 : Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _categories.entries.map((entry) {
                return _buildCategoryChip(entry.key, entry.value);
              }).toList(),
            ),
          ),

          // Equipment List
          Expanded(
            child: BlocBuilder<EquipmentBloc, EquipmentState>(
              builder: (context, state) {
                if (state is EquipmentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EquipmentError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text('Erreur: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<EquipmentBloc>().add(LoadEquipments());
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is EquipmentLoaded) {
                  if (state.equipments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.agriculture,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun équipement disponible',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les propriétaires peuvent ajouter leurs équipements ici',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<EquipmentBloc>().add(
                        LoadEquipments(categorie: _selectedCategorie),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.equipments.length,
                      itemBuilder: (context, index) {
                        return _buildEquipmentCard(state.equipments[index]);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'equipment_list_fab',
        onPressed: () {
          // TODO: Navigate to Add Equipment page (for owners)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité à venir: Ajouter un équipement'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Proposer'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategorie == (key == 'tous' ? null : key);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategorie = key == 'tous' ? null : key;
          });
          context.read<EquipmentBloc>().add(
            LoadEquipments(categorie: _selectedCategorie),
          );
        },
        selectedColor: Colors.green.shade100,
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to EquipmentDetailPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailPage(equipment: equipment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec cache
            EquipmentImage(
              imageUrl: equipment.images.isNotEmpty
                  ? equipment.images.first
                  : null,
              height: 180,
              equipmentName: equipment.nom,
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          equipment.nom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!equipment.disponible)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Non disponible',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        equipment.categorie,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        equipment.etat,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (equipment.localisation != null) ...[
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
                          equipment.localisation!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prix par jour',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${equipment.prixParJour.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: equipment.disponible
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EquipmentDetailPage(
                                      equipment: equipment,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Louer'),
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
}

// Placeholder for EquipmentDetailPage
class EquipmentDetailPage extends StatelessWidget {
  final Equipment equipment;

  const EquipmentDetailPage({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.nom),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Detail page for ${equipment.nom}\n(To be implemented)'),
      ),
    );
  }
}
