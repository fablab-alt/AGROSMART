import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PestMapPage extends StatefulWidget {
  const PestMapPage({super.key});

  @override
  State<PestMapPage> createState() => _PestMapPageState();
}

class _PestMapPageState extends State<PestMapPage> {
  // Mock data matching backend simulation
  final List<HeatPoint> _points = [
    HeatPoint(LatLng(5.3600, -4.0083), 1.0, 'Mildiou'),
    HeatPoint(LatLng(5.3700, -4.0183), 0.6, 'Rouille'),
    HeatPoint(LatLng(5.3500, -3.9983), 0.9, 'Chenille'),
    HeatPoint(LatLng(5.3800, -4.0283), 0.7, 'Mildiou'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte des Risques"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(5.3600, -4.0083), // Abidjan
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agrismart.app',
              ),
              // Simulating Heatmap with CircleMarkers for now (flutter_map_heatmap might not be installed)
              CircleLayer(
                circles: _points.map((p) => CircleMarker(
                  point: p.location,
                  radius: p.intensity * 20, // Size based on intensity
                  useRadiusInMeter: true,
                  color: _getColorForDisease(p.disease).withOpacity(0.5 * p.intensity),
                  borderColor: _getColorForDisease(p.disease),
                  borderStrokeWidth: 1,
                )).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Mildiou', Colors.red),
                    _buildLegendItem('Rouille', Colors.orange),
                    _buildLegendItem('Autre', Colors.purple),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getColorForDisease(String disease) {
    switch (disease.toLowerCase()) {
      case 'mildiou': return Colors.red;
      case 'rouille': return Colors.orange;
      default: return Colors.purple;
    }
  }
}

class HeatPoint {
  final LatLng location;
  final double intensity;
  final String disease;

  HeatPoint(this.location, this.intensity, this.disease);
}
