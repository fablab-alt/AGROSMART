import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/injection_container.dart' as di;

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  String? _selectedParcelleId;
  bool _isLoading = false;
  Map<String, dynamic>? _irrigationData;
  String? _error;

  // Programme settings
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  int _durationMinutes = 30;
  List<int> _selectedDays = [1, 3, 5]; // Lundi, Mercredi, Vendredi
  bool _autoMode = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
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
                      const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Programme d'Irrigation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Gérez l'irrigation de vos parcelles de manière intelligente",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildParcelleSelector(),
                  const SizedBox(height: 24),
                  if (_selectedParcelleId != null) ...[
                    _buildIrrigationStatus(isDark),
                    const SizedBox(height: 24),
                    _buildValveControlSection(isDark),
                    const SizedBox(height: 24),
                    _buildProgramSection(isDark),
                    const SizedBox(height: 24),
                    _buildRecommendationsSection(isDark),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ] else
                    _buildEmptyState(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelleSelector() {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoaded && state.parcelles.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sélectionner une parcelle",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedParcelleId,
                    hint: const Text("Choisir une parcelle"),
                    items: state.parcelles.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text("${p.nom} (${p.superficie} ha)"),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedParcelleId = value;
                        _irrigationData = null;
                        _error = null;
                      });
                      if (value != null) {
                        _loadIrrigationData(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }
        return const Center(child: Text("Aucune parcelle disponible"));
      },
    );
  }

  Future<void> _loadIrrigationData(String parcelleId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = di.sl<ApiClient>();
      final response = await apiClient.get(
        '/recommandations/irrigation/$parcelleId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _irrigationData = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.data['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildIrrigationStatus(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    final besoin = _irrigationData?['besoinEau'] ?? 0;
    final humidite = _irrigationData?['humiditeSol'] ?? 50;
    final statusColor = humidite < 30
        ? Colors.red
        : (humidite < 60 ? Colors.orange : Colors.green);
    final statusText = humidite < 30
        ? 'Critique'
        : (humidite < 60 ? 'Modéré' : 'Optimal');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: statusColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                "État actuel",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Humidité sol",
                  "$humidite%",
                  Icons.opacity,
                  statusColor,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Besoin en eau",
                  "${besoin}L/m²",
                  Icons.water,
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Dernière irrigation",
                  _irrigationData?['derniereIrrigation'] ?? 'N/A',
                  Icons.schedule,
                  Colors.grey,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Prochaine",
                  _irrigationData?['prochaineIrrigation'] ?? 'À définir',
                  Icons.event,
                  Colors.purple,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValveControlSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.settings_input_component,
                color: Colors.blue,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                "Contrôle des Vannes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildValveSwitch("Vanne Principale", true, isDark),
          _buildValveSwitch("Secteur Nord", false, isDark),
          _buildValveSwitch("Secteur Sud", false, isDark),
        ],
      ),
    );
  }

  Widget _buildValveSwitch(String label, bool value, bool isDark) {
    // This state should ideally be managed, but for mock UI we use a StatefulWidget item or just stateless with internal state logic here
    // Since this is a big page state, I'll just use a Stateful builder or simplier, I'll make it static for now as mock.
    // Better: use a local variable map or just StatefulBuilder.
    return StatefulBuilder(
      builder: (context, setState) {
        return SwitchListTile(
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          value: value,
          activeColor: Colors.blue,
          onChanged: (newValue) {
            setState(() => value = newValue);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$label ${newValue ? 'activée' : 'désactivée'}"),
                duration: const Duration(milliseconds: 500),
              ),
            );
          },
          secondary: Icon(
            Icons.water,
            color: value ? Colors.blue : Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildProgramSection(bool isDark) {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Programme d'irrigation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _autoMode,
                onChanged: (value) => setState(() => _autoMode = value),
                activeColor: Colors.green,
              ),
            ],
          ),
          if (_autoMode)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Mode automatique activé - L'IA gère l'irrigation",
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            "Heure de démarrage",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (time != null) {
                setState(() => _startTime = time);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    _startTime.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Durée (minutes)",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 10,
            max: 120,
            divisions: 11,
            label: "$_durationMinutes min",
            activeColor: Colors.blue,
            onChanged: (value) =>
                setState(() => _durationMinutes = value.toInt()),
          ),
          Center(
            child: Text(
              "$_durationMinutes minutes",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Jours d'irrigation",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                    }
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.grey),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    final recommendations =
        _irrigationData?['recommandations'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                "Recommandations IA",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendations.isEmpty)
            _buildRecommendationItem(
              "Basé sur la météo et l'humidité actuelle, nous recommandons d'irriguer demain matin.",
              Icons.wb_sunny,
              Colors.orange,
              isDark,
            )
          else
            ...recommendations.map(
              (r) => _buildRecommendationItem(
                r['message'] ?? r.toString(),
                Icons.tips_and_updates,
                Colors.blue,
                isDark,
              ),
            ),
          _buildRecommendationItem(
            "Économie estimée: 20% d'eau grâce au mode automatique",
            Icons.savings,
            Colors.green,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String text,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveProgram,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text(
              "Enregistrer le programme",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _startIrrigationNow,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.green, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              "Démarrer l'irrigation maintenant",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            "Sélectionnez une parcelle",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choisissez une parcelle pour configurer son programme d'irrigation",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProgram() async {
    if (_selectedParcelleId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = di.sl<ApiClient>();
      final response = await apiClient.post(
        '/recommandations/irrigation/calculate',
        data: {
          'parcelleId': _selectedParcelleId,
          'heureDebut':
              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
          'dureeMinutes': _durationMinutes,
          'joursIrrigation': _selectedDays,
          'modeAuto': _autoMode,
        },
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['success'] == true
                  ? 'Programme enregistré avec succès'
                  : response.data['message'] ?? 'Erreur',
            ),
            backgroundColor: response.data['success'] == true
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startIrrigationNow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 12),
            Text("Démarrer l'irrigation"),
          ],
        ),
        content: Text(
          "Voulez-vous démarrer l'irrigation immédiatement pour une durée de $_durationMinutes minutes ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Irrigation démarrée !"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Démarrer"),
          ),
        ],
      ),
    );
  }
}
