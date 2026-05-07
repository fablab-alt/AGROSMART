import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:agriculture/injection_container.dart' as di;
import '../bloc/community_listing_bloc.dart';
import '../../domain/entities/community_listing.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _localisationController = TextEditingController();

  ListingType _selectedType = ListingType.vente;
  String _selectedCategorie = 'tracteur';
  String _selectedEtat = 'bon';
  String? _selectedPrixUnite;
  bool _negociable = false;
  List<String> _imageUrls = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'tracteur', 'label': 'Tracteur', 'icon': Icons.agriculture},
    {'id': 'semoir', 'label': 'Semoir', 'icon': Icons.grass},
    {'id': 'pulverisateur', 'label': 'Pulvérisateur', 'icon': Icons.water_drop},
    {'id': 'moissonneuse', 'label': 'Moissonneuse', 'icon': Icons.content_cut},
    {'id': 'charrue', 'label': 'Charrue', 'icon': Icons.landscape},
    {'id': 'pompe', 'label': 'Pompe', 'icon': Icons.water},
    {'id': 'transport', 'label': 'Véhicule', 'icon': Icons.local_shipping},
    {'id': 'autre', 'label': 'Autre', 'icon': Icons.more_horiz},
  ];

  final List<String> _etats = ['neuf', 'excellent', 'bon', 'moyen', 'usagé'];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _localisationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<CommunityListingBloc>(),
      child: BlocListener<CommunityListingBloc, CommunityListingState>(
        listener: (context, state) {
          if (state is CommunityListingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          } else if (state is CommunityListingError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Publier une annonce'),
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Type d'annonce
                const Text(
                  'Type d\'annonce',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        ListingType.vente,
                        'Vendre',
                        Icons.sell,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        ListingType.location,
                        'Louer',
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Images
                const Text(
                  'Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez jusqu\'à 5 photos de votre équipement',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _buildImagePicker(),
                const SizedBox(height: 24),

                // Titre
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre de l\'annonce *',
                    hintText: 'Ex: Tracteur John Deere 5075E',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Décrivez votre équipement en détail...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Catégorie
                const Text(
                  'Catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategorie == cat['id'];
                    return ChoiceChip(
                      label: Text(cat['label']),
                      avatar: Icon(
                        cat['icon'],
                        size: 18,
                        color: isSelected ? Colors.white : Colors.green[700],
                      ),
                      selected: isSelected,
                      selectedColor: Colors.green[700],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategorie = cat['id']);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // État
                const Text(
                  'État',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedEtat,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.verified),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _etats.map((etat) {
                    return DropdownMenuItem(
                      value: etat,
                      child: Text(
                        etat.substring(0, 1).toUpperCase() + etat.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEtat = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Prix
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Prix *',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: 'FCFA',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Entrez le prix';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_selectedType == ListingType.location) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPrixUnite ?? '/jour',
                          decoration: InputDecoration(
                            labelText: 'Par',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '/jour',
                              child: Text('/jour'),
                            ),
                            DropdownMenuItem(
                              value: '/heure',
                              child: Text('/heure'),
                            ),
                            DropdownMenuItem(
                              value: '/semaine',
                              child: Text('/semaine'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedPrixUnite = value);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _negociable,
                  onChanged: (value) {
                    setState(() => _negociable = value ?? false);
                  },
                  title: const Text('Prix négociable'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Localisation
                TextFormField(
                  controller: _localisationController,
                  decoration: InputDecoration(
                    labelText: 'Localisation *',
                    hintText: 'Ex: Abidjan, Yopougon',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre localisation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Bouton publier
                Builder(
                  builder: (context) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _submitForm(context),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.publish),
                        label: Text(
                          _isLoading
                              ? 'Publication en cours...'
                              : 'Publier l\'annonce',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    ListingType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type == ListingType.vente) {
            _selectedPrixUnite = null;
          } else {
            _selectedPrixUnite = '/jour';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageUrls.length + 1,
        itemBuilder: (context, index) {
          if (index == _imageUrls.length) {
            // Add button
            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 32, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text('Ajouter', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(_imageUrls[index])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _imageUrls.removeAt(index));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 5 photos')));
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _imageUrls.add(image.path));
    }
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      context.read<CommunityListingBloc>().add(
        CreateListing(
          titre: _titreController.text,
          description: _descriptionController.text,
          type: _selectedType,
          categorie: _selectedCategorie,
          prix: double.parse(_prixController.text),
          prixUnite: _selectedPrixUnite,
          negociable: _negociable,
          etat: _selectedEtat,
          images: _imageUrls,
          localisation: _localisationController.text,
        ),
      );
    }
  }
}
