import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/domain/entities/user.dart';
import '../../../features/marketplace/presentation/pages/marketplace_page.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/buyer_dashboard/presentation/pages/buyer_dashboard_page.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/capteurs/presentation/pages/capteurs_page.dart';
import '../../core/providers/tab_navigation_provider.dart';

/// Page principale avec bottom navigation
/// Navigation différenciée selon le rôle:
/// - PRODUCTEUR: Accueil, Monitoring (Parcelles+Capteurs+Alertes), Vendre, Profil
/// - ACHETEUR: Accueil, Marketplace (achat), Panier, Profil
class MainShellPage extends StatefulWidget {
  final int initialIndex;

  const MainShellPage({super.key, this.initialIndex = 0});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _currentIndex;
  late ValueNotifier<int> _currentIndexNotifier;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _currentIndexNotifier = ValueNotifier<int>(_currentIndex);
  }

  @override
  void dispose() {
    _currentIndexNotifier.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _currentIndexNotifier.value = index;
  }

  bool _isProducer(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.role != 'ACHETEUR';
    }
    return false; // Par défaut, considérer comme acheteur
  }

  @override
  Widget build(BuildContext context) {
    final isProducer = _isProducer(context);

    return TabNavigationProvider(
      currentIndexNotifier: _currentIndexNotifier,
      onTabChange: _changeTab,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: isProducer
              ? [
                  // PRODUCTEUR: Dashboard, Monitoring IoT, Marketplace, Profil
                  const DashboardPage(), // 0: Dashboard producteur
                  const CapteursPage(), // 1: Monitoring IoT (design original)
                  const MarketplacePage(), // 2: Marketplace (vente)
                  const _ProfileTab(), // 3: Profil
                ]
              : [
                  // ACHETEUR: Dashboard, Marketplace, Panier, Profil
                  const BuyerDashboardPage(), // 0: Dashboard acheteur
                  const MarketplacePage(), // 1: Marketplace (achat)
                  const _CartTab(), // 2: Panier
                  const _ProfileTab(), // 3: Profil
                ],
        ),
        bottomNavigationBar: _buildBottomNav(isProducer),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isProducer) {
    // Titres selon l'onglet et le rôle
    final titles = isProducer
        ? ['Tableau de bord', 'Monitoring', 'Marketplace', 'Mon Profil']
        : ['Accueil', 'Marketplace', 'Mon Panier', 'Mon Profil'];

    return AppBar(
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: _currentIndex != 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Retour à l'onglet Accueil
                _changeTab(0);
              },
            )
          : null,
      actions: [
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        // Panier (visible seulement pour acheteur et pas sur l'onglet panier)
        if (!isProducer && _currentIndex != 2)
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              int cartCount = 0;
              if (cartState is CartLoaded) {
                cartCount = cartState.totalItems;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Panier',
                    onPressed: () {
                      _changeTab(2); // Aller au panier
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        // Menu settings
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                context.push('/settings');
                break;
              case 'support':
                context.push('/support');
                break;
              case 'about':
                context.push('/about');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'support',
              child: Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Aide & Support'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('À propos'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isProducer) {
    if (isProducer) {
      return _buildProducerBottomNav();
    } else {
      return _buildBuyerBottomNav();
    }
  }

  /// Navigation pour le PRODUCTEUR: Accueil, Monitoring, Marketplace, Profil
  Widget _buildProducerBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _changeTab(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined),
          activeIcon: Icon(Icons.monitor_heart),
          label: 'Monitoring',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Marketplace',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  /// Navigation pour l'ACHETEUR: Accueil, Marketplace, Panier, Profil
  Widget _buildBuyerBottomNav() {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (prev, curr) {
        if (prev is CartLoaded && curr is CartLoaded) {
          return prev.totalItems != curr.totalItems;
        }
        return true;
      },
      builder: (context, cartState) {
        int cartCount = 0;
        if (cartState is CartLoaded) {
          cartCount = cartState.totalItems;
        }

        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _changeTab(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Accueil',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Marketplace',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cartCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cartCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartCount > 9 ? '9+' : cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Panier',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        );
      },
    );
  }
}

/// Onglet Panier (wrapper pour CartPage dans le shell)
class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mon Panier',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Vider le panier',
                  onPressed: () => _showClearCartDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartLoaded && state.items.isNotEmpty) {
            return _buildCartContent(context, state);
          }

          return _buildEmptyCart(context);
        },
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tous les articles du panier ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CartBloc>().add(ClearCart());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parcourez le marketplace et ajoutez des produits',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nom,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.prix.toStringAsFixed(0)} FCFA x ${item.quantite}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.totalPrice.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              iconSize: 20,
                              color: Colors.grey[600],
                              onPressed: () {
                                if (item.quantite > 1) {
                                  context.read<CartBloc>().add(
                                    UpdateCartItemQuantity(
                                      itemId: item.id,
                                      quantite: item.quantite - 1,
                                    ),
                                  );
                                }
                              },
                            ),
                            Text(
                              '${item.quantite}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              iconSize: 20,
                              color: Colors.green[700],
                              onPressed: () {
                                context.read<CartBloc>().add(
                                  UpdateCartItemQuantity(
                                    itemId: item.id,
                                    quantite: item.quantite + 1,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Footer avec total et bouton
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.totalItems} article${state.totalItems > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      '${state.totalPrice.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commander',
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
        ),
      ],
    );
  }
}

