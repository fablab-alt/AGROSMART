import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/services/navigation_intent_service.dart';
import '../../../../core/theme/theme_cubit.dart';

class RegisterPage extends StatefulWidget {
  /// Rôle sélectionné : 'ACHETEUR' ou 'PRODUCTEUR'
  /// Les acheteurs ont un parcours simplifié (étape 1 uniquement)
  /// Les producteurs ont le parcours complet (3 étapes)
  final String role;

  const RegisterPage({super.key, this.role = 'ACHETEUR'});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  /// Indique si l'utilisateur est un acheteur (parcours simplifié)
  bool get isAcheteur => widget.role == 'ACHETEUR';

  /// Nombre total d'étapes selon le rôle
  int get totalSteps => isAcheteur ? 1 : 3;

  // Step 1: Personal Info
  final _nomController = TextEditingController();
  final _prenomsController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Also used for Auth
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adresseController = TextEditingController();

  // Step 2: Production Info (3 pairs)
  final _prodType1Controller = TextEditingController();
  final _prodSurface1Controller = TextEditingController();
  final _prodType2Controller = TextEditingController();
  final _prodSurface2Controller = TextEditingController();
  final _prodType3Controller = TextEditingController();
  final _prodSurface3Controller = TextEditingController();

  // Step 3: Production History (Last 3 months)
  final _mois1Controller = TextEditingController(); // Quantity
  final _mois2Controller = TextEditingController(); // Quantity
  final _mois3Controller = TextEditingController(); // Quantity

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  String _selectedLanguage = 'fr';

