import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/parcelle.dart';

class ParcelMapWidget extends StatefulWidget {
  final List<Parcelle> parcelles;
  final Parcelle? selectedParcelle;
  final Function(Parcelle)? onParcelTap;
  final bool allowEditing;

  const ParcelMapWidget({
    super.key,
    required this.parcelles,
    this.selectedParcelle,
    this.onParcelTap,
    this.allowEditing = false,
  });

  @override
  State<ParcelMapWidget> createState() => _ParcelMapWidgetState();
}

class _ParcelMapWidgetState extends State<ParcelMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _centerPoint;

  @override
  void initState() {
    super.initState();
    _calculateCenter();
  }

  void _calculateCenter() {
    if (widget.parcelles.isEmpty) {
      // Default to Abidjan, Côte d'Ivoire
      _centerPoint = LatLng(5.3600, -4.0083);
      return;
    }

    // Calculate center from parcels with coordinates
    final parcelsWithCoords = widget.parcelles
        .where((p) => p.hasGPSCoordinates)
        .toList();

    if (parcelsWithCoords.isEmpty) {
      _centerPoint = LatLng(5.3600, -4.0083);
      return;
    }

    double sumLat = 0;
    double sumLng = 0;
    for (var p in parcelsWithCoords) {
      sumLat += p.latitude!;
      sumLng += p.longitude!;
    }

    _centerPoint = LatLng(
      sumLat / parcelsWithCoords.length,
      sumLng / parcelsWithCoords.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerPoint ?? LatLng(5.3600, -4.0083),
            initialZoom: 13.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // Tile Layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.agrismart.agriculture',
            ),

            // Parcel Polygons
            PolygonLayer(polygons: _buildPolygons()),

            // Parcel Markers (center points)
            MarkerLayer(markers: _buildMarkers()),

            // Legend
            if (widget.parcelles.isNotEmpty)
              Positioned(bottom: 16, left: 16, child: _buildLegend()),
          ],
        ),

        // Controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'center',
                onPressed: () {
                  if (_centerPoint != null) {
                    _mapController.move(_centerPoint!, 13.0);
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Polygon> _buildPolygons() {
    return widget.parcelles.where((p) => p.hasPolygonDelineation).map((
      parcelle,
    ) {
      final isSelected = widget.selectedParcelle?.id == parcelle.id;

      return Polygon(
        points: parcelle.polygonDelimitation!
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        color: _getParcelColor(
          parcelle,
        ).withValues(alpha: isSelected ? 0.4 : 0.2),
        borderColor: _getParcelColor(parcelle),
        borderStrokeWidth: isSelected ? 3.0 : 2.0,
        label: parcelle.nom,
      );
    }).toList();
  }

  List<Marker> _buildMarkers() {
    return widget.parcelles.where((p) => p.hasGPSCoordinates).map((parcelle) {
      final isSelected = widget.selectedParcelle?.id == parcelle.id;

      return Marker(
        point: LatLng(parcelle.latitude!, parcelle.longitude!),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => widget.onParcelTap?.call(parcelle),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getParcelColor(parcelle),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getCultureIcon(parcelle.cultureActuelle?.categorie),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    parcelle.nom,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Légende',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.green, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Parcelle délimitée', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Point GPS parcelle', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.parcelles.length} parcelle(s)',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _getParcelColor(Parcelle parcelle) {
    final category = parcelle.cultureActuelle?.categorie;

    switch (category) {
      case 'cereales':
        return Colors.amber;
      case 'legumineuses':
        return Colors.green;
      case 'tubercules':
        return Colors.brown;
      case 'legumes':
        return Colors.lightGreen;
      case 'fruits':
        return Colors.orange;
      case 'oleagineux':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  IconData _getCultureIcon(String? category) {
    switch (category) {
      case 'cereales':
        return Icons.grain;
      case 'legumineuses':
        return Icons.eco;
      case 'tubercules':
        return Icons.park;
      case 'legumes':
        return Icons.local_florist;
      case 'fruits':
        return Icons.apple;
      case 'oleagineux':
        return Icons.water_drop;
      default:
        return Icons.place;
    }
  }
}
