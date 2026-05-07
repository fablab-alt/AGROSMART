import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/analytics_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/analytics_data.dart';


class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(LoadAnalytics()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Mes statistiques'),
          // Let AppBar theme handle colors or keep specific brand color but ensure contrast
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AnalyticsBloc>().add(LoadAnalytics());
              },
            ),
          ],
        ),
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is AnalyticsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFriendlyErrorMessage(state.message),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AnalyticsBloc>().add(LoadAnalytics()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is AnalyticsLoaded) {
              return _buildContent(context, state.data);
            }
            
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalyticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROI Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Retour sur Investissement',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data.roiTrend,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.roiPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Stats from RendementData and Economies
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                'Rendement',
                data.rendementData.value,
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Eau économisée',
                '${data.economies.eau.toInt()} L',
                Icons.water_drop,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Engrais réduits',
                 '${data.economies.engrais.toInt()} kg',
                Icons.grass,
                Colors.amber,
              ),
              _buildStatCard(
                context,
                'Pertes évitées',
                '${data.economies.pertesEvitees.toInt()} FCFA',
                Icons.health_and_safety,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rendements par culture
          if (data.rendementesParCulture.isNotEmpty) ...[
            const Text(
              'Rendements par culture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.rendementesParCulture.map((yield) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            yield.culture,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${yield.improvement}%',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Actuel',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${yield.rendementActuel} T/ha',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Objectif',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${yield.rendementObjectif} T/ha',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],

          // Économies
          const Text(
            'Économies réalisées',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildEconomyRow(context, 'Eau', data.economies.eau),
                const Divider(),
                _buildEconomyRow(context, 'Engrais', data.economies.engrais),
                const Divider(),
                _buildEconomyRow(context, 'Pertes évitées', data.economies.pertesEvitees),
                const Divider(thickness: 2),
                _buildEconomyRow(
                  context,
                  'Total',
                  data.economies.total,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Performance des parcelles
          if (data.performanceParcelles.isNotEmpty) ...[
            const Text(
              'Performance des parcelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.performanceParcelles.map((perf) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          perf.nom,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                       // Assuming scoreQualite is what we want here, normalized to 0-1 if needed, or if it is 0-100 divide by 100
                      CircularProgressIndicator(
                        value: perf.scoreQualite / 100,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          perf.scoreQualite >= 50 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${perf.scoreQualite.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: perf.scoreQualite >= 50 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Reduced font size slightly to fit
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomyRow(BuildContext context, String label, double amount, {bool isTotal = false}) {
     // Determine color for Amount text
    Color amountColor;
    if (isTotal) {
      amountColor = Theme.of(context).brightness == Brightness.dark 
          ? Colors.greenAccent 
          : Colors.indigo;
    } else {
      amountColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                ),
          ),
          Text(
            // Handle double -> String formatting
            '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }


  String _getFriendlyErrorMessage(String originalMessage) {
    if (originalMessage.contains('500') || originalMessage.contains('Server error')) {
      return "Le serveur rencontre des difficultés momentanées. Veuillez réessayer plus tard.";
    }
    if (originalMessage.contains('connection') || originalMessage.contains('SocketException')) {
      return "Vérifiez votre connexion internet.";
    }
    return "Une erreur est survenue lors du chargement des données.";
  }
}
