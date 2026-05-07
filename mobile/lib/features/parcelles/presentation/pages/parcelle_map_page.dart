import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

class ParcelleMapPage extends StatefulWidget {
  final List<Parcelle> parcelles;

  const ParcelleMapPage({super.key, required this.parcelles});

  @override
  State<ParcelleMapPage> createState() => _ParcelleMapPageState();
}

class _ParcelleMapPageState extends State<ParcelleMapPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // Calculate center
    LatLng center = const LatLng(5.35, -4.00); // Abidjan default
    if (widget.parcelles.isNotEmpty) {
      double lat = 0;
      double lon = 0;
      int count = 0;
      for (var p in widget.parcelles) {
        if (p.latitude != null && p.longitude != null && p.latitude != 0 && p.longitude != 0) {
          lat += p.latitude!;
          lon += p.longitude!;
          count++;
        }
      }
      if (count > 0) {
        center = LatLng(lat / count, lon / count);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Parcelles'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.agrismart.app',
          ),
          MarkerLayer(
            markers: widget.parcelles
                .where((p) => p.latitude != null && p.longitude != null && p.latitude != 0)
                .map((p) {
              return Marker(
                point: LatLng(p.latitude!, p.longitude!),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
                      ),
                      child: Text(
                        p.nom,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
