import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/recommandations/presentation/bloc/recommandation_bloc.dart';

/// Section displaying recommendations on the dashboard
class RecommandationsSection extends StatelessWidget {
  const RecommandationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommandationBloc, RecommandationState>(
      builder: (context, state) {
        if (state is RecommandationLoaded) {
          final recommandations = state.recommandations.take(3).toList();
          if (recommandations.isEmpty) {
            return const EmptyCard(
              icon: Icons.check_circle_outline,
              title: "Aucune recommandation",
              subtitle: "Tout est en ordre !",
              color: Colors.green,
            );
          }
          return Column(
            children: [
              ...recommandations.map(
                (r) => RecommandationCard(recommandation: r),
              ),
              if (state.recommandations.length > 3)
                TextButton.icon(
                  onPressed: () => context.push('/recommandations'),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    "Voir ${state.recommandations.length - 3} autres",
                  ),
                ),
            ],
          );
        }
        if (state is RecommandationLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return const EmptyCard(
          icon: Icons.lightbulb_outline,
          title: "Recommandations",
          subtitle: "Chargement...",
          color: Colors.orange,
        );
      },
    );
  }
}

/// Individual recommendation card
class RecommandationCard extends StatelessWidget {
  final dynamic recommandation;

  const RecommandationCard({super.key, required this.recommandation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = _getIconAndColor(
      recommandation.priorite?.toLowerCase() ?? 'normale',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommandation.titre ?? 'Recommandation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (recommandation.description != null)
                  Text(
                    recommandation.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getIconAndColor(String priority) {
    return switch (priority) {
      'haute' || 'urgente' => (Icons.warning_amber_rounded, Colors.red),
      'moyenne' => (Icons.info_outline, Colors.orange),
      _ => (Icons.lightbulb_outline, Colors.green),
    };
  }
}

/// Empty state card
class EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
