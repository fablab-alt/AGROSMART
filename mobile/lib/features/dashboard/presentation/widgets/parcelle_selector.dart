import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'package:agriculture/features/parcelles/domain/entities/parcelle.dart';

/// Horizontal selector for choosing parcelles
class ParcelleSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const ParcelleSelector({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoaded && state.parcelles.isNotEmpty) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(state.parcelles.length, (index) {
                final isSelected = index == selectedIndex;
                final parcelle = state.parcelles[index];
                return _ParcelleSelectorItem(
                  parcelle: parcelle,
                  index: index,
                  isSelected: isSelected,
                  onTap: () => onIndexChanged(index),
                );
              }),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Aucune parcelle enregistrée",
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
}

class _ParcelleSelectorItem extends StatelessWidget {
  final Parcelle parcelle;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _ParcelleSelectorItem({
    required this.parcelle,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF28A745) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF28A745).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
            border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            parcelle.nom.isNotEmpty ? parcelle.nom : "Parcelle ${index + 1}",
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Detailed card showing selected parcelle information
class ParcelleDetailCard extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onViewDetails;

  const ParcelleDetailCard({
    super.key,
    required this.selectedIndex,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParcelleBloc, ParcelleState>(
      builder: (context, state) {
        if (state is ParcelleLoaded && state.parcelles.isNotEmpty) {
          final safeIndex = selectedIndex < state.parcelles.length
              ? selectedIndex
              : 0;
          final parcelle = state.parcelles[safeIndex];
          return _ParcelleDetailContent(
            parcelle: parcelle,
            onViewDetails: onViewDetails,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ParcelleDetailContent extends StatelessWidget {
  final Parcelle parcelle;
  final VoidCallback? onViewDetails;

  const _ParcelleDetailContent({required this.parcelle, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthStatus = _getHealthStatus(parcelle, isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: healthStatus.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: healthStatus.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcelle.nom.isNotEmpty
                          ? parcelle.nom
                          : "Parcelle sans nom",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.crop_free,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${parcelle.superficie} ha",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.eco, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            parcelle.cultureActuelle?.nom ??
                                parcelle.cultureLegacy ??
                                "Aucune culture",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                status: healthStatus.statusText,
                color: healthStatus.statusColor,
                dotColor: healthStatus.dotColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            healthStatus.description,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (onViewDetails != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: healthStatus.statusColor,
                side: BorderSide(color: healthStatus.statusColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Voir les détails"),
            ),
          ],
        ],
      ),
    );
  }

  _HealthStatus _getHealthStatus(Parcelle parcelle, bool isDark) {
    final santeStr = parcelle.sante.toString().split('.').last.toLowerCase();

    if (santeStr == 'optimal') {
      return _HealthStatus(
        statusColor: isDark ? const Color(0xFF81C784) : const Color(0xFF28A745),
        bgColor: isDark
            ? const Color(0xFF1B5E20).withOpacity(0.3)
            : const Color(0xFFE8F5E9),
        statusText: "Optimal",
        description:
            "Tout est nickel ! Le sol est en bonne santé, les plantes poussent bien.",
        dotColor: Colors.green,
      );
    } else if (santeStr == 'critique') {
      return _HealthStatus(
        statusColor: isDark ? const Color(0xFFE57373) : const Color(0xFFDC3545),
        bgColor: isDark
            ? const Color(0xFFB71C1C).withOpacity(0.3)
            : const Color(0xFFFFEBEE),
        statusText: "Critique",
        description:
            "Aïe ! Le sol n'est pas bon du tout. Les plantes peuvent avoir du mal à pousser. Faut réagir vite.",
        dotColor: Colors.red,
      );
    } else {
      return _HealthStatus(
        statusColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800),
        bgColor: isDark
            ? const Color(0xFFE65100).withOpacity(0.3)
            : const Color(0xFFFFF3E0),
        statusText: "Surveillance",
        description:
            "Y'a quelques petits soucis à surveiller. Rien de grave, mais vaut mieux garder l'œil ouvert.",
        dotColor: Colors.orange,
      );
    }
  }
}

class _HealthStatus {
  final Color statusColor;
  final Color bgColor;
  final String statusText;
  final String description;
  final Color dotColor;

  const _HealthStatus({
    required this.statusColor,
    required this.bgColor,
    required this.statusText,
    required this.description,
    required this.dotColor,
  });
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final Color dotColor;

  const _StatusBadge({
    required this.status,
    required this.color,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
