import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SensorHistoryChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final Color color;
  final String unit;

  const SensorHistoryChart({
    super.key,
    required this.data,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("Aucune donnée historique"));
    }

    // Calculer min et max pour l'échelle Y
    double minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    // Ajouter une marge
    double margin = (maxY - minY) * 0.2;
    if (margin == 0) margin = 5; // Cas où toutes les valeurs sont égales

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: margin > 0 ? margin : 1,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: Color(0xFFE5E7EB),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < data.length) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data[value.toInt()].label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: margin > 0 ? margin : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (data.length - 1).toDouble(),
            minY: minY - margin,
            maxY: maxY + margin,
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.value);
                }).toList(),
                isCurved: true,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final flSpot = barSpot;
                    return LineTooltipItem(
                      '${flSpot.y.toStringAsFixed(1)} $unit',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}
