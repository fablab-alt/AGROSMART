import 'package:flutter/material.dart';
import '../../../core/services/local_language_service.dart';

/// Widget de sélection de langue
/// Permet aux utilisateurs de choisir parmi les langues disponibles
/// incluant le français et les langues locales ivoiriennes
class LanguageSelectorWidget extends StatefulWidget {
  /// Callback appelé quand la langue change
  final VoidCallback? onLanguageChanged;

  /// Si true, affiche sous forme de BottomSheet au lieu de Dialog
  final bool useBottomSheet;

  const LanguageSelectorWidget({
    super.key,
    this.onLanguageChanged,
    this.useBottomSheet = true,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();

  /// Affiche le sélecteur de langue
  static Future<void> show(BuildContext context, {VoidCallback? onChanged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageBottomSheet(onChanged: onChanged),
    );
  }
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  final _languageService = LocalLanguageService();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(_languageService.t('language')),
      subtitle: Text(_languageService.currentLanguage.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageSelector(context),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    if (widget.useBottomSheet) {
      LanguageSelectorWidget.show(
        context,
        onChanged: () {
          setState(() {});
          widget.onLanguageChanged?.call();
        },
      );
    } else {
      _showLanguageDialog(context);
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _LanguageDialog(
        onChanged: () {
          setState(() {});
          widget.onLanguageChanged?.call();
        },
      ),
    );
  }
}

class _LanguageBottomSheet extends StatefulWidget {
  final VoidCallback? onChanged;

  const _LanguageBottomSheet({this.onChanged});

  @override
  State<_LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<_LanguageBottomSheet> {
  final _languageService = LocalLanguageService();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Titre
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    _languageService.t('select_language'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Liste des langues
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: LocalLanguage.values.length,
              itemBuilder: (context, index) {
                final language = LocalLanguage.values[index];
                final isSelected = language == _languageService.currentLanguage;

                return _LanguageListTile(
                  language: language,
                  isSelected: isSelected,
                  onTap: () => _selectLanguage(language),
                );
              },
            ),

            const SizedBox(height: 16),

            // Note informative pour les langues locales
            if (!_languageService.currentLanguage.hasTTSSupport)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les alertes vocales seront lues avec des enregistrements audio',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(LocalLanguage language) async {
    await _languageService.setLanguage(language);

    // Jouer une salutation dans la nouvelle langue
    await _languageService.playGreeting();

    if (mounted) {
      setState(() {});
      widget.onChanged?.call();
      Navigator.of(context).pop();
    }
  }
}

class _LanguageListTile extends StatelessWidget {
  final LocalLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageListTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getLanguageFlag(language),
      title: Text(
        language.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.green[700] : null,
        ),
      ),
      subtitle: _getLanguageSubtitle(language),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Colors.green[700])
          : language.hasTTSSupport
          ? null
          : Icon(Icons.volume_up, color: Colors.grey[400], size: 20),
      onTap: onTap,
    );
  }

  Widget _getLanguageFlag(LocalLanguage language) {
    // Emoji de drapeau ou initiales
    String flag;
    switch (language) {
      case LocalLanguage.french:
        flag = '🇫🇷';
      case LocalLanguage.baoule:
      case LocalLanguage.dioula:
      case LocalLanguage.senoufo:
        flag = '🇨🇮';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(flag, style: const TextStyle(fontSize: 24))),
    );
  }

  Widget? _getLanguageSubtitle(LocalLanguage language) {
    switch (language) {
      case LocalLanguage.french:
        return const Text('Langue par défaut');
      case LocalLanguage.baoule:
        return const Text('Centre de la Côte d\'Ivoire');
      case LocalLanguage.dioula:
        return const Text('Nord et Ouest de la Côte d\'Ivoire');
      case LocalLanguage.senoufo:
        return const Text('Nord de la Côte d\'Ivoire');
    }
  }
}

class _LanguageDialog extends StatefulWidget {
  final VoidCallback? onChanged;

  const _LanguageDialog({this.onChanged});

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _languageService = LocalLanguageService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language, color: Colors.green),
          const SizedBox(width: 8),
          Text(_languageService.t('select_language')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: LocalLanguage.values.map((language) {
          return RadioListTile<LocalLanguage>(
            title: Text(language.displayName),
            value: language,
            groupValue: _languageService.currentLanguage,
            activeColor: Colors.green,
            onChanged: (value) => _selectLanguage(value!),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_languageService.t('cancel')),
        ),
      ],
    );
  }

  Future<void> _selectLanguage(LocalLanguage language) async {
    await _languageService.setLanguage(language);
    await _languageService.playGreeting();

    if (mounted) {
      setState(() {});
      widget.onChanged?.call();
      Navigator.of(context).pop();
    }
  }
}
