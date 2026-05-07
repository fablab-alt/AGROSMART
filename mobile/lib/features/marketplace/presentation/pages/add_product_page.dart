import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/marketplace_bloc.dart';

class AddProductPage extends StatefulWidget {
  final String? type; // 'vente' (default) or 'location'
  const AddProductPage({super.key, this.type});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prixController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _locController = TextEditingController();

  // Rental specific
  final _cautionController = TextEditingController();
  final _minDurationController = TextEditingController(text: '1');

  bool _isLocation = false;

  String _selectedCategory = 'cereale';
  final List<String> _categories = [
    'cereale',
    'legume',
    'fruit',
    'tubercule',
    'oleagineux',
    'intrant',
    'equipement',
    'service',
    'autre',
  ];
  String? _selectedUnit = 'kg';
  final List<String> _units = ['kg', 'tonne', 'unite', 'sac', 'litre', 'jour'];

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isLocation = widget.type == 'location';
    if (_isLocation) {
      _selectedCategory =
          'location'; // Default category for rentals or add new one?
      _selectedUnit = 'jour';
    } else {
      _selectedCategory = _categories.first;
    }
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter au moins une image')),
        );
        return;
      }

      final data = {
        'nom': _nomController.text,
        'description':
            _descController.text +
            (_isLocation
                ? ' [LOCATION]'
                : ''), // Hack to distinguish for now until backend supports proper type
        'categorie': _selectedCategory,
        'prix': double.tryParse(_prixController.text) ?? 0,
        'unite': _selectedUnit,
        'quantite_disponible': double.tryParse(_qtyController.text) ?? 1,
        'localisation': _locController.text,
        // Add more metadata to description or separate fields if backend supports it
        // 'type_offre': _isLocation ? 'location' : 'vente',
      };

      context.read<MarketplaceBloc>().add(
        AddMarketplaceProduct(data: data, images: _selectedImages),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLocation ? 'Mettre en location' : 'Vendre un produit'),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<MarketplaceBloc, MarketplaceState>(
        listener: (context, state) {
          if (state is MarketplaceLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Annonce ajoutée avec succès!')),
            );
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          } else if (state is MarketplaceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Switcher
                Row(
                  children: [
                    const Text(
                      'Type d\'offre: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ToggleButtons(
                      isSelected: [!_isLocation, _isLocation],
                      onPressed: (index) {
                        setState(() {
                          _isLocation = index == 1;
                          if (_isLocation) {
                            _selectedUnit = 'jour';
                            _selectedCategory = 'location'; // Suggestion
                          } else {
                            _selectedUnit = 'kg';
                            _selectedCategory = 'cereale';
                          }
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Vente'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Location'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Picker (Same as before)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ..._selectedImages.map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  file,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.remove(file);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: _isLocation
                        ? 'Nom de l\'équipement'
                        : 'Nom du produit',
                  ),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _isLocation
                              ? 'Prix par jour (FCFA)'
                              : 'Prix (FCFA)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unité'),
                        items: _units
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLocation) ...[
                  TextFormField(
                    controller: _minDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durée minimum (jours)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cautionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Caution (FCFA)',
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantité Disponible',
                    ),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _locController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu (Ville/Quartier)',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optionnel)',
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                      builder: (context, state) {
                        if (state is MarketplaceLoading) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        return Text(
                          _isLocation
                              ? 'Publier la location'
                              : 'Mettre en vente',
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
