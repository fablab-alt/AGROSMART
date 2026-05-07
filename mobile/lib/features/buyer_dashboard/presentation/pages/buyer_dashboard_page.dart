import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../../core/providers/tab_navigation_provider.dart';

/// Dashboard pour les utilisateurs avec le rôle ACHETEUR
class BuyerDashboardPage extends StatefulWidget {
  const BuyerDashboardPage({super.key});

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Charger les données initiales
    _loadData();
  }

  void _loadData() {
    context.read<CartBloc>().add(LoadCart());
    // TODO: Charger les commandes
    // context.read<OrdersBloc>().add(LoadOrders());
  }

  /// Basculer vers l'onglet Marketplace dans le shell principal
  void _goToMarketplace() {
    TabNavigationProvider.changeTab(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String userName = "Acheteur";
                    if (state is AuthAuthenticated) {
                      userName = state.user.prenoms.isNotEmpty
                          ? state.user.prenoms
                          : state.user.nom;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _goToMarketplace,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey[400]),
                                const SizedBox(width: 12),
                                Text(
                                  'Rechercher des produits...',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context, isDark),
                    const SizedBox(height: 24),
                    _buildRecentOrders(context, isDark),
                    const SizedBox(height: 24),
                    _buildFavorites(context, isDark),
                    const SizedBox(height: 24),
                    _buildCategories(context, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickActionButton(
          icon: Icons.store_outlined,
          label: 'Marketplace',
          color: Colors.green,
          onTap: _goToMarketplace,
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_outlined,
          label: 'Commandes',
          color: Colors.blue,
          onTap: () => context.push('/orders'),
        ),
        _QuickActionButton(
          icon: Icons.favorite_outline,
          label: 'Favoris',
          color: Colors.red,
          onTap: () => context.push('/favorites'),
        ),
        _QuickActionButton(
          icon: Icons.local_shipping_outlined,
          label: 'Livraisons',
          color: Colors.orange,
          onTap: () => context.push('/orders'),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes commandes récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/orders'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Placeholder pour les commandes
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune commande récente',
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _goToMarketplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Découvrir le marketplace'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavorites(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Produits favoris',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/favorites'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Placeholder pour les favoris
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.favorite_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Aucun favori pour le moment',
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Explorez le marketplace et ajoutez des produits à vos favoris',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context, bool isDark) {
    final categories = [
      {'name': 'Semences', 'icon': Icons.grass, 'color': Colors.green},
      {'name': 'Engrais', 'icon': Icons.eco, 'color': Colors.brown},
      {'name': 'Équipements', 'icon': Icons.build, 'color': Colors.blue},
      {'name': 'Fruits', 'icon': Icons.apple, 'color': Colors.red},
      {'name': 'Légumes', 'icon': Icons.local_florist, 'color': Colors.orange},
      {'name': 'Céréales', 'icon': Icons.grain, 'color': Colors.amber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories populaires',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return InkWell(
              onTap: () => context.push('/marketplace'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
