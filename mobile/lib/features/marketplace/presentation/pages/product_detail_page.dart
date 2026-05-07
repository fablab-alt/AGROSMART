import 'package:agriculture/core/config/environment_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/product.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _showContactOptions = false;

  Product get product => widget.product;

  /// Vérifie si l'utilisateur est authentifié et affiche un dialog sinon
  void _requireAuth(BuildContext context, VoidCallback onAuthenticated) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      onAuthenticated();
    } else {
      _showAuthRequiredDialog(context);
    }
  }

  /// Dialog invitant l'utilisateur à se connecter
  void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez être connecté pour effectuer cette action. '
          'Connectez-vous ou créez un compte pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/login');
            },
            child: const Text('Se connecter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/role-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  void _addToCart() {
    context.read<CartBloc>().add(
      AddToCart(
        produitId: product.id,
        quantite: _quantity,
        productName: product.nom,
        productPrice: product.prix,
        productUnit: product.unite,
        productStock: product.quantiteDisponible.toInt(),
        productImages: product.images,
        productCategory: product.categorie,
        vendeurNom: product.vendeurNom,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity x ${product.nom} ajouté au panier'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Voir le panier',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  void _buyNow() {
    // Ajouter au panier puis aller directement au checkout
    context.read<CartBloc>().add(
      AddToCart(
        produitId: product.id,
        quantite: _quantity,
        productName: product.nom,
        productPrice: product.prix,
        productUnit: product.unite,
        productStock: product.quantiteDisponible.toInt(),
        productImages: product.images,
        productCategory: product.categorie,
        vendeurNom: product.vendeurNom,
      ),
    );
    // Petite delay pour permettre au panier de se mettre à jour
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.push('/checkout');
      }
    });
  }

  void _toggleFavorite() {
    _requireAuth(context, () {
      context.read<FavoritesBloc>().add(
        ToggleFavorite(produitId: product.id, productName: product.nom),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.nom,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bouton Favoris avec état réel
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, favState) {
              final isFavorite =
                  favState is FavoritesLoaded &&
                  favState.isFavorite(product.id);

              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                tooltip: isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: _toggleFavorite,
              );
            },
          ),
          // Bouton Partager
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage bientôt disponible')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _getImageUrl(product.images.first),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom et prix
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.nom,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${product.prix.toInt()} FCFA',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          if (product.unite != null)
                            Text(
                              '/ ${product.unite}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(
                        product.categorie.toUpperCase(),
                        Colors.green[100]!,
                        Colors.green[800]!,
                      ),
                      if (product.localisation != null)
                        _buildTag(
                          '📍 ${product.localisation}',
                          Colors.blue[100]!,
                          Colors.blue[800]!,
                        ),
                      _buildTag(
                        'Stock: ${product.quantiteDisponible.toInt()}',
                        product.quantiteDisponible > 0
                            ? Colors.green[100]!
                            : Colors.red[100]!,
                        product.quantiteDisponible > 0
                            ? Colors.green[800]!
                            : Colors.red[800]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sélecteur de quantité
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? "Aucune description fournie.",
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Vendeur
                  const Text(
                    "Vendeur",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildSellerCard(),

                  const SizedBox(height: 16),

                  // Options de contact (collapsible)
                  _buildContactSection(),

                  // Espace pour le bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'Quantité :',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _quantity < product.quantiteDisponible.toInt()
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[100],
            child: Icon(Icons.person, color: Colors.green[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vendeur Partenaire",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "Membre depuis ${product.createdAt.year}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil vendeur bientôt disponible'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showContactOptions = !_showContactOptions),
          child: Row(
            children: [
              const Text(
                "Contacter le vendeur",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Icon(
                _showContactOptions
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
            ],
          ),
        ),
        if (_showContactOptions) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onPressed: () => _launchWhatsApp(product.vendeurTelephone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone,
                  label: 'Appeler',
                  color: Colors.blue,
                  onPressed: () => _launchCall(product.vendeurTelephone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.sms,
                  label: 'SMS',
                  color: Colors.orange,
                  onPressed: () => _launchSMS(product.vendeurTelephone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: Colors.purple,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat interne bientôt disponible'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final totalPrice = product.prix * _quantity;
    final isAvailable = product.quantiteDisponible > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  '${totalPrice.toInt()} FCFA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Boutons d'action
            Row(
              children: [
                // Ajouter au panier
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isAvailable ? _addToCart : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Ajouter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Acheter maintenant
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isAvailable ? _buyNow : null,
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Commander maintenant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!isAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Produit actuellement indisponible',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Numéro non disponible')));
      return;
    }
    final number = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Numéro non disponible')));
      return;
    }
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSMS(String? phone) async {
    if (phone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Numéro non disponible')));
      return;
    }
    final uri = Uri.parse("sms:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    if (!path.startsWith('/')) path = '/$path';
    return '${EnvironmentConfig.backendOrigin}$path';
  }
}
