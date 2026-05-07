import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stock.dart';
import '../bloc/stock_bloc.dart';
import '../bloc/stock_event.dart';
import '../bloc/stock_state.dart';

/// Page principale pour afficher et gérer les stocks agricoles
class StocksPage extends StatefulWidget {
  const StocksPage({super.key});

  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage> {
  StockCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  void _loadStocks() {
    context.read<StockBloc>().add(
      LoadStocks(categorie: _selectedCategory?.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Stocks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StockBloc>().add(const RefreshStocks());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: BlocConsumer<StockBloc, StockState>(
              listener: (context, state) {
                if (state is StockError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is StockCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock créé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStocks();
                } else if (state is StockDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadStocks();
                }
              },
              builder: (context, state) {
                if (state is StockLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is StocksLoaded) {
                  if (state.stocks.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildStocksList(state.stocks);
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'stocks_add_fab',
        onPressed: () {
          // TODO: Naviguer vers la page de création de stock
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Création de stock à venir')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Stock'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'Tous', '📦'),
          ...StockCategory.values.map(
            (category) =>
                _buildCategoryChip(category, category.label, category.icon),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    StockCategory? category,
    String label,
    String icon,
  ) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _loadStocks();
        },
      ),
    );
  }

  Widget _buildStocksList(List<Stock> stocks) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<StockBloc>().add(const RefreshStocks());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: stocks.length,
        itemBuilder: (context, index) {
          final stock = stocks[index];
          return _buildStockCard(stock);
        },
      ),
    );
  }

  Widget _buildStockCard(Stock stock) {
    final pourcentage = stock.pourcentageDuSeuil;
    final Color statusColor = stock.estEpuise
        ? Colors.red
        : stock.estEnDessousDuSeuil
        ? Colors.orange
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          // TODO: Naviguer vers la page de détail
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Détail de ${stock.nom}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stock.categorie.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stock.type,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      stock.estEpuise
                          ? 'Épuisé'
                          : stock.estEnDessousDuSeuil
                          ? 'Stock bas'
                          : 'OK',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${stock.quantite} ${stock.unite}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Seuil d\'alerte',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${stock.seuilAlerte} ${stock.unite}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pourcentage > 100 ? 1.0 : pourcentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${pourcentage.toStringAsFixed(0)}% du seuil',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (stock.parcelle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.landscape, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      stock.parcelle!.nom,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              if (stock.nombreAlertesNonLues != null &&
                  stock.nombreAlertesNonLues! > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stock.nombreAlertesNonLues} alerte(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun stock enregistré',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter un nouveau stock',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
