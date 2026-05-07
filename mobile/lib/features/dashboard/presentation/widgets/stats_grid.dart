import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_data.dart';

class StatsGrid extends StatelessWidget {
  final Stats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Rendement', '${stats.yield} t/ha', Icons.agriculture, Colors.green),
        _buildStatCard('ROI', '+${stats.roi}%', Icons.trending_up, Colors.blue),
        _buildStatCard('Santé Sol', '${stats.soilHealth}/100', Icons.grass, Colors.brown),
        _buildStatCard('Eau', '-30%', Icons.water_drop_outlined, Colors.cyan),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
