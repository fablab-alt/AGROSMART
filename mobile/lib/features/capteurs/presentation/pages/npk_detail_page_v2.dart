import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/sensor.dart';

/// Page de détail améliorée pour le capteur NPK
/// Permet de visualiser chaque composé séparément avec historique et graphiques
class NpkDetailPageV2 extends StatefulWidget {
  final Sensor capteur;

  const NpkDetailPageV2({super.key, required this.capteur});

  @override
  State<NpkDetailPageV2> createState() => _NpkDetailPageV2State();
}

class _NpkDetailPageV2State extends State<NpkDetailPageV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7j';

  // Données simulées pour l'historique (à remplacer par API)
  final Map<String, List<NPKDataPoint>> _historicalData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateMockData();
  }

  void _generateMockData() {
    final now = DateTime.now();
    _historicalData['nitrogen'] = List.generate(
      7,
      (i) => NPKDataPoint(
        date: now.subtract(Duration(days: 6 - i)),
        value: 80 + (i * 5) + (i % 2 == 0 ? 10 : -5).toDouble(),
      ),
    );
    _historicalData['phosphorus'] = List.generate(
      7,
      (i) => NPKDataPoint(
        date: now.subtract(Duration(days: 6 - i)),
        value: 45 + (i * 3) + (i % 2 == 0 ? 5 : -3).toDouble(),
      ),
    );
    _historicalData['potassium'] = List.generate(
      7,
      (i) => NPKDataPoint(
        date: now.subtract(Duration(days: 6 - i)),
        value: 180 + (i * 8) + (i % 2 == 0 ? 15 : -10).toDouble(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar avec gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF4CAF50),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.capteur.nom,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.capteur.parcelleNom ??
                                        'Parcelle non assignée',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatusBadge(
                              'Batterie ${widget.capteur.niveauBatterie.toInt()}%',
                              Icons.battery_std,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(
                              widget.capteur.signalForce,
                              Icons.signal_cellular_alt,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(
                              _getStatusText(widget.capteur.status),
                              Icons.check_circle,
                              color: _getStatusColor(widget.capteur.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Données actualisées')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsBottomSheet(context),
              ),
            ],
          ),

          // Tabs pour chaque composé
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: isDark ? Colors.white : const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4CAF50),
                tabs: const [
                  Tab(text: 'Vue globale'),
                  Tab(text: 'Azote (N)'),
                  Tab(text: 'Phosphore (P)'),
                  Tab(text: 'Potassium (K)'),
                ],
              ),
              isDark ? Theme.of(context).cardColor : Colors.white,
            ),
          ),

          // Contenu des tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildElementTab(
                  'nitrogen',
                  'Azote (N)',
                  Colors.blue,
                  widget.capteur.nitrogen ?? 0,
                  50,
                  200,
                ),
                _buildElementTab(
                  'phosphorus',
                  'Phosphore (P)',
                  Colors.orange,
                  widget.capteur.phosphorus ?? 0,
                  30,
                  100,
                ),
                _buildElementTab(
                  'potassium',
                  'Potassium (K)',
                  Colors.purple,
                  widget.capteur.potassium ?? 0,
                  150,
                  300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
        return 'Actif';
      case 'warning':
        return 'Attention';
      case 'critical':
      case 'defaillant':
        return 'Critique';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'active':
        return Colors.greenAccent;
      case 'warning':
        return Colors.orangeAccent;
      case 'critical':
      case 'defaillant':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  /// Tab vue globale avec les 3 éléments
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de résumé
          _buildSummaryCard(),
          const SizedBox(height: 20),

          // Grille des 3 éléments
          const Text(
            'Valeurs actuelles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildElementCard(
                  'N',
                  'Azote',
                  widget.capteur.nitrogen ?? 0,
                  Colors.blue,
                  50,
                  200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildElementCard(
                  'P',
                  'Phosphore',
                  widget.capteur.phosphorus ?? 0,
                  Colors.orange,
                  30,
                  100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildElementCard(
                  'K',
                  'Potassium',
                  widget.capteur.potassium ?? 0,
                  Colors.purple,
                  150,
                  300,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Graphique comparatif
          const Text(
            'Évolution comparée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildComparisonChart(),

          const SizedBox(height: 24),

          // Interprétation IA
          _buildAIInterpretation(),

          const SizedBox(height: 24),

          // Recommandations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasData =
        widget.capteur.nitrogen != null ||
        widget.capteur.phosphorus != null ||
        widget.capteur.potassium != null;
    final n = widget.capteur.nitrogen ?? 0;
    final p = widget.capteur.phosphorus ?? 0;
    final k = widget.capteur.potassium ?? 0;

    String overallStatus;
    Color statusColor;
    String statusIcon;

    if (!hasData) {
      overallStatus = 'Pas de données';
      statusColor = Colors.grey;
      statusIcon = '?';
    } else if (n < 30 || p < 20 || k < 100) {
      overallStatus = 'Carence sévère';
      statusColor = Colors.red;
      statusIcon = '✗';
    } else if (n < 50 || p < 30 || k < 150) {
      overallStatus = 'Carence détectée';
      statusColor = Colors.orange;
      statusIcon = '⚠';
    } else {
      overallStatus = 'Optimal';
      statusColor = Colors.green;
      statusIcon = '✓';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  statusIcon,
                  style: TextStyle(fontSize: 28, color: statusColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'État général du sol',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overallStatus,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dernière mesure: ${_formatDate(widget.capteur.lastUpdate)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementCard(
    String symbol,
    String name,
    double value,
    Color color,
    double min,
    double max,
  ) {
    String status = 'Optimal';
    Color statusColor = Colors.green;

    if (value < min) {
      status = 'Faible';
      statusColor = Colors.orange;
    } else if (value > max) {
      status = 'Élevé';
      statusColor = Colors.red;
    }

    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      symbol,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'mg/kg',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$min - $max',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de période
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildPeriodButton('24h'),
                _buildPeriodButton('7j'),
                _buildPeriodButton('30j'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLineData(
                      _historicalData['nitrogen'] ?? [],
                      Colors.blue,
                    ),
                    _buildLineData(
                      _historicalData['phosphorus'] ?? [],
                      Colors.orange,
                    ),
                    _buildLineData(
                      _historicalData['potassium'] ?? [],
                      Colors.purple,
                    ),
                  ],
                  minY: 0,
                  maxY: 300,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Légende
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Azote', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Phosphore', Colors.orange),
                const SizedBox(width: 16),
                _buildLegendItem('Potassium', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(List<NPKDataPoint> data, Color color) {
    return LineChartBarData(
      spots: data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildAIInterpretation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Analyse IA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInterpretationItem(
              'Azote (N)',
              _getInterpretation('nitrogen', widget.capteur.nitrogen ?? 0),
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInterpretationItem(
              'Phosphore (P)',
              _getInterpretation('phosphorus', widget.capteur.phosphorus ?? 0),
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildInterpretationItem(
              'Potassium (K)',
              _getInterpretation('potassium', widget.capteur.potassium ?? 0),
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  String _getInterpretation(String element, double value) {
    switch (element) {
      case 'nitrogen':
        if (value < 50)
          return 'Carence en azote. Risque de jaunissement des feuilles et retard de croissance.';
        if (value > 200)
          return 'Excès d\'azote. Risque de croissance excessive et vulnérabilité aux maladies.';
        return 'Niveau optimal. Favorise une bonne croissance végétative.';
      case 'phosphorus':
        if (value < 30)
          return 'Carence en phosphore. Peut affecter le développement racinaire et la floraison.';
        if (value > 100)
          return 'Excès de phosphore. Peut bloquer l\'absorption d\'autres nutriments.';
        return 'Niveau optimal. Bon développement des racines et des fruits.';
      case 'potassium':
        if (value < 150)
          return 'Carence en potassium. Risque de mauvaise qualité des fruits et sensibilité aux maladies.';
        if (value > 300)
          return 'Excès de potassium. Peut perturber l\'absorption du magnésium et du calcium.';
        return 'Niveau optimal. Bonne résistance aux stress et qualité des récoltes.';
      default:
        return 'Données insuffisantes pour l\'analyse.';
    }
  }

  Widget _buildInterpretationItem(
    String title,
    String interpretation,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  interpretation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Recommandations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationItem(
              'Fertilisation',
              'Appliquer un engrais NPK équilibré (15-15-15) à raison de 200g/plant.',
              Icons.eco,
            ),
            _buildRecommendationItem(
              'Prochaine mesure',
              'Effectuer une nouvelle analyse dans 2 semaines pour suivre l\'évolution.',
              Icons.schedule,
            ),
            _buildRecommendationItem(
              'Amendement',
              'Considérer l\'ajout de matière organique pour améliorer la structure du sol.',
              Icons.yard,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/recommandations');
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Voir toutes les recommandations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab pour un élément spécifique (N, P ou K)
  Widget _buildElementTab(
    String key,
    String name,
    Color color,
    double value,
    double min,
    double max,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de valeur actuelle
          _buildCurrentValueCard(name, value, color, min, max),
          const SizedBox(height: 20),

          // Graphique historique
          const Text(
            'Historique',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSingleElementChart(key, color),

          const SizedBox(height: 20),

          // Statistiques
          _buildStatisticsCard(key, color),

          const SizedBox(height: 20),

          // Seuils et plages
          _buildThresholdsCard(name, color, min, max),
        ],
      ),
    );
  }

  Widget _buildCurrentValueCard(
    String name,
    double value,
    Color color,
    double min,
    double max,
  ) {
    String status = 'Optimal';
    if (value < min) status = 'Faible';
    if (value > max) status = 'Élevé';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'mg/kg',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleElementChart(String key, Color color) {
    final data = _historicalData[key] ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildPeriodButton('24h'),
                _buildPeriodButton('7j'),
                _buildPeriodButton('30j'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 30,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.length) {
                            final date = data[value.toInt()].date;
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                          .toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.3),
                            color.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(String key, Color color) {
    final data = _historicalData[key] ?? [];
    if (data.isEmpty) return const SizedBox();

    final values = data.map((d) => d.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques (7 derniers jours)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Moyenne',
                    avg.toStringAsFixed(1),
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Min',
                    minVal.toStringAsFixed(1),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Max',
                    maxVal.toStringAsFixed(1),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text('mg/kg', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildThresholdsCard(
    String name,
    Color color,
    double minOptimal,
    double maxOptimal,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plages de référence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildThresholdRow('Carence', '< $minOptimal mg/kg', Colors.orange),
            _buildThresholdRow(
              'Optimal',
              '$minOptimal - $maxOptimal mg/kg',
              Colors.green,
            ),
            _buildThresholdRow('Excès', '> $maxOptimal mg/kg', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres du capteur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Alertes de seuil'),
              subtitle: const Text(
                'Recevoir une alerte si les valeurs sortent des plages',
              ),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Fréquence de mesure'),
              subtitle: const Text('Toutes les 6 heures'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exporter les données'),
              subtitle: const Text('Format CSV ou Excel'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Délégué pour le header persistant avec les tabs
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverAppBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

/// Modèle de données pour un point NPK
class NPKDataPoint {
  final DateTime date;
  final double value;

  NPKDataPoint({required this.date, required this.value});
}
