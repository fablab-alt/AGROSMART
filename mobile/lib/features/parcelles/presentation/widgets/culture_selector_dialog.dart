import 'package:flutter/material.dart';
import '../../domain/entities/parcelle.dart';

class CultureSelectorDialog extends StatefulWidget {
  final List<CultureInfo> cultures;
  final CultureInfo? selectedCulture;
  final String preferredLanguage; // 'fr', 'baoule', 'malinke', 'senoufo'

  const CultureSelectorDialog({
    super.key,
    required this.cultures,
    this.selectedCulture,
    this.preferredLanguage = 'fr',
  });

  @override
  State<CultureSelectorDialog> createState() => _CultureSelectorDialogState();
}

class _CultureSelectorDialogState extends State<CultureSelectorDialog> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categories = widget.cultures
        .map((c) => c.categorie)
        .toSet()
        .toList()
      ..sort();

    var filteredCultures = widget.cultures.where((culture) {
      final matchesSearch = _searchQuery.isEmpty ||
          culture.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (culture.nomLocalBaoule?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (culture.nomLocalMalinke?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (culture.nomLocalSenoufo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesCategory =
          _selectedCategory == null || culture.categorie == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 12),
                const Text(
                  'Sélectionner une Culture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une culture...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            // Category Filters
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('Toutes', null),
                  ...categories.map((cat) => _buildCategoryChip(_formatCategory(cat), cat)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Culture List
            Expanded(
              child: filteredCultures.isEmpty
                  ? const Center(child: Text('Aucune culture trouvée'))
                  : ListView.builder(
                      itemCount: filteredCultures.length,
                      itemBuilder: (context, index) {
                        final culture = filteredCultures[index];
                        return _buildCultureTile(culture);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
        },
        selectedColor: Colors.green.shade100,
      ),
    );
  }

  Widget _buildCultureTile(CultureInfo culture) {
    final isSelected = widget.selectedCulture?.id == culture.id;
    final localName = _getLocalName(culture);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(culture.categorie).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCategoryIcon(culture.categorie),
          color: _getCategoryColor(culture.categorie),
          size: 24,
        ),
      ),
      title: Text(
        culture.nom,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (localName != null)
            Text(
              localName,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          Text(
            culture.nomScientifique,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () => Navigator.of(context).pop(culture),
    );
  }

  String? _getLocalName(CultureInfo culture) {
    switch (widget.preferredLanguage) {
      case 'baoule':
        return culture.nomLocalBaoule;
      case 'malinke':
        return culture.nomLocalMalinke;
      case 'senoufo':
        return culture.nomLocalSenoufo;
      default:
        return null;
    }
  }

  String _formatCategory(String category) {
    final Map<String, String> labels = {
      'cereales': 'Céréales',
      'legumineuses': 'Légumineuses',
      'tubercules': 'Tubercules',
      'legumes': 'Légumes',
      'fruits': 'Fruits',
      'oleagineux': 'Oléagineux',
    };
    return labels[category] ?? category;
  }

  Color _getCategoryColor(String category) {
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
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
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
        return Icons.agriculture;
    }
  }
}
