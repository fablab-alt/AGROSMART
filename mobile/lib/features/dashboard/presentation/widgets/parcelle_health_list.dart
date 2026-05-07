import 'package:flutter/material.dart';
import '../../../parcelles/domain/entities/parcelle.dart';
import 'package:go_router/go_router.dart';

class ParcelleHealthList extends StatefulWidget {
  final List<Parcelle> parcelles;

  const ParcelleHealthList({super.key, required this.parcelles});

  @override
  State<ParcelleHealthList> createState() => _ParcelleHealthListState();
}

class _ParcelleHealthListState extends State<ParcelleHealthList> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.parcelles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Match dashboard padding
          child: const Text(
            'Mes Parcelles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal list of tabs/chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.parcelles.length,
            itemBuilder: (context, index) {
              final parcelle = widget.parcelles[index];
              final isSelected = index == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(parcelle.nom),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    }
                  },
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.green.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Selected Parcelle Details Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildParcelleCard(widget.parcelles[_selectedIndex]),
        ),
      ],
    );
  }

  Widget _buildParcelleCard(Parcelle parcelle) {
    final healthInfo = _getHealthInfo(parcelle.sante);
    
    return InkWell(
      onTap: () => context.push('/parcelles/details/${parcelle.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: healthInfo.color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: healthInfo.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcelle.culture,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${parcelle.superficie} ${parcelle.uniteSuperficie}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: healthInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: healthInfo.color),
                  ),
                  child: Row(
                    children: [
                      Icon(healthInfo.icon, size: 16, color: healthInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        healthInfo.label,
                        style: TextStyle(
                          color: healthInfo.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  Icons.water_drop, 
                  '${parcelle.humidite ?? "--"}%', 
                  'Humidité', 
                  Colors.blue
                ),
                _buildMetric(
                  Icons.thermostat, 
                  '${parcelle.temperature ?? "--"}°C', 
                  'Température', 
                  Colors.orange
                ),
                _buildMetric(
                  Icons.grass, 
                  parcelle.typeSol, 
                  'Sol', 
                  Colors.brown
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  HealthInfo _getHealthInfo(ParcelleHealth sante) {
    switch (sante) {
      case ParcelleHealth.optimal:
        return HealthInfo(
          color: Colors.green, 
          label: 'Optimal', 
          icon: Icons.check_circle
        );
      case ParcelleHealth.surveillance:
        return HealthInfo(
          color: Colors.orange, 
          label: 'Surveillance', 
          icon: Icons.warning
        );
      case ParcelleHealth.critique:
        return HealthInfo(
          color: Colors.red, 
          label: 'Critique', 
          icon: Icons.error
        );
    }
  }
}

class HealthInfo {
  final Color color;
  final String label;
  final IconData icon;

  HealthInfo({required this.color, required this.label, required this.icon});
}
