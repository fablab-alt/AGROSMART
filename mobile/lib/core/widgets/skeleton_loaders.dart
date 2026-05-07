import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Collection of skeleton loaders for consistent loading states
/// Uses shimmer effect for smooth loading animations

/// Generic skeleton container with shimmer effect
class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const SkeletonContainer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets margin;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonContainer(
      width: width,
      height: height,
      margin: margin,
      borderRadius: const BorderRadius.all(Radius.circular(4)),
    );
  }
}

/// Skeleton for circular avatar
class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton for cards (parcelle, product, etc.)
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonAvatar(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                    const SkeletonText(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SkeletonText(width: double.infinity),
          const SkeletonText(width: 200),
        ],
      ),
    );
  }
}

/// Skeleton for list items
class SkeletonListItem extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final double height;
  final EdgeInsets margin;

  const SkeletonListItem({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.height = 72,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (hasLeading) ...[
            const SkeletonAvatar(size: 48),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 16,
                ),
                const SizedBox(height: 4),
                const SkeletonText(width: 120, height: 12),
              ],
            ),
          ),
          if (hasTrailing)
            const SkeletonContainer(
              width: 60,
              height: 24,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
        ],
      ),
    );
  }
}

/// Skeleton for product/marketplace cards
class SkeletonProductCard extends StatelessWidget {
  final double imageHeight;

  const SkeletonProductCard({super.key, this.imageHeight = 150});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonContainer(
            height: imageHeight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(width: double.infinity, height: 16),
                const SkeletonText(width: 80, height: 12),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SkeletonText(width: 60, height: 20),
                    SkeletonContainer(
                      width: 32,
                      height: 32,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for dashboard stats grid
class SkeletonStatsGrid extends StatelessWidget {
  final int itemCount;

  const SkeletonStatsGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          itemCount,
          (index) => Container(
            width: 140,
            height: 100,
            margin: const EdgeInsets.only(right: 12),
            child: SkeletonContainer(
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton wrapper for loading lists
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
  });

  /// Factory for list items skeleton
  factory SkeletonList.listItems({
    Key? key,
    int itemCount = 5,
    bool hasLeading = true,
    bool hasTrailing = false,
  }) {
    return SkeletonList(
      key: key,
      itemCount: itemCount,
      itemBuilder: (_, _) =>
          SkeletonListItem(hasLeading: hasLeading, hasTrailing: hasTrailing),
    );
  }

  /// Factory for cards skeleton
  factory SkeletonList.cards({
    Key? key,
    int itemCount = 3,
    double cardHeight = 120,
  }) {
    return SkeletonList(
      key: key,
      itemCount: itemCount,
      itemBuilder: (_, _) => SkeletonCard(height: cardHeight),
    );
  }

  /// Factory for product grid skeleton
  factory SkeletonList.productGrid({Key? key, int itemCount = 4}) {
    return SkeletonList(
      key: key,
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonProductCard(),
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => itemBuilder(context, index),
        ),
      ),
    );
  }
}

/// Mixin to add skeleton loading state to widgets
mixin SkeletonLoaderMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  /// Builds content or skeleton based on loading state
  Widget buildWithSkeleton({
    required Widget content,
    required Widget skeleton,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLoading ? skeleton : content,
    );
  }
}
