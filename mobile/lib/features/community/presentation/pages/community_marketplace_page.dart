import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/injection_container.dart' as di;
import 'package:agriculture/core/widgets/cached_image.dart';
import '../bloc/community_listing_bloc.dart';
import '../../domain/entities/community_listing.dart';

class CommunityMarketplacePage extends StatefulWidget {
  const CommunityMarketplacePage({super.key});

  @override
  State<CommunityMarketplacePage> createState() =>
      _CommunityMarketplacePageState();
}

class _CommunityMarketplacePageState extends State<CommunityMarketplacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ListingType? _selectedType;
  String? _selectedCategorie;

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'label': 'Tous', 'icon': Icons.apps},
    {'id': 'tracteur', 'label': 'Tracteurs', 'icon': Icons.agriculture},
    {'id': 'semoir', 'label': 'Semoirs', 'icon': Icons.grass},
    {
      'id': 'pulverisateur',
      'label': 'Pulvérisateurs',
      'icon': Icons.water_drop,
    },
    {'id': 'moissonneuse', 'label': 'Moissonneuses', 'icon': Icons.content_cut},
    {'id': 'charrue', 'label': 'Charrues', 'icon': Icons.landscape},
    {'id': 'pompe', 'label': 'Pompes', 'icon': Icons.water},
    {'id': 'transport', 'label': 'Transport', 'icon': Icons.local_shipping},
    {'id': 'autre', 'label': 'Autres', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => di.sl<CommunityListingBloc>()..add(LoadListings()),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          title: const Text('Équipements Communauté'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Tous', icon: Icon(Icons.view_list, size: 20)),
              Tab(text: 'Vente', icon: Icon(Icons.sell, size: 20)),
              Tab(text: 'Location', icon: Icon(Icons.access_time, size: 20)),
            ],
            onTap: (index) {
              setState(() {
                if (index == 0) {
                  _selectedType = null;
                } else if (index == 1) {
                  _selectedType = ListingType.vente;
                } else {
                  _selectedType = ListingType.location;
                }
              });
              context.read<CommunityListingBloc>().add(
                LoadListings(
                  type: _selectedType,
                  categorie: _selectedCategorie,
                ),
              );
            },
          ),
        ),
        body: Column(
          children: [
            // Catégories horizontales
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategorie == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
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
                        setState(() {
                          _selectedCategorie = selected ? cat['id'] : null;
                        });
                        context.read<CommunityListingBloc>().add(
                          LoadListings(
                            type: _selectedType,
                            categorie: _selectedCategorie,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Liste des annonces
            Expanded(
              child: BlocBuilder<CommunityListingBloc, CommunityListingState>(
                builder: (context, state) {
                  if (state is CommunityListingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CommunityListingError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<CommunityListingBloc>()
                                .add(LoadListings()),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ListingsLoaded) {
                    if (state.listings.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<CommunityListingBloc>().add(
                          LoadListings(
                            type: _selectedType,
                            categorie: _selectedCategorie,
                          ),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.listings.length,
                        itemBuilder: (context, index) {
                          return _buildListingCard(
                            context,
                            state.listings[index],
                            state.favoriteIds.contains(
                              state.listings[index].id,
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'community_marketplace_fab',
          onPressed: () => _showCreateListingSheet(context),
          backgroundColor: const Color(0xFF1B5E20),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Publier', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce pour le moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à publier une annonce !',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(
    BuildContext context,
    CommunityListing listing,
    bool isFavorite,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showListingDetail(context, listing),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec cache
            Stack(
              children: [
                ProductImage(
                  imageUrl: listing.images.isNotEmpty
                      ? listing.images.first
                      : null,
                  height: 180,
                  productName: listing.titre,
                ),
                // Badge type
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: listing.isForSale
                          ? Colors.orange[700]
                          : Colors.blue[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      listing.typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Favoris
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      context.read<CommunityListingBloc>().add(
                        ToggleFavorite(listing.id),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.titre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        listing.priceDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.localisation,
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.verified,
                        listing.etat,
                        Colors.green[100]!,
                        Colors.green[800]!,
                      ),
                      const SizedBox(width: 8),
                      if (listing.negociable)
                        _buildInfoChip(
                          Icons.handshake,
                          'Négociable',
                          Colors.blue[100]!,
                          Colors.blue[800]!,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.vues}',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vendeur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green[100],
                        backgroundImage: listing.vendeurPhoto != null
                            ? NetworkImage(listing.vendeurPhoto!)
                            : null,
                        child: listing.vendeurPhoto == null
                            ? Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.green[700],
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          listing.vendeurNom,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showContactSheet(context, listing),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Contacter'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[700],
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.agriculture, size: 60, color: Colors.grey[500]),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showListingDetail(BuildContext context, CommunityListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) =>
            _ListingDetailSheet(listing: listing, scrollController: controller),
      ),
    );
  }

  void _showContactSheet(BuildContext context, CommunityListing listing) {
    final messageController = TextEditingController();
    final bloc = context.read<CommunityListingBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Contacter ${listing.vendeurNom}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'À propos de: ${listing.titre}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      bloc.add(
                        SendInquiry(
                          listingId: listing.id,
                          message: messageController.text,
                        ),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message envoyé !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateListingSheet(BuildContext context) {
    context.push('/community-marketplace/create');
  }
}

class _ListingDetailSheet extends StatelessWidget {
  final CommunityListing listing;
  final ScrollController scrollController;

  const _ListingDetailSheet({
    required this.listing,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Images carousel
          if (listing.images.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: listing.images.length,
                itemBuilder: (_, index) => CachedImage(
                  imageUrl: listing.images[index],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.agriculture, size: 80),
            ),

          const SizedBox(height: 24),

          // Titre et prix
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: listing.isForSale
                            ? Colors.orange[100]
                            : Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.typeLabel,
                        style: TextStyle(
                          color: listing.isForSale
                              ? Colors.orange[800]
                              : Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      listing.titre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    listing.priceDisplay,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  if (listing.negociable)
                    Text(
                      'Négociable',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            listing.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Détails
          const Text(
            'Détails',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.category, 'Catégorie', listing.categorie),
          _buildDetailRow(Icons.verified, 'État', listing.etat),
          _buildDetailRow(
            Icons.location_on,
            'Localisation',
            listing.localisation,
          ),
          _buildDetailRow(Icons.visibility, 'Vues', '${listing.vues}'),

          const SizedBox(height: 24),

          // Vendeur
          const Text(
            'Vendeur',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[100],
              backgroundImage: listing.vendeurPhoto != null
                  ? NetworkImage(listing.vendeurPhoto!)
                  : null,
              child: listing.vendeurPhoto == null
                  ? Icon(Icons.person, size: 30, color: Colors.green[700])
                  : null,
            ),
            title: Text(
              listing.vendeurNom,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text('Membre de la communauté'),
          ),

          const SizedBox(height: 32),

          // Bouton contact
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Show contact sheet
              },
              icon: const Icon(Icons.message),
              label: const Text('Contacter le vendeur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
