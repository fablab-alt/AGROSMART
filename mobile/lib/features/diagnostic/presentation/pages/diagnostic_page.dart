import 'dart:io';
import 'package:agriculture/features/diagnostic/data/models/diagnostic_model.dart';
import 'package:agriculture/features/diagnostic/presentation/widgets/diagnostic_analysis_table.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/diagnostic/presentation/bloc/diagnostic_bloc.dart';
import 'package:agriculture/injection_container.dart';

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  DiagnosticModel? _result;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DiagnosticBloc>(),
      child: BlocConsumer<DiagnosticBloc, DiagnosticState>(
        listener: (context, state) {
          if (state is DiagnosticError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DiagnosticSuccess) {
            setState(() {
              _result = state.result;
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text(
                'Diagnostic IA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => _showHistory(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone de capture
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_selectedImage == null) ...[
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: const Color(0xFF2196F3).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Scanner une plante',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prenez une photo d\'une feuille ou plante pour détecter les maladies et carences',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                context: context,
                                icon: Icons.camera_alt,
                                label: 'Caméra',
                                color: const Color(0xFF2196F3),
                                onTap: () =>
                                    _pickImage(context, ImageSource.camera),
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                context: context,
                                icon: Icons.photo_library,
                                label: 'Galerie',
                                color: Colors.blue,
                                onTap: () =>
                                    _pickImage(context, ImageSource.gallery),
                              ),
                            ],
                          ),
                        ] else ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_selectedImage!.path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state is DiagnosticLoading)
                            Column(
                              children: [
                                const CircularProgressIndicator(
                                  color: const Color(0xFF2196F3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Analyse en cours...',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            )
                          else if (_result != null)
                            _buildResultCard(context, _result!)
                          else
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _analyzeImage(context),
                                  icon: const Icon(Icons.search),
                                  label: const Text('Analyser'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                      _result = null;
                                    });
                                  },
                                  child: const Text('Choisir une autre image'),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Maladies détectables
                  const Text(
                    'Maladies Détectables',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildDiseaseCard(
                          context,
                          'Mildiou',
                          Icons.bug_report,
                          Colors.red,
                        ),
                        _buildDiseaseCard(
                          context,
                          'Rouille',
                          Icons.warning,
                          Colors.orange,
                        ),
                        _buildDiseaseCard(
                          context,
                          'Oïdium',
                          Icons.cloud,
                          Colors.grey,
                        ),
                        _buildDiseaseCard(
                          context,
                          'Carence N',
                          Icons.eco,
                          Colors.green,
                        ),
                        _buildDiseaseCard(
                          context,
                          'Anthracnose',
                          Icons.coronavirus,
                          Colors.brown,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, DiagnosticModel result) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on health status and theme mode
    final MaterialColor baseColor = result.isHealthy
        ? Colors.green
        : Colors.red;
    final Color backgroundColor = isDarkMode
        ? baseColor.withValues(alpha: 0.15)
        : baseColor.withValues(alpha: 0.1);
    final Color borderColor = isDarkMode
        ? baseColor.withValues(alpha: 0.3)
        : baseColor.withValues(alpha: 0.2);
    final Color iconColor = baseColor;
    final Color titleColor = isDarkMode
        ? baseColor.shade200
        : baseColor.shade700;

    return Column(
      children: [
        // Résumé rapide
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Icon(
                result.isHealthy ? Icons.check_circle : Icons.warning,
                size: 48,
                color: iconColor,
              ),
              const SizedBox(height: 12),
              Text(
                result.diseaseName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confiance: ${result.confidenceScore}%',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _result = null;
                      });
                    },
                    child: const Text('Nouveau scan'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showDetailedAnalysis(context, result),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analyse détaillée'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetailedAnalysis(BuildContext context, DiagnosticModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Analyse complète',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Tableau d'analyse
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: DiagnosticAnalysisTable(
                    diagnostic: result,
                    onSendToRecommendations: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/recommandations');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _result = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _analyzeImage(BuildContext context) async {
    if (_selectedImage == null) return;
    context.read<DiagnosticBloc>().add(
      AnalyzeImage(
        image: File(_selectedImage!.path),
        cropType: 'Tomate', // Default or pick from UI
        // parcelleId: ... pick from UI or passed parameter
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        // Pass the Bloc
        value: context.read<DiagnosticBloc>()..add(LoadHistory()),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) =>
              BlocBuilder<DiagnosticBloc, DiagnosticState>(
                buildWhen: (p, c) =>
                    c is DiagnosticHistoryLoaded ||
                    c is DiagnosticLoading ||
                    c is DiagnosticError,
                builder: (context, state) {
                  if (state is DiagnosticLoading)
                    return const Center(child: CircularProgressIndicator());
                  if (state is DiagnosticError)
                    return Center(child: Text('Erreur: ${state.message}'));
                  if (state is DiagnosticHistoryLoaded) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).dividerColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Historique des diagnostics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.history.length,
                            itemBuilder: (context, index) {
                              final item = state.history[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.bug_report,
                                      color: const Color(0xFF2196F3),
                                    ),
                                  ),
                                  title: Text(item.diseaseName),
                                  subtitle: Text(
                                    '${item.cropType} • ${item.confidenceScore}% confiance',
                                  ),
                                  trailing: Text(
                                    _formatDate(item.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
  }
}
