/// Utilities for optimizing widget rebuilds with RepaintBoundary
///
/// RepaintBoundary creates a separate layer in the render tree,
/// preventing expensive repaints from propagating to or from child widgets.
library;

import 'package:flutter/material.dart';

/// Widget helper that wraps children with RepaintBoundary when appropriate.
///
/// Use this for:
/// - Complex animations that shouldn't trigger parent repaints
/// - Scrollable content with many items
/// - Widgets that update frequently but independently
/// - Complex custom painters
///
/// ```dart
/// OptimizedRepaintBoundary(
///   debugLabel: 'ComplexChart',
///   child: MyComplexChartWidget(),
/// )
/// ```
class OptimizedRepaintBoundary extends StatelessWidget {
  final Widget child;
  final String? debugLabel;

  /// Whether to enable the RepaintBoundary.
  /// Can be used to conditionally disable during development.
  final bool enabled;

  const OptimizedRepaintBoundary({
    super.key,
    required this.child,
    this.debugLabel,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return RepaintBoundary(
      child: debugLabel != null && _isDebugMode
          ? _DebugRepaintBoundary(debugLabel: debugLabel!, child: child)
          : child,
    );
  }

  static bool get _isDebugMode {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }
}

/// Debug wrapper that shows repaint count during development
class _DebugRepaintBoundary extends StatefulWidget {
  final Widget child;
  final String debugLabel;

  const _DebugRepaintBoundary({required this.child, required this.debugLabel});

  @override
  State<_DebugRepaintBoundary> createState() => _DebugRepaintBoundaryState();
}

class _DebugRepaintBoundaryState extends State<_DebugRepaintBoundary> {
  int _repaintCount = 0;

  @override
  Widget build(BuildContext context) {
    _repaintCount++;

    // Only show debug info in debug mode
    assert(() {
      if (_repaintCount % 10 == 0) {
        debugPrint(
          'RepaintBoundary[${widget.debugLabel}]: repaint #$_repaintCount',
        );
      }
      return true;
    }());

    return widget.child;
  }
}

/// Extension to easily add RepaintBoundary to any widget
extension RepaintBoundaryExtension on Widget {
  /// Wraps the widget with a RepaintBoundary for paint isolation
  Widget withRepaintBoundary({String? debugLabel}) {
    return OptimizedRepaintBoundary(debugLabel: debugLabel, child: this);
  }
}

/// A list tile optimized for use in long scrollable lists.
///
/// Uses RepaintBoundary and semantic keys for optimal performance.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) => OptimizedListItem(
///     itemKey: 'item_$index',
///     child: MyListTile(data: items[index]),
///   ),
/// )
/// ```
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final String itemKey;
  final bool enableRepaintBoundary;

  const OptimizedListItem({
    super.key,
    required this.child,
    required this.itemKey,
    this.enableRepaintBoundary = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = KeyedSubtree(key: ValueKey(itemKey), child: child);

    if (enableRepaintBoundary) {
      return RepaintBoundary(child: widget);
    }
    return widget;
  }
}

/// A card widget optimized for complex content that updates independently.
///
/// Wraps content with RepaintBoundary and provides proper semantics.
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double elevation;
  final BorderRadius? borderRadius;

  const OptimizedCard({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.padding,
    this.margin,
    this.color,
    this.elevation = 2.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: RepaintBoundary(
        child: Container(
          margin: margin,
          child: Card(
            color: color,
            elevation: elevation,
            shape: borderRadius != null
                ? RoundedRectangleBorder(borderRadius: borderRadius!)
                : null,
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );
  }
}

/// Widget for expensive animations that should be isolated
///
/// Useful for:
/// - Loading spinners
/// - Animated charts
/// - Continuous animations
class IsolatedAnimation extends StatelessWidget {
  final Widget child;

  const IsolatedAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// Helper mixin for widgets that need to track rebuild performance
mixin RebuildTracker<T extends StatefulWidget> on State<T> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;

  /// Current build count for this widget instance
  int get buildCount => _buildCount;

  /// Time since last build (null if first build)
  Duration? get timeSinceLastBuild {
    if (_lastBuildTime == null) return null;
    return DateTime.now().difference(_lastBuildTime!);
  }

  /// Call this at the start of your build method to track rebuilds
  void trackBuild() {
    _buildCount++;
    final now = DateTime.now();

    assert(() {
      if (_lastBuildTime != null) {
        final elapsed = now.difference(_lastBuildTime!);
        if (elapsed.inMilliseconds < 16) {
          // Less than one frame - might be excessive rebuilds
          debugPrint(
            'Warning: ${widget.runtimeType} rebuilding rapidly '
            '(${elapsed.inMilliseconds}ms since last build, count: $_buildCount)',
          );
        }
      }
      return true;
    }());

    _lastBuildTime = now;
  }
}
