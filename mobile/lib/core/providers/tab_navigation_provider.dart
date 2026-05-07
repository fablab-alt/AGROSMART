import 'package:flutter/material.dart';

/// Provider pour gérer la navigation entre les onglets du MainShellPage
class TabNavigationProvider extends InheritedWidget {
  final ValueNotifier<int> currentIndexNotifier;
  final Function(int) onTabChange;

  const TabNavigationProvider({
    super.key,
    required this.currentIndexNotifier,
    required this.onTabChange,
    required super.child,
  });

  static TabNavigationProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabNavigationProvider>();
  }

  static TabNavigationProvider of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No TabNavigationProvider found in context');
    return result!;
  }

  /// Change l'onglet actif du shell principal
  static void changeTab(BuildContext context, int index) {
    final provider = maybeOf(context);
    if (provider != null) {
      provider.onTabChange(index);
    }
  }

  @override
  bool updateShouldNotify(TabNavigationProvider oldWidget) {
    return currentIndexNotifier != oldWidget.currentIndexNotifier;
  }
}
