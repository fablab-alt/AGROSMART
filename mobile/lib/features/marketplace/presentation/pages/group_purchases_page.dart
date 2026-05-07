import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/injection_container.dart' as di;
import '../bloc/group_purchase_bloc.dart';
import 'package:agriculture/features/marketplace/domain/entities/group_purchase.dart';

class GroupPurchasesListPage extends StatelessWidget {
  const GroupPurchasesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achats Groupés'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocProvider(
        create: (context) =>
            di.sl<GroupPurchaseBloc>()..add(LoadGroupPurchases()),
        child: BlocBuilder<GroupPurchaseBloc, GroupPurchaseState>(
          builder: (context, state) {
            if (state is GroupPurchaseLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GroupPurchaseError) {
              return Center(child: Text('Erreur: ${state.message}'));
            }

            if (state is GroupPurchasesLoaded) {
              final purchases = state.groupPurchases;
              if (purchases.isEmpty) {
                return const Center(child: Text('Aucun achat groupé en cours'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: purchases.length,
                itemBuilder: (context, index) {
                  return _buildGroupPurchaseCard(context, purchases[index]);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'group_purchases_fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Création d\'achat groupé (bientôt)')),
          );
        },
        label: const Text('Créer un groupe'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupPurchaseCard(BuildContext context, GroupPurchase purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupPurchaseDetailPage(purchase: purchase),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      purchase.categorie.toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '-${purchase.economiePourcentage}%',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                purchase.produitType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lieu: ${purchase.localisationLivraison}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${purchase.quantiteActuelle} / ${purchase.quantiteObjectif} ${purchase.unite}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${purchase.progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: purchase.progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: Theme.of(context).primaryColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prix Groupe',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${purchase.prixGroupe.toStringAsFixed(0)} F',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  // Avatar stack placeholder for participants
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Align(
                          widthFactor: 0.7,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[(i + 1) * 200],
                            child: const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '+12', // Mock count
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
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

class GroupPurchaseDetailPage extends StatefulWidget {
  final GroupPurchase purchase;

  const GroupPurchaseDetailPage({super.key, required this.purchase});

  @override
  State<GroupPurchaseDetailPage> createState() =>
      _GroupPurchaseDetailPageState();
}

class _GroupPurchaseDetailPageState extends State<GroupPurchaseDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails Achat Groupé')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.purchase.produitType,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(widget.purchase.localisationLivraison),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Économie',
                    '-${widget.purchase.economiePourcentage}%',
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Prix',
                    '${widget.purchase.prixGroupe.toStringAsFixed(0)} F',
                    Colors.black,
                  ),
                  _buildStatItem(
                    'Cible',
                    '${widget.purchase.quantiteObjectif} ${widget.purchase.unite}',
                    Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.purchase.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Join Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rejoindre ce groupe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) setState(() => _quantity--);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          '$_quantity ${widget.purchase.unite}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total à payer: ${(_quantity * widget.purchase.prixGroupe).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement Join Logic with Payment
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Rejoint avec $_quantity ${widget.purchase.unite} ! (Simulation)',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('CONFIRMER MA PARTICIPATION'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