/// Onglet Profil
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return _buildAuthenticatedProfile(context, state);
        }
        return _buildGuestProfile(context);
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Connectez-vous',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accédez à votre profil, vos commandes et vos favoris',
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/role-selection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedProfile(
    BuildContext context,
    AuthAuthenticated state,
  ) {
    final user = state.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isProducer = user.role != 'ACHETEUR';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header avec background turquoise
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Avatar circulaire
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF1E88E5),
                    child: Text(
                      user.prenoms.isNotEmpty
                          ? user.prenoms[0].toUpperCase() +
                                user.nom[0].toUpperCase()
                          : user.nom[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Infos utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.prenoms} ${user.nom}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isProducer ? 'Producteur certifié' : 'Acheteur',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton modifier profil
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    context.push('/edit-profile');
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Section Statistiques (pour producteur)
                if (isProducer) _buildStatsCard(context, isDark, user),

                // Section Statistiques (pour acheteur)
                if (!isProducer) _buildBuyerStatsCard(context, isDark, user),

                const SizedBox(height: 16),

                // Section Paramètres
                _buildSettingsCard(context, isDark),

                const SizedBox(height: 16),

                // Section Support
                _buildSupportCard(context, isDark),

                const SizedBox(height: 16),

                // Bouton Déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Afficher une confirmation avant déconnexion
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text(
                            'Voulez-vous vraiment vous déconnecter ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.read<AuthBloc>().add(LogoutRequested());
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Déconnexion'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Carte Statistiques pour Producteur
  Widget _buildStatsCard(BuildContext context, bool isDark, User user) {
    // Calculer la production moyenne des 3 derniers mois
    double totalProduction =
        (user.productionMois1 ?? 0) +
        (user.productionMois2 ?? 0) +
        (user.productionMois3 ?? 0);
    String productionText = totalProduction > 0
        ? '${totalProduction.toStringAsFixed(0)} kg'
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  '${user.parcellesCount}',
                  'Parcelles',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  user.hectaresTotal > 0
                      ? '${user.hectaresTotal.toStringAsFixed(1)}ha'
                      : user.superficieExploitee != null
                      ? '${user.superficieExploitee!.toStringAsFixed(1)}${user.uniteSuperficie ?? 'ha'}'
                      : 'N/A',
                  'Surface totale',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  productionText,
                  'Production (3 mois)',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  context,
                  '${user.capteursCount}',
                  'Capteurs',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Carte Statistiques pour Acheteur
  Widget _buildBuyerStatsCard(BuildContext context, bool isDark, User user) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        int itemsInCart = 0;
        if (cartState is CartLoaded) {
          itemsInCart = cartState.totalItems;
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '$itemsInCart',
                      'Articles panier',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '0',
                      'Commandes',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      '${user.points}',
                      'Points',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      user.level ?? 'Novice',
                      'Niveau',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Carte Paramètres
  Widget _buildSettingsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paramètres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSettingRow(context, 'Notifications push', true, (value) {
            // TODO: Gérer le changement
          }),
          const Divider(height: 24),
          _buildSettingRow(context, 'Mode vocal', false, (value) {
            // TODO: Gérer le changement
          }),
          const Divider(height: 24),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Langue', style: TextStyle(fontSize: 15)),
                Row(
                  children: [
                    Text(
                      'Français',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green[600],
        ),
      ],
    );
  }

  // Carte Support
  Widget _buildSupportCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSupportItem(
            context,
            Icons.phone_outlined,
            'Contacter le support',
            Colors.green,
            () => context.push('/support'),
          ),
          const SizedBox(height: 12),
          _buildSupportItem(
            context,
            Icons.menu_book_outlined,
            "Guide d'utilisation",
            Colors.blue,
            () {
              // TODO: Ouvrir le guide
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
