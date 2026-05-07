import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/search_bloc.dart';

class ProductSearchDelegate extends SearchDelegate<String> {
  final BuildContext blocContext;

  ProductSearchDelegate(this.blocContext);

  @override
  String get searchFieldLabel => 'Rechercher des produits...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Entrez un terme de recherche'));
    }

    // Trigger search
    blocContext.read<SearchBloc>().add(SearchProducts(query));

    return BlocBuilder<SearchBloc, SearchState>(
      bloc: blocContext.read<SearchBloc>(),
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SearchError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message),
              ],
            ),
          );
        }

        if (state is SearchLoaded) {
          if (state.results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun résultat pour "$query"',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Essayez avec d\'autres mots-clés',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final product = state.results[index];
              return ListTile(
                leading: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.shopping_bag),
                title: Text(product.nom),
                subtitle: Text('${product.prix.toStringAsFixed(0)} FCFA'),
                onTap: () {
                  close(context, query);
                  context.push('/marketplace/product/${product.id}');
                },
              );
            },
          );
        }

        return const Center(child: Text('Recherchez des produits'));
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      bloc: blocContext.read<SearchBloc>(),
      builder: (context, state) {
        // Load search history
        if (state is! SearchHistoryLoaded) {
          blocContext.read<SearchBloc>().add(LoadSearchHistory());
        }

        if (state is SearchHistoryLoaded) {
          if (query.isEmpty) {
            // Show full search history
            return _buildSearchHistory(context, state.history);
          } else {
            // Filter history based on query
            final filteredHistory = state.history
                .where(
                  (q) => q.query.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

            return _buildSearchHistory(context, filteredHistory);
          }
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSearchHistory(BuildContext context, List<dynamic> history) {
    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucun historique de recherche',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  blocContext.read<SearchBloc>().add(ClearSearchHistory());
                },
                child: const Text('Effacer tout'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final searchQuery = history[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(searchQuery.query),
                subtitle: Text('${searchQuery.resultCount} résultats'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    blocContext.read<SearchBloc>().add(
                      RemoveSearchQuery(searchQuery.query),
                    );
                  },
                ),
                onTap: () {
                  query = searchQuery.query;
                  showResults(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
