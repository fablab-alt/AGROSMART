import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/core/config/environment_config.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../bloc/favorites_bloc.dart';
import '../../domain/entities/favorite.dart';

/// Page des favoris - Affiche les produits favoris de l'utilisateur
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Recharger les favoris à chaque affichage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<FavoritesBloc>().add(LoadFavorites());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Si non authentifié, afficher invitation à se connecter
        if (authState is! AuthAuthenticated) {
          return _buildNotAuthenticatedView(context, isDark);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mes Favoris',
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
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  context.read<FavoritesBloc>().add(LoadFavorites());
                },
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
          body: BlocConsumer<FavoritesBloc, FavoritesState>(
            listener: (context, state) {
              if (state is FavoriteToggled) {
                final message = state.isNowFavorite
                    ? '${state.productName ?? "Produit"} ajouté aux favoris'
                    : '${state.productName ?? "Produit"} retiré des favoris';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is FavoritesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is FavoritesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is FavoritesLoaded) {
                if (state.favorites.isEmpty) {
                  return _buildEmptyFavorites(context, isDark);
                }
                return _buildFavoritesList(context, state.favorites, isDark);
              }

              if (state is FavoritesError) {
                return _buildErrorView(context, state.message, isDark);
              }

              // État initial - charger les favoris
              return const Center(child: CircularProgressIndicator());
            },
          ),
        );
      },
    );
  }

  Widget _buildNotAuthenticatedView(BuildContext context, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos favoris',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sauvegardez vos produits préférés et retrouvez-les facilement',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Pas encore de favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parcourez le marketplace et ajoutez des produits à vos favoris en cliquant sur le ❤️',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.store),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Explorer le marketplace',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 24),
            Text(
              'Impossible de charger les favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<FavoritesBloc>().add(LoadFavorites());
              },
              icon: const Icon(Icons.refresh),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    BuildContext context,
    List<FavoriteItem> favorites,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoritesBloc>().add(LoadFavorites());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final item = favorites[index];
          return _FavoriteItemCard(
            item: item,
            onRemove: () {
              context.read<FavoritesBloc>().add(
                RemoveFromFavorites(produitId: item.produitId),
              );
            },
            onAddToCart: () {
              context.read<CartBloc>().add(
                AddToCart(produitId: item.produitId, quantite: 1),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.nom} ajouté au panier'),
                  action: SnackBarAction(
                    label: 'Voir',
                    onPressed: () => context.push('/cart'),
                  ),
                ),
              );
            },
            onTap: () {
              // Naviguer vers la page détail du produit
              context.push('/product/${item.produitId}');
            },
          );
        },
      ),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _FavoriteItemCard({
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
    required this.onTap,
  });

  String _getImageUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return '${EnvironmentConfig.backendOrigin}$path';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getImageUrl(item.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: Colors.grey[400],
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.categorie,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        if (item.vendeurNom != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'par ${item.vendeurNom}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${item.prix.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green[700],
                          ),
                        ),
                        const Spacer(),
                        if (!item.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Indisponible',
                              style: TextStyle(fontSize: 11, color: Colors.red),
                            ),
                          )
                        else
                          Text(
                            'Stock: ${item.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: 'Retirer des favoris',
                  ),
                  if (item.isAvailable)
                    IconButton(
                      onPressed: onAddToCart,
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: Colors.green[700],
                      ),
                      tooltip: 'Ajouter au panier',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
