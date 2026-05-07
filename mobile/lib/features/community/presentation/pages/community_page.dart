import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:agriculture/features/marketplace/domain/entities/product.dart';
import 'package:agriculture/features/common/presentation/widgets/voice_assistant_sheet.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();
    context.read<MarketplaceBloc>().add(LoadMarketplaceProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Communauté",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Echangez avec d'autres producteurs",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavigationButtons(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Messages récents"),
                  const SizedBox(height: 12),
                  _buildMessagesList(),
                  const SizedBox(height: 24),
                  _buildMarketplaceSection(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'community_fab',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: VoiceAssistantContent(), // Use imported widget
            ),
          );
        },
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                "Messages",
                Icons.chat_bubble_outline,
                const Color(0xFF4285F4), // Blue
                () => context.push('/messages'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavButton(
                "Formations",
                Icons.menu_book,
                const Color(0xFFF57C00), // Orange
                () => context.push('/formations'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                "Équipements",
                Icons.agriculture,
                const Color(0xFF43A047), // Green
                () => context.push('/community-marketplace'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildNavButton(
                "Assistant IA",
                Icons.smart_toy,
                const Color(0xFF7B1FA2), // Purple
                () => context.push('/chatbot'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: Colors.black87),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "Aucune discussion récente",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketplaceSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: Colors.green[700],
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Marketplace",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF28A745)),
                onPressed: () => context.push('/add-product'),
                tooltip: 'Vendre un produit',
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<MarketplaceBloc, MarketplaceState>(
            builder: (context, state) {
              // Use Mock data if empty to match mockup visuals for verification
              final List<Product> products = (state is MarketplaceLoaded)
                  ? state.products
                  : [];

              if (products.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      "Aucun produit en vente",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 150, // Adjusted height
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Placeholder image area
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey[100],
                              child: Center(
                                child: Text(
                                  "IMAGE", // Placeholder text or mock image
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${product.prix.toInt()} FCFA",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Disponible: ${product.quantiteDisponible.toInt()} sacs",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
