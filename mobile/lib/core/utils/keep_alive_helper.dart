/// Mixin pour conserver l'état des tabs/pages dans un TabBarView
///
/// Ce mixin permet de garder les widgets enfants en mémoire lorsqu'on
/// navigue entre les onglets, évitant ainsi des rechargements inutiles.
library;

import 'package:flutter/material.dart';

/// Mixin à ajouter sur les pages enfants d'un TabBarView
/// pour préserver leur état lors de la navigation entre onglets.
///
/// Usage:
/// ```dart
/// class _MyTabPageState extends State<MyTabPage>
///     with AutomaticKeepAliveClientMixin<MyTabPage> {
///
///   @override
///   bool get wantKeepAlive => true;
///
///   @override
///   Widget build(BuildContext context) {
///     super.build(context); // Important!
///     return ...
///   }
/// }
/// ```
///
/// Pour les cas où vous voulez un contrôle plus fin:
///
/// ```dart
/// class _MyTabPageState extends State<MyTabPage>
///     with AutomaticKeepAliveClientMixin<MyTabPage>, TabKeepAliveMixin {
///
///   @override
///   bool get wantKeepAlive => shouldKeepAlive;
///
///   @override
///   Widget build(BuildContext context) {
///     super.build(context);
///     return ...
///   }
/// }
/// ```
mixin TabKeepAliveMixin<T extends StatefulWidget> on State<T> {
  bool _keepAlive = true;

  /// Retourne true si le widget doit être gardé en mémoire
  bool get shouldKeepAlive => _keepAlive;

  /// Active/désactive la conservation de l'état
  ///
  /// Utile pour libérer la mémoire quand l'utilisateur n'est pas
  /// revenu sur cet onglet depuis longtemps.
  void setKeepAlive(bool value) {
    if (_keepAlive != value) {
      _keepAlive = value;
      // Si le widget implémente AutomaticKeepAliveClientMixin,
      // updateKeepAlive() sera appelé automatiquement
    }
  }
}

/// Widget helper pour envelopper un enfant dans un KeepAlive
/// sans avoir besoin d'un StatefulWidget séparé.
///
/// Usage:
/// ```dart
/// TabBarView(
///   children: [
///     KeepAliveWrapper(child: MyWidget1()),
///     KeepAliveWrapper(child: MyWidget2()),
///   ],
/// )
/// ```
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  final bool keepAlive;

  const KeepAliveWrapper({
    super.key,
    required this.child,
    this.keepAlive = true,
  });

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin<KeepAliveWrapper> {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Widget qui écoute les changements de tab et rafraîchit
/// automatiquement son contenu si nécessaire.
///
/// Usage:
/// ```dart
/// TabRefreshAware(
///   tabController: _tabController,
///   tabIndex: 0,
///   onBecameActive: () {
///     // Rafraîchir les données
///     context.read<MyBloc>().add(RefreshData());
///   },
///   child: MyTabContent(),
/// )
/// ```
class TabRefreshAware extends StatefulWidget {
  final TabController tabController;
  final int tabIndex;
  final Widget child;
  final VoidCallback? onBecameActive;
  final VoidCallback? onBecameInactive;
  final Duration refreshCooldown;

  const TabRefreshAware({
    super.key,
    required this.tabController,
    required this.tabIndex,
    required this.child,
    this.onBecameActive,
    this.onBecameInactive,
    this.refreshCooldown = const Duration(minutes: 1),
  });

  @override
  State<TabRefreshAware> createState() => _TabRefreshAwareState();
}

class _TabRefreshAwareState extends State<TabRefreshAware>
    with AutomaticKeepAliveClientMixin<TabRefreshAware> {
  DateTime? _lastRefresh;
  bool _wasActive = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_handleTabChange);
    _wasActive = widget.tabController.index == widget.tabIndex;
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    final isNowActive = widget.tabController.index == widget.tabIndex;

    if (isNowActive && !_wasActive) {
      // Tab devenu actif
      final now = DateTime.now();
      final shouldRefresh =
          _lastRefresh == null ||
          now.difference(_lastRefresh!) > widget.refreshCooldown;

      if (shouldRefresh) {
        widget.onBecameActive?.call();
        _lastRefresh = now;
      }
    } else if (!isNowActive && _wasActive) {
      // Tab devenu inactif
      widget.onBecameInactive?.call();
    }

    _wasActive = isNowActive;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Extension pour faciliter l'utilisation de KeepAlive sur des listes
extension KeepAliveListExtension on List<Widget> {
  /// Enveloppe chaque widget de la liste dans un KeepAliveWrapper
  List<Widget> withKeepAlive({bool keepAlive = true}) {
    return map(
      (widget) => KeepAliveWrapper(keepAlive: keepAlive, child: widget),
    ).toList();
  }
}
