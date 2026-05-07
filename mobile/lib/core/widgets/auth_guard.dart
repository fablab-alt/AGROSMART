import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';

/// Widget qui protège une action nécessitant une authentification.
///
/// Si l'utilisateur n'est pas connecté, affiche une popup de connexion.
/// Sinon, exécute l'action protégée.
class AuthGuard extends StatelessWidget {
  /// L'enfant à afficher (généralement un bouton)
  final Widget child;

  /// L'action à exécuter si l'utilisateur est authentifié
  final VoidCallback onAuthenticated;

  /// Message personnalisé pour la popup
  final String? message;

  /// Si true, redirige vers login au lieu de montrer une popup
  final bool redirectToLogin;

  const AuthGuard({
    super.key,
    required this.child,
    required this.onAuthenticated,
    this.message,
    this.redirectToLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () => _handleTap(context), child: child);
  }

  void _handleTap(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      // Utilisateur connecté, exécuter l'action
      onAuthenticated();
    } else {
      // Utilisateur non connecté
      if (redirectToLogin) {
        context.push('/login');
      } else {
        _showLoginRequiredDialog(context);
      }
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => LoginRequiredDialog(
        message: message ?? 'Connectez-vous pour continuer',
        onLogin: () {
          Navigator.of(ctx).pop();
          context.push('/login');
        },
        onRegister: () {
          Navigator.of(ctx).pop();
          context.push('/role-selection');
        },
      ),
    );
  }
}

/// Popup affichée quand une action nécessite une connexion
class LoginRequiredDialog extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LoginRequiredDialog({
    super.key,
    required this.message,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.green[700], size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Connexion requise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Bouton Se connecter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Se connecter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton Créer un compte
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRegister,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[700],
                side: BorderSide(color: Colors.green[700]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Créer un compte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }
}

/// Extension pour faciliter l'utilisation de AuthGuard
extension AuthGuardExtension on BuildContext {
  /// Vérifie si l'utilisateur est authentifié et exécute l'action
  void requireAuth({required VoidCallback onAuthenticated, String? message}) {
    final authState = read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      onAuthenticated();
    } else {
      showDialog(
        context: this,
        builder: (ctx) => LoginRequiredDialog(
          message: message ?? 'Connectez-vous pour continuer',
          onLogin: () {
            Navigator.of(ctx).pop();
            push('/login');
          },
          onRegister: () {
            Navigator.of(ctx).pop();
            push('/role-selection');
          },
        ),
      );
    }
  }

  /// Retourne true si l'utilisateur est authentifié
  bool get isAuthenticated {
    final authState = read<AuthBloc>().state;
    return authState is AuthAuthenticated;
  }
}
