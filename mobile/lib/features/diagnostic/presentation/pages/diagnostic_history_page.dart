import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/diagnostic_bloc.dart';
import '../../domain/entities/diagnostic.dart';

class DiagnosticHistoryPage extends StatefulWidget {
  const DiagnosticHistoryPage({super.key});

  @override
  State<DiagnosticHistoryPage> createState() => _DiagnosticHistoryPageState();
}

class _DiagnosticHistoryPageState extends State<DiagnosticHistoryPage> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DiagnosticBloc>()..add(LoadHistory()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Historique diagnostics'),
          // backgroundColor: Colors.green,
          // foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDateRange,
              tooltip: 'Filtrer par date',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                 setState(() {
                  _selectedDateRange = null;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_selectedDateRange != null)
              Container(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.green.shade900.withValues(alpha: 0.3) 
                    : Colors.green.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtre: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                        style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900, 
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.green,
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<DiagnosticBloc, DiagnosticState>(
                builder: (context, state) {
                  if (state is DiagnosticLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
        
                  if (state is DiagnosticError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${state.message}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.read<DiagnosticBloc>().add(LoadHistory()),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }
        
                  if (state is DiagnosticHistoryLoaded) {
                    // Filter logic
                    final filteredHistory = state.history.where((diagnostic) {
                      if (_selectedDateRange == null) return true;
                      final date = diagnostic.createdAt;
                      return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                             date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                    }).toList();

                    if (filteredHistory.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Theme.of(context).disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              _selectedDateRange != null 
                                  ? 'Aucun diagnostic dans cette période' 
                                  : 'Aucun diagnostic enregistré',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      );
                    }
        
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<DiagnosticBloc>().add(LoadHistory());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final diagnostic = filteredHistory[index];
                          return _buildDiagnosticCard(diagnostic);
                        },
                      ),
                    );
                  }
        
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Widget _buildDiagnosticCard(Diagnostic diagnostic) {
    Color severityColor;
    switch (diagnostic.severity.toLowerCase()) {
      case 'high':
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      case 'low':
      case 'healthy':
        severityColor = Colors.green;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: severityColor.withValues(alpha: 0.1),
          child: Icon(Icons.bug_report, color: severityColor),
        ),
        title: Text(
          diagnostic.diseaseName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${diagnostic.cropType} • ${DateFormat('dd/MM/yyyy').format(diagnostic.createdAt)}'),
            const SizedBox(height: 4),
            Text(
              'Confiance: ${diagnostic.confidenceScore.toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: () {
          // TODO: Navigate to details
        },
      ),
    );
  }
}
