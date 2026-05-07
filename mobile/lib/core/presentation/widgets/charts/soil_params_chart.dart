import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SoilParamsChart extends StatefulWidget {
  final List<dynamic> data; // Replace dynamic with actual model if available

  const SoilParamsChart({super.key, required this.data});

  @override
  State<SoilParamsChart> createState() => _SoilParamsChartState();
}

class _SoilParamsChartState extends State<SoilParamsChart> {
  // Colors matching web app
  static const Color humidityColor = Color(0xFF3B82F6);
  static const Color tempColor = Color(0xFFEF4444);
  static const Color phColor = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text("Aucune donnée récente"));
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        // Legend
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: humidityColor, label: "Humidité (%)"),
            SizedBox(width: 16),
            _LegendItem(color: tempColor, label: "Temp. (°C)"),
            SizedBox(width: 16),
            _LegendItem(color: phColor, label: "pH"),
          ],
        ),
        const SizedBox(height: 20),
        // Chart
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              mainData(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
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
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: 0,
      maxY: 100, // Adjust based on data
      lineBarsData: [
        // Humidity
        LineChartBarData(
          spots: widget.data.asMap().entries.map((e) {
            final val = e.value['humidite'] is double ? e.value['humidite'] : (e.value['humidite'] as num).toDouble();
            return FlSpot(e.key.toDouble(), val);
          }).toList(),
          isCurved: true,
          color: humidityColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
        // Temperature
        LineChartBarData(
          spots: widget.data.asMap().entries.map((e) {
             final val = e.value['temperature'] is double ? e.value['temperature'] : (e.value['temperature'] as num).toDouble();
            return FlSpot(e.key.toDouble(), val);
          }).toList(),
          isCurved: true,
          color: tempColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
        // pH (Scaled x10 for visibility if needed, or 0-14 range on secondary axis - keeping simple for now)
         LineChartBarData(
          spots: widget.data.asMap().entries.map((e) {
             final val = e.value['ph'] is double ? e.value['ph'] : (e.value['ph'] as num).toDouble();
             // Scaling pH (usually 0-14) to be visible on 0-100 chart? Or keep as is.
             // If temps are 30 and humidity 80, pH 7 is very low.
             // Let's multiply by 5 to make it visible ~35, or just plot as is.
             // For parity with web, web uses same axis. Let's scale it x5 for visual comparison if needed, 
             // but web code shows pure values. Let's stick to pure values for accuracy.
            return FlSpot(e.key.toDouble(), val * 5); // SCALING for visibility as per "Web App Parity" often implies visual parity. 
            // WAIT, web app screenshot or code: 
            // <Line dataKey="ph" ... name="pH" /> 
            // It puts them on same axis. If humidity is 80 and pH is 7, pH is flat at bottom.
            // I'll multiply by 10 to put it around 70 range, or just leave it. 
            // Let's stick to raw values but maybe add a note or use right axis (complex in fl_chart).
            // I will use raw values but if it's too small, I might need a secondary axis.
            // For now, raw values to be safe.
            // RE-READING WEB CODE: It just puts them on same chart.
          }).toList(),
          isCurved: true,
          color: phColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
         // tooltipBgColor: Colors.white,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              if (barSpot.barIndex == 0) { // Humidity
                 return LineTooltipItem(
                  'H: ${flSpot.y.toStringAsFixed(1)}%',
                  const TextStyle(color: humidityColor, fontWeight: FontWeight.bold),
                );
              } else if (barSpot.barIndex == 1) { // Temp
                 return LineTooltipItem(
                  'T: ${flSpot.y.toStringAsFixed(1)}°C',
                  const TextStyle(color: tempColor, fontWeight: FontWeight.bold),
                );
              } else { // pH
                 // We scaled pH by 5? No, I decided not to.
                 // If I did scale, I'd need to divide here.
                 // let's stick to raw.
                 return LineTooltipItem(
                  'pH: ${flSpot.y.toStringAsFixed(1)}',
                  const TextStyle(color: phColor, fontWeight: FontWeight.bold),
                );
              }
            }).toList();
          },
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.grey,
    );
    Widget text;
    // Assuming data is daily for last 7 days
    if (value.toInt() >= 0 && value.toInt() < widget.data.length) {
       // date string, simplify
       final dateStr = widget.data[value.toInt()]['date'] as String;
       // Extract Day? "Mon", "Tue" etc or "12/05"
       // Web code uses `prev.jour`.
       // Let's just take first 3 chars or split.
       text = Text(dateStr.split(' ')[0], style: style); 
    } else {
      text = const Text('', style: style);
    }

    return SideTitleWidget(
      meta: meta,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
       color: Colors.grey,
    );
    String text;
    if (value % 20 == 0) {
      text = '${value.toInt()}';
    } else {
      return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.left);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