  static const _weakPasswords = [
    'password',
    '12345678',
    '123456789',
    'qwerty',
    'azerty',
    'abc123',
    'password123',
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adresseController.dispose();

    _prodType1Controller.dispose();
    _prodSurface1Controller.dispose();
    _prodType2Controller.dispose();
    _prodSurface2Controller.dispose();
    _prodType3Controller.dispose();
    _prodSurface3Controller.dispose();

    _mois1Controller.dispose();
    _mois2Controller.dispose();
    _mois3Controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Pour les acheteurs, on n'a pas besoin des infos de production
      if (isAcheteur) {
        context.read<AuthBloc>().add(
          RegisterRequested(
            nom: _nomController.text.trim(),
            prenoms: _prenomsController.text.trim(),
            telephone: _phoneController.text.trim(),
            password: _passwordController.text,
            email: _emailController.text.trim(),
            adresse: _adresseController.text.trim(),
            languePreferee: _selectedLanguage,
            role: 'ACHETEUR',
          ),
        );
        return;
      }

      // Pour les producteurs, on inclut toutes les infos de production
      // Calculate total surface and ensure parsed correctly
      double surfaceTotal = 0.0;
      if (_prodSurface1Controller.text.isNotEmpty)
        surfaceTotal += double.tryParse(_prodSurface1Controller.text) ?? 0.0;
      if (_prodSurface2Controller.text.isNotEmpty)
        surfaceTotal += double.tryParse(_prodSurface2Controller.text) ?? 0.0;
      if (_prodSurface3Controller.text.isNotEmpty)
        surfaceTotal += double.tryParse(_prodSurface3Controller.text) ?? 0.0;

      // Use the first production type as main type if multiple
      String? mainType = _prodType1Controller.text.isNotEmpty
          ? _prodType1Controller.text
          : null;

      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _nomController.text.trim(),
          prenoms: _prenomsController.text.trim(),
          telephone: _phoneController.text.trim(),
          password: _passwordController.text,
          email: _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          languePreferee: _selectedLanguage,
          role: 'PRODUCTEUR',
          // Mapping specific fields to User entity fields
          typeProducteur: mainType,
          superficie: surfaceTotal > 0 ? surfaceTotal.toString() : null,
          uniteSuperficie: 'ha', // Default as per mockups (label says Hectares)
          // Passing monthly productions to be handled by updated Bloc/Repository
          // Passing monthly productions to be handled by updated Bloc/Repository
          productionMois1: _mois1Controller.text.trim(),
          productionMois2: _mois2Controller.text.trim(),
          productionMois3: _mois3Controller.text.trim(),
          productions: [
            if (_prodType1Controller.text.isNotEmpty &&
                _prodSurface1Controller.text.isNotEmpty)
              {
                'type': _prodType1Controller.text.trim(),
                'surface': double.tryParse(_prodSurface1Controller.text) ?? 0.0,
              },
            if (_prodType2Controller.text.isNotEmpty &&
                _prodSurface2Controller.text.isNotEmpty)
              {
                'type': _prodType2Controller.text.trim(),
                'surface': double.tryParse(_prodSurface2Controller.text) ?? 0.0,
              },
            if (_prodType3Controller.text.isNotEmpty &&
                _prodSurface3Controller.text.isNotEmpty)
              {
                'type': _prodType3Controller.text.trim(),
                'surface': double.tryParse(_prodSurface3Controller.text) ?? 0.0,
              },
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Main background color: Mockup Green (Light) vs Theme Surface (Dark)
    final backgroundColor = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              final cubit = context.read<ThemeCubit>();
              cubit.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated || state is AuthRegistered) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inscription réussie ! Bienvenue !'),
                  backgroundColor: Colors.green,
                ),
              );

              // Vérifier s'il y a une route en attente
              if (NavigationIntent.hasPendingRoute()) {
                final pendingRoute = NavigationIntent.consumePendingRoute();
                context.go(pendingRoute!);
                return;
              }

              // Tous les utilisateurs vont au dashboard (Accueil)
              context.go('/');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ), // Reduced spacing as AppBar takes space
                  // Header with Icon
                  Icon(
                    isAcheteur ? Icons.shopping_bag : Icons.account_circle,
                    size: 60,
                    color: const Color(0xFF28A745),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAcheteur
                        ? 'Inscription Acheteur'
                        : 'Inscription Producteur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    isAcheteur
                        ? 'Créez votre compte pour accéder au marketplace'
                        : 'Créez votre compte pour suivre vos productions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content Card based on Step
                  _buildStepContent(isDark),

                  // Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          TextButton.icon(
                            onPressed: () => setState(() => _currentStep -= 1),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            label: const Text(
                              'Précédent',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          const SizedBox(width: 80), // Spacer
                        // Pour les acheteurs: bouton S'inscrire dès l'étape 1
                        // Pour les producteurs: bouton Suivant jusqu'à l'étape 3
                        if (!isAcheteur && _currentStep < 2)
                          TextButton.icon(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _currentStep += 1);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF28A745),
                            ),
                            label: const Text(
                              'suivant',
                              style: TextStyle(
                                color: Color(0xFF28A745),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            iconAlignment: IconAlignment.end,
                          )
                        else
                          SizedBox(
                            width: 200,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF28A745),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Lien vers connexion (visible uniquement à la dernière étape ou pour les acheteurs)
                  if (_currentStep == (totalSteps - 1))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Déjà inscrit ? Se connecter',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    Widget content;
    Color cardColor;
    String title;

    switch (_currentStep) {
      case 0:
        title = 'Informations Personnelles';
        cardColor = isDark
            ? Theme.of(context).cardColor
            : const Color(0xFFE8F5E9); // Green-50
        content = _buildStep1Form();
        break;
      case 1:
        title = 'Informations de Production';
        cardColor = isDark
            ? Theme.of(context).cardColor
            : const Color(0xFFE3F2FD); // Blue-50
        content = _buildStep2Form();
        break;
      case 2:
        title = 'Productions des 3 derniers mois';
        cardColor = isDark
            ? Theme.of(context).cardColor
            : const Color(0xFFFFFDE7); // Yellow-50ish
        content = _buildStep3Form();
        break;
      default:
        return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 20),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Column(
      children: [
        _buildTextField(
          'Nom *',
          _nomController,
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Prénom *',
          _prenomsController,
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Email *',
          _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => !v!.contains('@') ? 'Email invalide' : null,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Téléphone *',
          _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Mot de passe *',
          _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: _validatePassword,
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPasswordCriteria(),
        ],
        const SizedBox(height: 12),
        _buildTextField(
          'Confirmer mot de passe *',
          _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          validator: (v) =>
              v != _passwordController.text ? 'Mots de passe différents' : null,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langue préférée *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'fr',
                    child: Row(
                      children: [
                        Text('🇫🇷', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Français'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Row(
                      children: [
                        Text('🇬🇧', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('English'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bci',
                    child: Row(
                      children: [
                        Text('🇨🇮', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Baoulé'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bm',
                    child: Row(
                      children: [
                        Text('🇲🇱', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Bambara'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ff',
                    child: Row(
                      children: [
                        Text('🌍', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Peul (Fulfulde)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'dyu',
                    child: Row(
                      children: [
                        Text('🇨🇮', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Dioula'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'wo',
                    child: Row(
                      children: [
                        Text('🇸🇳', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Wolof'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'mos',
                    child: Row(
                      children: [
                        Text('🇧🇫', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Mooré'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'ha',
                    child: Row(
                      children: [
                        Text('🌍', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 12),
                        Text('Haoussa'),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedLanguage = v!),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'L\'application sera affichée dans cette langue',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Adresse *',
          _adresseController,
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
      ],
    );
  }

  Widget _buildStep2Form() {
    return Column(
      children: [
        _buildProductionPair(1, _prodType1Controller, _prodSurface1Controller),
        const SizedBox(height: 16),
        _buildProductionPair(
          2,
          _prodType2Controller,
          _prodSurface2Controller,
          isRequired: false,
        ),
        const SizedBox(height: 16),
        _buildProductionPair(
          3,
          _prodType3Controller,
          _prodSurface3Controller,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildProductionPair(
    int index,
    TextEditingController typeCtrl,
    TextEditingController surfaceCtrl, {
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Type de production${isRequired ? " *" : ""}',
          typeCtrl,
          hintText: 'Ex: Maïs, cacao, Légumes...',
          validator: isRequired ? (v) => v!.isEmpty ? 'Requis' : null : null,
        ),
        const SizedBox(height: 8),
        _buildTextField(
          'Superficie (hectares)${isRequired ? " *" : ""}',
          surfaceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: isRequired ? (v) => v!.isEmpty ? 'Requis' : null : null,
        ),
      ],
    );
  }

  Widget _buildStep3Form() {
    return Column(
      children: [
        _buildMonthInput('Mois 1', _mois1Controller),
        const SizedBox(height: 16),
        _buildMonthInput('Mois 2', _mois2Controller),
        const SizedBox(height: 16),
        _buildMonthInput('Mois 3', _mois3Controller),
      ],
    );
  }

  Widget _buildMonthInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Quantité (kg)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    if (value.length < 8) return 'Au moins 8 caractères requis';
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return 'Au moins une majuscule requise';
    if (!RegExp(r'[a-z]').hasMatch(value))
      return 'Au moins une minuscule requise';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre requis';
    if (_weakPasswords.contains(
      value.toLowerCase().replaceAll(RegExp(r'[0-9]'), ''),
    )) {
      return 'Ce mot de passe est trop commun';
    }
    return null;
  }

  Widget _buildPasswordCriteria() {
    final pw = _passwordController.text;
    final criteria = [
      (label: 'Au moins 8 caractères', ok: pw.length >= 8),
      (label: 'Au moins une majuscule', ok: RegExp(r'[A-Z]').hasMatch(pw)),
      (label: 'Au moins une minuscule', ok: RegExp(r'[a-z]').hasMatch(pw)),
      (label: 'Au moins un chiffre', ok: RegExp(r'[0-9]').hasMatch(pw)),
      (
        label: 'Mot de passe non commun',
        ok: !_weakPasswords.contains(
          pw.toLowerCase().replaceAll(RegExp(r'[0-9]'), ''),
        ),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critères du mot de passe :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...criteria.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(
                    c.ok ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: c.ok ? const Color(0xFF28A745) : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.ok ? const Color(0xFF28A745) : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              isDense: true,
              suffixIcon: suffixIcon,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
