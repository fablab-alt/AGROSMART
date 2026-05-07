import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/security/biometric_auth_service.dart';

/// Bouton permettant l'authentification biométrique
class BiometricAuthButton extends StatefulWidget {
  /// Callback appelé quand l'authentification réussit
  final VoidCallback onAuthenticationSuccess;

  /// Callback appelé quand l'authentification échoue
  final void Function(String errorMessage)? onAuthenticationFailed;

  /// Raison affichée à l'utilisateur (iOS)
  final String localizedReason;

  /// Pour transactions sensibles (paiement, etc.)
  final bool sensitiveTransaction;

  /// Style du bouton
  final BiometricButtonStyle style;

  const BiometricAuthButton({
    super.key,
    required this.onAuthenticationSuccess,
    this.onAuthenticationFailed,
    this.localizedReason = 'Veuillez vous authentifier',
    this.sensitiveTransaction = false,
    this.style = BiometricButtonStyle.filled,
  });

  @override
  State<BiometricAuthButton> createState() => _BiometricAuthButtonState();
}

class _BiometricAuthButtonState extends State<BiometricAuthButton> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;
  bool _isBiometricAvailable = false;
  BiometricType? _biometricType;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      setState(() => _isBiometricAvailable = false);
      return;
    }

    final biometrics = await _biometricService.getAvailableBiometrics();
    setState(() {
      _isBiometricAvailable = true;
      // Priorité: Face > Fingerprint > autres
      if (biometrics.contains(BiometricType.face)) {
        _biometricType = BiometricType.face;
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        _biometricType = BiometricType.fingerprint;
      } else if (biometrics.isNotEmpty) {
        _biometricType = biometrics.first;
      }
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      final result = await _biometricService.authenticate(
        localizedReason: widget.localizedReason,
        sensitiveTransaction: widget.sensitiveTransaction,
      );

      if (!mounted) return;

      if (result.success) {
        widget.onAuthenticationSuccess();
      } else {
        final errorMessage = result.errorMessage ?? 'Authentification échouée';
        widget.onAuthenticationFailed?.call(errorMessage);

        // Afficher un SnackBar d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  IconData _getBiometricIcon() {
    if (_biometricType == BiometricType.face) {
      return Icons.face;
    } else if (_biometricType == BiometricType.fingerprint) {
      return Icons.fingerprint;
    }
    return Icons.lock;
  }

  String _getBiometricLabel() {
    if (_biometricType == BiometricType.face) {
      return 'Face ID';
    } else if (_biometricType == BiometricType.fingerprint) {
      return 'Empreinte';
    }
    return 'Biométrie';
  }

  @override
  Widget build(BuildContext context) {
    // N'afficher que si disponible
    if (!_isBiometricAvailable) {
      return const SizedBox.shrink();
    }

    final icon = _getBiometricIcon();
    final label = _getBiometricLabel();

    switch (widget.style) {
      case BiometricButtonStyle.filled:
        return FilledButton.icon(
          onPressed: _isAuthenticating ? null : _authenticate,
          icon: _isAuthenticating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(_isAuthenticating ? 'Authentification...' : label),
        );

      case BiometricButtonStyle.outlined:
        return OutlinedButton.icon(
          onPressed: _isAuthenticating ? null : _authenticate,
          icon: _isAuthenticating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(_isAuthenticating ? 'Authentification...' : label),
        );

      case BiometricButtonStyle.text:
        return TextButton.icon(
          onPressed: _isAuthenticating ? null : _authenticate,
          icon: _isAuthenticating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon),
          label: Text(_isAuthenticating ? 'Authentification...' : label),
        );

      case BiometricButtonStyle.iconOnly:
        return IconButton(
          onPressed: _isAuthenticating ? null : _authenticate,
          icon: _isAuthenticating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 32),
          tooltip: label,
        );
    }
  }
}

/// Style du bouton biométrique
enum BiometricButtonStyle {
  /// Bouton rempli (FilledButton)
  filled,

  /// Bouton avec bordure (OutlinedButton)
  outlined,

  /// Bouton texte (TextButton)
  text,

  /// Icône uniquement (IconButton)
  iconOnly,
}

/// Widget d'opt-in pour activer/désactiver l'authentification biométrique
class BiometricOptInWidget extends StatefulWidget {
  /// Valeur actuelle (activée/désactivée)
  final bool enabled;

  /// Callback quand la valeur change
  final ValueChanged<bool> onChanged;

  /// Afficher une description
  final bool showDescription;

  const BiometricOptInWidget({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.showDescription = true,
  });

  @override
  State<BiometricOptInWidget> createState() => _BiometricOptInWidgetState();
}

class _BiometricOptInWidgetState extends State<BiometricOptInWidget> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAvailable = false;
  String _biometricDescription = 'Biométrie';

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      setState(() => _isAvailable = false);
      return;
    }

    final biometrics = await _biometricService.getAvailableBiometrics();
    if (biometrics.isEmpty) {
      setState(() => _isAvailable = false);
      return;
    }

    final primaryType = biometrics.contains(BiometricType.face)
        ? BiometricType.face
        : biometrics.first;

    setState(() {
      _isAvailable = true;
      _biometricDescription = _biometricService.getBiometricTypeDescription(
        primaryType,
      );
    });
  }

  Future<void> _handleToggle(bool value) async {
    if (value) {
      // Tester l'authentification avant d'activer
      final success = await _biometricService.authenticateForLogin();
      if (success) {
        widget.onChanged(true);
      } else {
        // Afficher un message d'erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible d\'activer l\'authentification biométrique',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      widget.onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    return SwitchListTile(
      value: widget.enabled,
      onChanged: _handleToggle,
      title: Text('Authentification $_biometricDescription'),
      subtitle: widget.showDescription
          ? const Text('Se connecter rapidement avec votre biométrie')
          : null,
      secondary: Icon(
        widget.enabled ? Icons.lock_outline : Icons.lock_open,
        color: widget.enabled ? Colors.green : null,
      ),
    );
  }
}
