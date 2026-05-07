import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/features/auth/domain/entities/user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProducer = false; // Déterminer le rôle de l'utilisateur

  // Contrôleurs pour les champs
  late TextEditingController _nomController;
  late TextEditingController _prenomsController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  late TextEditingController _typeProducteurController; // Changed from dropdown
  late TextEditingController _superficieController;
  late TextEditingController _mois1Controller;
  late TextEditingController _mois2Controller;
  late TextEditingController _mois3Controller;

  String _selectedRegion = 'Centre';
  String _selectedLanguage = 'fr';
  // String _selectedTypeProducteur = 'Producteur individuel'; // Removed
  String _selectedUniteSuperficie = 'ha';
  String _selectedSystemeIrrigation = 'Manuel';

  final List<String> _regions = [
    'Abidjan',
    'Centre',
    'Nord',
    'Sud',
    'Est',
    'Ouest',
  ];

  // Removed _typesProducteur list

  final List<String> _unitesSuperficie = ['ha', 'm²', 'ares'];

  final List<String> _systemesIrrigation = [
    'Manuel',
    'Goutte à goutte',
    'Aspersion',
    'Gravitaire',
    'Aucun',
  ];

  // Image Picker
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    User? user;
    if (authState is AuthAuthenticated) {
      user = authState.user;
    } else if (authState is AuthRegistered) {
      user = authState.user;
    }

    // Déterminer le rôle
    _isProducer = user?.role == 'PRODUCTEUR';

    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomsController = TextEditingController(text: user?.prenoms ?? '');
    _telephoneController = TextEditingController(text: user?.telephone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _adresseController = TextEditingController(text: user?.adresse ?? '');
    _superficieController = TextEditingController(
      text: user?.superficieExploitee?.toString() ?? '',
    );
    _mois1Controller = TextEditingController(
      text: user?.productionMois1?.toString() ?? '',
    );
    _mois2Controller = TextEditingController(
      text: user?.productionMois2?.toString() ?? '',
    );
    _mois3Controller = TextEditingController(
      text: user?.productionMois3?.toString() ?? '',
    );

    _typeProducteurController = TextEditingController(
      text: user?.typeProducteur ?? '',
    );
    _selectedLanguage = user?.preferredLanguage ?? 'fr';

    // Initialize dropdowns safely
    if (user?.regionName != null && _regions.contains(user!.regionName)) {
      _selectedRegion = user.regionName!;
    }
    // Removed _selectedTypeProducteur check
    if (user?.uniteSuperficie != null &&
        _unitesSuperficie.contains(user!.uniteSuperficie)) {
      _selectedUniteSuperficie = user.uniteSuperficie!;
    }
    if (user?.systemeIrrigation != null &&
        _systemesIrrigation.contains(user!.systemeIrrigation)) {
      _selectedSystemeIrrigation = user.systemeIrrigation!;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomsController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _typeProducteurController.dispose();
    _superficieController.dispose();
    _mois1Controller.dispose();
    _mois2Controller.dispose();
    _mois3Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to profile page
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Informations personnelles'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo de profil
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade100,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null, // TODO: Add network image if user has one
                        child: _imageFile == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.green.shade700,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _changePhoto,
                    child: const Text('Changer la photo'),
                  ),
                ),
                const SizedBox(height: 24),

                // Section: Identité
                _buildSectionTitle('Identité'),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _prenomsController,
                  label: 'Prénoms',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Les prénoms sont requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Section: Contact
                _buildSectionTitle('Contact'),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  enabled: true, // Enabled phone editing
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le téléphone est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email (optionnel)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _adresseController,
                  label: 'Adresse',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Section: Préférences
                _buildSectionTitle('Préférences'),
                const SizedBox(height: 12),

                // Langue préférée
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Langue préférée',
                        icon: Icon(Icons.language),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(
                          value: 'baoule',
                          child: Text('Baoulé'),
                        ),
                        DropdownMenuItem(
                          value: 'malinke',
                          child: Text('Malinké'),
                        ),
                        DropdownMenuItem(
                          value: 'senoufo',
                          child: Text('Senoufo'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                      },
                    ),
                  ),
                ),

                // Sections spécifiques au PRODUCTEUR uniquement
                if (_isProducer) ...[
                  const SizedBox(height: 24),

                  // Section: Exploitation
                  _buildSectionTitle('Exploitation'),
                  const SizedBox(height: 12),

                  // Région
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Région',
                          icon: Icon(Icons.map),
                        ),
                        items: _regions
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedRegion = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Type de producteur
                  // Type de producteur (Culture principale)
                  _buildTextField(
                    controller: _typeProducteurController,
                    label: 'Type de production / Culture principale',
                    icon: Icons.agriculture,
                    hintText: 'Ex: Maïs, Cacao, Hévéa...',
                  ),
                  const SizedBox(height: 24),

                  // Section: Profil Agricole
                  _buildSectionTitle('Profil Agricole'),
                  const SizedBox(height: 12),

                  // Superficie exploitée avec unité
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _superficieController,
                          label: 'Superficie exploitée',
                          icon: Icons.square_foot,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUniteSuperficie,
                              isExpanded: true,
                              items: _unitesSuperficie
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(
                                  () => _selectedUniteSuperficie = value!,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Système d'irrigation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSystemeIrrigation,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: "Système d'irrigation",
                          icon: Icon(Icons.water_drop),
                        ),
                        items: _systemesIrrigation
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedSystemeIrrigation = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Historique Production
                  _buildSectionTitle('Historique Production (3 derniers mois)'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _mois1Controller,
                    label: 'Production Mois - 1 (kg)',
                    icon: Icons.history,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _mois2Controller,
                    label: 'Production Mois - 2 (kg)',
                    icon: Icons.history,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _mois3Controller,
                    label: 'Production Mois - 3 (kg)',
                    icon: Icons.history,
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 32),

                // Bouton de sauvegarde
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton annuler
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).cardColor
            : Theme.of(context).disabledColor.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Changer la photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.camera_alt, color: Colors.green),
              ),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Données communes pour tous les utilisateurs
      final Map<String, dynamic> profileData = {
        'nom': _nomController.text,
        'prenoms': _prenomsController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text,
        'adresse': _adresseController.text,
        'preferredLanguage': _selectedLanguage,
      };

      // Ajouter les données producteur si applicable
      if (_isProducer) {
        profileData.addAll({
          'typeProducteur': _typeProducteurController.text,
          'region': _selectedRegion,
          'superficieExploitee': double.tryParse(_superficieController.text),
          'uniteSuperficie': _selectedUniteSuperficie,
          'systemeIrrigation': _selectedSystemeIrrigation,
          'productionMois1': double.tryParse(_mois1Controller.text),
          'productionMois2': double.tryParse(_mois2Controller.text),
          'productionMois3': double.tryParse(_mois3Controller.text),
        });
      }

      context.read<AuthBloc>().add(
        UpdateProfileRequested(
          nom: _nomController.text,
          prenoms: _prenomsController.text,
          email: _emailController.text,
          telephone: _telephoneController.text,
          typeProducteur: _isProducer ? _typeProducteurController.text : null,
          region: _isProducer ? _selectedRegion : null,
          photo: _imageFile,
          superficieExploitee: _isProducer
              ? double.tryParse(_superficieController.text)
              : null,
          uniteSuperficie: _isProducer ? _selectedUniteSuperficie : null,
          systemeIrrigation: _isProducer ? _selectedSystemeIrrigation : null,
          productionMois1: _isProducer
              ? double.tryParse(_mois1Controller.text)
              : null,
          productionMois2: _isProducer
              ? double.tryParse(_mois2Controller.text)
              : null,
          productionMois3: _isProducer
              ? double.tryParse(_mois3Controller.text)
              : null,
        ),
      );
    }
  }
}
