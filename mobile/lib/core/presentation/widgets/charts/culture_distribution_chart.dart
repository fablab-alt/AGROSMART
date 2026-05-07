import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CultureDistributionChart extends StatefulWidget {
  final List<dynamic> data; // {name: String, value: double, color: String?}

  const CultureDistributionChart({super.key, required this.data});

  @override
  State<CultureDistributionChart> createState() =>
      _CultureDistributionChartState();
}

class _CultureDistributionChartState extends State<CultureDistributionChart> {
  int touchedIndex = -1;

  // Default colors from Web
  static const List<Color> defaultColors = [
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Orange/Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text("Aucune culture"));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          const SizedBox(height: 18),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color =
                  Utils.hexToColor(item['color']) ??
                  defaultColors[index % defaultColors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(item['value'] as num).toDouble().toStringAsFixed(1)} ha',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final item = widget.data[i];
      final color =
          Utils.hexToColor(item['color']) ??
          defaultColors[i % defaultColors.length];
      final value = (item['value'] as num).toDouble();

      return PieChartSectionData(
        color: color,
        value: value,
        title:
            '${value.toStringAsFixed(0)}%', // Ideally percentage, but data seems to be ha directly.
        // If data is ha, we should calculating percentage?
        // Web code: dataKey="value" and in label shows ha.
        // Chart itself shows slices relative to total.
        // Let's just show value or empty.
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: shadows,
        ),
        radius: radius,
        showTitle: false, // Cleaner look
      );
    });
  }
}

class Utils {
  static Color? hexToColor(String? hexString) {
    if (hexString == null) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }
}
