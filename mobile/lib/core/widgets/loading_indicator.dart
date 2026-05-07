/// Widget d'indicateur de chargement réutilisable
/// Affiche un spinner avec un message optionnel
library;

import 'package:flutter/material.dart';

/// Indicateur de chargement personnalisé pour l'application
class LoadingIndicator extends StatelessWidget {
  /// Message optionnel à afficher sous le spinner
  final String? message;

  /// Taille du spinner
  final double size;

  /// Couleur du spinner (utilise la couleur primaire par défaut)
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spinnerColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Version compacte de l'indicateur de chargement
class LoadingIndicatorCompact extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicatorCompact({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
