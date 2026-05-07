/// Service pour gérer la navigation contextuelle
/// Sauvegarde l'intention de l'utilisateur avant authentification
/// et le redirige vers sa destination après connexion
class NavigationIntent {
  static String? _pendingRoute;
  static Map<String, dynamic>? _routeExtra;

  /// Sauvegarder une route en attente (ex: checkout)
  static void setPendingRoute(String route, {Map<String, dynamic>? extra}) {
    _pendingRoute = route;
    _routeExtra = extra;
  }

  /// Obtenir et supprimer la route en attente
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    _routeExtra = null;
    return route;
  }

  /// Obtenir les données extra de la route
  static Map<String, dynamic>? getRouteExtra() {
    return _routeExtra;
  }

  /// Vérifier s'il y a une route en attente
  static bool hasPendingRoute() {
    return _pendingRoute != null;
  }

  /// Effacer la route en attente
  static void clear() {
    _pendingRoute = null;
    _routeExtra = null;
  }
}
