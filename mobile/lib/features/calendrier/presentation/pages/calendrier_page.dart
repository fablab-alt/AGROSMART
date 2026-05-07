import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/activite.dart';
import '../bloc/calendrier_bloc.dart';
import '../bloc/calendrier_event.dart';
import '../bloc/calendrier_state.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendrierPage extends StatefulWidget {
  const CalendrierPage({super.key});

  @override
  State<CalendrierPage> createState() => _CalendrierPageState();
}

class _CalendrierPageState extends State<CalendrierPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TypeActivite? _selectedType;
  StatutActivite? _selectedStatut;
  PrioriteActivite? _selectedPriorite;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadActivites();
  }

  void _loadActivites() {
    context.read<CalendrierBloc>().add(
      LoadActivites(
        typeActivite: _selectedType,
        statut: _selectedStatut,
        priorite: _selectedPriorite,
      ),
    );
  }

  List<Activite> _getEventsForDay(List<Activite> activites, DateTime day) {
    return activites.where((activite) {
      return isSameDay(activite.dateDebut, day) ||
          (activite.dateFin != null &&
              day.isAfter(activite.dateDebut) &&
              day.isBefore(activite.dateFin!));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendrier Agricole',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'all':
                    _selectedType = null;
                    _selectedStatut = null;
                    _selectedPriorite = null;
                    break;
                  case 'planifiee':
                    _selectedStatut = StatutActivite.planifiee;
                    break;
                  case 'en_cours':
                    _selectedStatut = StatutActivite.enCours;
                    break;
                  case 'terminee':
                    _selectedStatut = StatutActivite.terminee;
                    break;
                }
                _loadActivites();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Toutes')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'planifiee',
                child: Text('Planifiées'),
              ),
              const PopupMenuItem(value: 'en_cours', child: Text('En cours')),
              const PopupMenuItem(value: 'terminee', child: Text('Terminées')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<CalendrierBloc, CalendrierState>(
        builder: (context, state) {
          if (state is CalendrierLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CalendrierError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadActivites,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final activites = state is CalendrierLoaded
              ? state.activites
              : <Activite>[];

          return Column(
            children: [
              TableCalendar<Activite>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(activites, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildActivitesList(
                  _getEventsForDay(activites, _selectedDay ?? DateTime.now()),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendrier_add_fab',
        onPressed: () => _showCreateActiviteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivitesList(List<Activite> activites) {
    if (activites.isEmpty) {
      return const Center(child: Text('Aucune activité pour ce jour'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: activites.length,
      itemBuilder: (context, index) {
        final activite = activites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(activite.priorite),
              child: Text(activite.typeActivite.displayName.split(' ')[0]),
            ),
            title: Text(
              activite.titre,
              style: TextStyle(
                decoration: activite.statut == StatutActivite.terminee
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activite.typeActivite.displayName),
                Text(
                  activite.statut.displayName,
                  style: TextStyle(
                    color: _getStatutColor(activite.statut),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (activite.parcelle != null)
                  Text('Parcelle: ${activite.parcelle!.nom}'),
                if (activite.estEnRetard)
                  const Text(
                    '⚠️ En retard',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: activite.statut != StatutActivite.terminee
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      context.read<CalendrierBloc>().add(
                        MarquerActiviteComplete(activite.id),
                      );
                    },
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () => _showActiviteDetails(activite),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(PrioriteActivite priorite) {
    switch (priorite) {
      case PrioriteActivite.urgente:
        return Colors.red;
      case PrioriteActivite.haute:
        return Colors.orange;
      case PrioriteActivite.moyenne:
        return Colors.blue;
      case PrioriteActivite.basse:
        return Colors.grey;
    }
  }

  Color _getStatutColor(StatutActivite statut) {
    switch (statut) {
      case StatutActivite.planifiee:
        return Colors.blue;
      case StatutActivite.enCours:
        return Colors.orange;
      case StatutActivite.terminee:
        return Colors.green;
      case StatutActivite.annulee:
        return Colors.red;
      case StatutActivite.reportee:
        return Colors.purple;
    }
  }

  void _showActiviteDetails(Activite activite) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                activite.titre,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Type', activite.typeActivite.displayName),
              _buildDetailRow('Statut', activite.statut.displayName),
              _buildDetailRow('Priorité', activite.priorite.displayName),
              _buildDetailRow(
                'Date début',
                DateFormat('dd/MM/yyyy HH:mm').format(activite.dateDebut),
              ),
              if (activite.dateFin != null)
                _buildDetailRow(
                  'Date fin',
                  DateFormat('dd/MM/yyyy HH:mm').format(activite.dateFin!),
                ),
              if (activite.description != null)
                _buildDetailRow('Description', activite.description!),
              if (activite.parcelle != null)
                _buildDetailRow('Parcelle', activite.parcelle!.nom),
              if (activite.coutEstime != null)
                _buildDetailRow(
                  'Coût estimé',
                  '${activite.coutEstime!.toStringAsFixed(2)} FCFA',
                ),
              if (activite.produitsUtilises != null &&
                  activite.produitsUtilises!.isNotEmpty)
                _buildDetailRow(
                  'Produits utilisés',
                  activite.produitsUtilises!.join(', '),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (activite.statut != StatutActivite.terminee)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<CalendrierBloc>().add(
                            MarquerActiviteComplete(activite.id),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Marquer terminée'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<CalendrierBloc>().add(
                          DeleteExistingActivite(activite.id),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateActiviteDialog() {
    // TODO: Implement create activite dialog with form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de création en développement'),
      ),
    );
  }
}
