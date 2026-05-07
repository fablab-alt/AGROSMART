import 'package:agriculture/core/config/environment_config.dart';
import 'package:agriculture/core/widgets/smart_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/marketplace_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'product_detail_page.dart';
import '../../domain/entities/product.dart';

// Placeholder classes for Search and Filter - To be moved to separate files
class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) =>
      Center(child: Text("Résultats pour '$query'"));

  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text("Recherchez un produit..."));
}

class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;

  // Catégories disponibles dans le marketplace
  static const List<Map<String, dynamic>> categories = [
    {'value': null, 'label': 'Toutes les catégories', 'icon': Icons.apps},
    {'value': 'semences', 'label': 'Semences', 'icon': Icons.grass},
    {'value': 'engrais', 'label': 'Engrais', 'icon': Icons.science},
    {'value': 'equipements', 'label': 'Équipements', 'icon': Icons.build},
    {'value': 'location', 'label': 'Location', 'icon': Icons.calendar_today},
    {'value': 'pesticides', 'label': 'Pesticides', 'icon': Icons.bug_report},
    {'value': 'outils', 'label': 'Outils', 'icon': Icons.handyman},
    {'value': 'recoltes', 'label': 'Récoltes', 'icon': Icons.agriculture},
    {'value': 'autres', 'label': 'Autres', 'icon': Icons.more_horiz},
  ];

  // Catégories autorisées pour les PRODUCTEURS (vendre récoltes, louer/acheter équipements)
  static const List<String> producteurCategories = [
    'equipements', // Peut acheter équipements
    'location', // Peut louer équipements
    'recoltes', // Peut vendre ses récoltes
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  List<Map<String, dynamic>> _getFilteredCategories() {
    // Récupérer le rôle de l'utilisateur depuis AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user.role == 'PRODUCTEUR') {
      // Filtrer pour ne montrer que les catégories autorisées aux producteurs
      return categories.where((cat) {
        return cat['value'] == null ||
            producteurCategories.contains(cat['value']);
      }).toList();
    }
    // Acheteurs voient tout
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Filtrer par catégorie",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_selectedCategory != null)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCategory = null);
                    widget.onCategorySelected(null);
                    Navigator.pop(context);
                  },
                  child: const Text('Effacer'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredCategories.map((cat) {
              final isSelected = _selectedCategory == cat['value'];
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.green[700],
                    ),
                    const SizedBox(width: 6),
                    Text(cat['label'] as String),
                  ],
                ),
                selectedColor: Colors.green[700],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                onSelected: (selected) {
                  setState(() => _selectedCategory = cat['value'] as String?);
                  widget.onCategorySelected(cat['value'] as String?);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<MarketplaceBloc>()..add(LoadMarketplaceProducts()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Marketplace',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(),
                  );
                },
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: _selectedCategory != null,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => FilterBottomSheet(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => context.push('/cart'),
              ),
            ],
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: 'Acheter'),
                Tab(text: 'Louer'),
              ],
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Filtre actif indicator
                  if (_selectedCategory != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.green[50],
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtre: ${_getCategoryLabel(_selectedCategory!)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = null),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                      builder: (context, state) {
                        if (state is MarketplaceLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is MarketplaceError) {
                          // Improved Error UI
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Oups !",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    "Impossible de charger les produits pour le moment.",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<MarketplaceBloc>().add(
                                      LoadMarketplaceProducts(),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Réessayer"),
                                ),
                              ],
                            ),
                          );
                        } else if (state is MarketplaceLoaded) {
                          // Appliquer le filtre par catégorie
                          var filteredProducts = state.products;
                          if (_selectedCategory != null) {
                            filteredProducts = state.products
                                .where(
                                  (p) =>
                                      p.categorie.toLowerCase() ==
                                      _selectedCategory!.toLowerCase(),
                                )
                                .toList();
                          }

                          final sales = filteredProducts
                              .where(
                                (p) =>
                                    p.description?.toLowerCase().contains(
                                          'location',
                                        ) !=
                                        true &&
                                    p.categorie != 'location',
                              )
                              .toList();
                          final rentals = filteredProducts
                              .where(
                                (p) =>
                                    p.description?.toLowerCase().contains(
                                          'location',
                                        ) ==
                                        true ||
                                    p.categorie == 'location',
                              )
                              .toList();

                          return TabBarView(
                            children: [
                              _buildProductGrid(
                                sales,
                                "Aucun produit en vente",
                              ),
                              _buildProductGrid(
                                rentals,
                                "Aucun produit en location",
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    // Seuls les producteurs connectés peuvent ajouter des produits
                    if (authState is AuthAuthenticated &&
                        authState.user.role == 'PRODUCTEUR') {
                      return FloatingActionButton(
                        heroTag: 'marketplace_add_fab',
                        onPressed: () => _showAddOptions(context),
                        tooltip: 'Ajouter une annonce',
                        backgroundColor: const Color(0xFF28A745),
                        child: const Icon(Icons.add, color: Colors.white),
                      );
                    }
                    // Ne pas afficher le FAB pour les non-authentifiés ou acheteurs
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    const labels = {
      'semences': 'Semences',
      'engrais': 'Engrais',
      'equipements': 'Équipements',
      'location': 'Location',
      'pesticides': 'Pesticides',
      'outils': 'Outils',
      'recoltes': 'Récoltes',
      'autres': 'Autres',
    };
    return labels[category.toLowerCase()] ?? category;
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sell),
            title: const Text('Vendre un produit'),
            onTap: () {
              Navigator.pop(context);
              context.push('/add-product?type=vente');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Mettre en location'),
            onTap: () {
              Navigator.pop(context);
              context.push('/add-product?type=location');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, String emptyMessage) {
    if (products.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MarketplaceBloc>().add(LoadMarketplaceProducts());
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: product.images.isNotEmpty
                        ? SmartNetworkImage(
                            imageUrl: _getImageUrl(product.images.first),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.prix.toInt()} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categorie.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.localisation ?? 'Non spécifié',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return '${EnvironmentConfig.backendOrigin}$path';
  }
}
