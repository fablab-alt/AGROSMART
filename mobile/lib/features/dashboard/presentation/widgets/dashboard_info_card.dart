import 'package:flutter/material.dart';

/// Reusable info card widget for displaying dashboard metrics
/// Used in overview cards section
class DashboardInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isYellow;
  final VoidCallback? onTap;

  const DashboardInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isYellow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark
        ? (isYellow ? const Color(0xFFFFD54F) : const Color(0xFF81C784))
        : (isYellow ? Colors.orange[800] : Colors.green[800]);

    final semanticLabel = '${title.replaceAll('\n', ' ')}: $value';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140,
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.5 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: color, size: 24, semanticLabel: null),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid layout for multiple info cards
class DashboardInfoCardsGrid extends StatelessWidget {
  final List<DashboardInfoCard> cards;
  final double spacing;

  const DashboardInfoCardsGrid({
    super.key,
    required this.cards,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}
