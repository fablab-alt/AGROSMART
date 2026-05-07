import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher les états d'erreur
///
/// Utilisé dans toutes les pages pour afficher les erreurs de manière cohérente
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color? iconColor;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  /// Factory pour les erreurs réseau
  factory ErrorStateWidget.network({Key? key, VoidCallback? onRetry}) {
    return ErrorStateWidget(
      key: key,
      message: 'Problème de connexion',
      details: 'Vérifiez votre connexion internet et réessayez.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }

  /// Factory pour les erreurs serveur
  factory ErrorStateWidget.server({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      key: key,
      message: message ?? 'Erreur serveur',
      details: 'Un problème est survenu. Réessayez plus tard.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
    );
  }

  /// Factory pour les données non trouvées
  factory ErrorStateWidget.notFound({Key? key, String? itemName}) {
    return ErrorStateWidget(
      key: key,
      message: itemName != null
          ? '$itemName non trouvé'
          : 'Données non trouvées',
      icon: Icons.search_off,
    );
  }

  /// Factory pour les erreurs d'authentification
  factory ErrorStateWidget.unauthorized({Key? key, VoidCallback? onLogin}) {
    return ErrorStateWidget(
      key: key,
      message: 'Session expirée',
      details: 'Veuillez vous reconnecter.',
      icon: Icons.lock_outline,
      onRetry: onLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: effectiveIconColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher un message d'erreur dans une snackbar
class ErrorSnackBar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showWithRetry(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

/// Widget pour les états vides
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  /// Factory pour liste vide
  factory EmptyStateWidget.noData({Key? key, String? message, Widget? action}) {
    return EmptyStateWidget(
      key: key,
      message: message ?? 'Aucune donnée',
      icon: Icons.folder_open,
      action: action,
    );
  }

  /// Factory pour résultats de recherche vides
  factory EmptyStateWidget.noResults({Key? key, String? searchTerm}) {
    return EmptyStateWidget(
      key: key,
      message: 'Aucun résultat',
      subtitle: searchTerm != null
          ? 'Aucun résultat pour "$searchTerm"'
          : 'Essayez avec d\'autres mots-clés',
      icon: Icons.search_off,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Widget de chargement avec message
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }
}
