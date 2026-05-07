import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/formations/presentation/bloc/formation_bloc.dart';
import 'package:agriculture/features/formations/domain/entities/formation.dart';
import 'package:agriculture/injection_container.dart';

class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage> {
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'IoT',
    'Irrigation',
    'Maladies',
    'Sol',
    'Cultures',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FormationBloc>()..add(LoadFormations()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Formations',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                // TODO: Formations sauvegardées
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Stats progression
            BlocBuilder<FormationBloc, FormationState>(
              builder: (context, state) {
                int total = 0;
                int completed = 0;
                int inProgress = 0;

                if (state is FormationLoaded) {
                  total = state.formations.length;
                  completed = state.formations
                      .where((f) => f.isComplete)
                      .length;
                  inProgress = state.formations
                      .where((f) => (f.progression ?? 0) > 0 && !f.isComplete)
                      .length;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('$total', 'Formations', Icons.school),
                      _buildStat('$completed', 'Terminée', Icons.check_circle),
                      _buildStat('$inProgress', 'En cours', Icons.play_circle),
                    ],
                  ),
                );
              },
            ),

            // Catégories
            Container(
              height: 50,
              color: Theme.of(context).cardColor,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: _selectedCategory == cat
                              ? const Color(0xFFF57C00).withOpacity(0.9)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      selected: _selectedCategory == cat,
                      selectedColor: const Color(0xFFF57C00).withOpacity(0.2),
                      onSelected: (sel) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),

            // Liste des formations
            Expanded(
              child: BlocBuilder<FormationBloc, FormationState>(
                builder: (context, state) {
                  if (state is FormationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FormationError) {
                    return Center(child: Text('Erreur: ${state.message}'));
                  } else if (state is FormationLoaded) {
                    final filtered = _selectedCategory == 'Toutes'
                        ? state.formations
                        : state.formations
                              .where((f) => f.categorie == _selectedCategory)
                              .toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Aucune formation trouvée.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildFormationCard(filtered[index]),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF57C00), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFormationCard(Formation formation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showFormationDetail(formation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF57C00).withValues(alpha: 0.2)
                          : const Color(0xFFF57C00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(formation.categorie),
                      size: 36,
                      color: const Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (formation.isNew)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NOUVEAU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (formation.isComplete)
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 16,
                              ),
                          ],
                        ),
                        Text(
                          formation.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formation.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(
                    Icons.access_time,
                    '${formation.dureeMinutes} min',
                  ),
                  const SizedBox(width: 8),
                  _buildChip(Icons.signal_cellular_alt, formation.type),
                  const SizedBox(width: 8),
                  // _buildChip(Icons.play_lesson, '${formation.modules} modules'), // Modules not in Entity, maybe remove or infer?
                ],
              ),
              if ((formation.progression ?? 0) > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (formation.progression ?? 0) / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            formation.isComplete
                                ? Colors.green
                                : const Color(0xFFF57C00),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formation.progression ?? 0}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: formation.isComplete
                            ? Colors.green
                            : const Color(0xFFF57C00),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _showFormationDetail(Formation formation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFF57C00), Colors.orange.shade800],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(formation.categorie),
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formation.categorie,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                formation.titre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(formation.description),
              const SizedBox(height: 16),

              // Infos
              Row(
                children: [
                  _buildInfoItem(
                    Icons.access_time,
                    '${formation.dureeMinutes} min',
                  ),
                  _buildInfoItem(Icons.signal_cellular_alt, formation.type),
                  _buildInfoItem(Icons.play_lesson, '3 modules'), // Placeholder
                ],
              ),
              const SizedBox(height: 24),

              // Modules
              const Text(
                'Contenu de la formation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...List.generate(3, (i) {
                // Fixed modules count for now
                final completed =
                    (formation.progression ?? 0) > (i + 1) / 3 * 100;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: completed
                        ? Colors.green
                        : Colors.grey.shade200,
                    radius: 16,
                    child: completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                  title: Text('Module ${i + 1}'),
                  subtitle: Text(
                    completed ? 'Terminé' : 'Non démarré',
                    style: TextStyle(
                      color: completed ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    completed ? Icons.play_circle : Icons.lock,
                    color: completed ? const Color(0xFFF57C00) : Colors.grey,
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Bouton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Formation démarrée !'),
                        backgroundColor: const Color(0xFFF57C00),
                      ),
                    );
                  },
                  icon: Icon(
                    (formation.progression ?? 0) == 0
                        ? Icons.play_arrow
                        : Icons.play_circle,
                  ),
                  label: Text(
                    (formation.progression ?? 0) == 0
                        ? 'Commencer'
                        : 'Continuer',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF57C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'IoT':
        return Icons.sensors;
      case 'Irrigation':
        return Icons.water_drop;
      case 'Maladies':
        return Icons.bug_report;
      case 'Sol':
        return Icons.terrain;
      case 'Cultures':
        return Icons.grass;
      default:
        return Icons.school;
    }
  }
}
