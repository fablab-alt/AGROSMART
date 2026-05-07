/// Mixin et widgets pour la pagination infinie
/// AgroSmart - Application Mobile
///
/// Fonctionnalités:
/// - Chargement automatique au scroll
/// - Gestion de l'état de chargement
/// - Indicateurs visuels de chargement
/// - Pull-to-refresh intégré
/// - Gestion des erreurs avec retry
library;

import 'dart:async';
import 'package:flutter/material.dart';

/// État de la pagination
enum PaginationStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
  noMoreData,
}

/// Modèle de données paginées
class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;
  final String? error;
  final PaginationStatus status;

  const PaginatedData({
    this.items = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasMore = false,
    this.error,
    this.status = PaginationStatus.initial,
  });

  PaginatedData<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasMore,
    String? error,
    PaginationStatus? status,
  }) {
    return PaginatedData<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      status: status ?? this.status,
    );
  }

  /// Ajouter de nouveaux items
  PaginatedData<T> appendItems(List<T> newItems, {bool hasMore = true}) {
    return copyWith(
      items: [...items, ...newItems],
      currentPage: currentPage + 1,
      hasMore: hasMore,
      status: hasMore ? PaginationStatus.loaded : PaginationStatus.noMoreData,
    );
  }

  /// Rafraîchir avec de nouveaux items
  PaginatedData<T> refresh(
    List<T> newItems, {
    int? totalPages,
    int? totalItems,
    bool hasMore = true,
  }) {
    return PaginatedData<T>(
      items: newItems,
      currentPage: 1,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore,
      status: PaginationStatus.loaded,
    );
  }
}

/// Contrôleur de pagination
class PaginationController<T> extends ChangeNotifier {
  PaginatedData<T> _data = const PaginatedData();
  final Future<PaginatedData<T>> Function(int page) fetchPage;
  final int pageSize;
  final double loadMoreThreshold;

  PaginationController({
    required this.fetchPage,
    this.pageSize = 20,
    this.loadMoreThreshold = 200.0,
  });

  PaginatedData<T> get data => _data;
  List<T> get items => _data.items;
  bool get isLoading => _data.status == PaginationStatus.loading;
  bool get isLoadingMore => _data.status == PaginationStatus.loadingMore;
  bool get hasError => _data.status == PaginationStatus.error;
  bool get hasMore => _data.hasMore;
  String? get error => _data.error;

  /// Charger la première page
  Future<void> loadInitial() async {
    if (_data.status == PaginationStatus.loading) return;

    _data = _data.copyWith(status: PaginationStatus.loading);
    notifyListeners();

    try {
      final result = await fetchPage(1);
      _data = result.copyWith(status: PaginationStatus.loaded);
    } catch (e) {
      _data = _data.copyWith(
        status: PaginationStatus.error,
        error: e.toString(),
      );
    }

    notifyListeners();
  }

  /// Charger plus d'items
  Future<void> loadMore() async {
    if (!_data.hasMore ||
        _data.status == PaginationStatus.loading ||
        _data.status == PaginationStatus.loadingMore) {
      return;
    }

    _data = _data.copyWith(status: PaginationStatus.loadingMore);
    notifyListeners();

    try {
      final nextPage = _data.currentPage + 1;
      final result = await fetchPage(nextPage);

      _data = _data.appendItems(result.items, hasMore: result.hasMore);
    } catch (e) {
      _data = _data.copyWith(
        status: PaginationStatus.error,
        error: e.toString(),
      );
    }

    notifyListeners();
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    _data = const PaginatedData(status: PaginationStatus.loading);
    notifyListeners();

    try {
      final result = await fetchPage(1);
      _data = result.copyWith(status: PaginationStatus.loaded);
    } catch (e) {
      _data = _data.copyWith(
        status: PaginationStatus.error,
        error: e.toString(),
      );
    }

    notifyListeners();
  }

  /// Gérer le scroll pour charger automatiquement
  void onScroll(ScrollController scrollController) {
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;

    if (maxScroll - currentScroll <= loadMoreThreshold) {
      loadMore();
    }
  }
}

/// Widget de liste paginée
class InfinitePaginatedList<T> extends StatefulWidget {
  final PaginationController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separatorBuilder;
  final Widget? headerWidget;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final EdgeInsets? padding;
  final bool enableRefresh;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const InfinitePaginatedList({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separatorBuilder,
    this.headerWidget,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.padding,
    this.enableRefresh = true,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  State<InfinitePaginatedList<T>> createState() =>
      _InfinitePaginatedListState<T>();
}

class _InfinitePaginatedListState<T> extends State<InfinitePaginatedList<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Charger les données initiales
    if (widget.controller.data.status == PaginationStatus.initial) {
      widget.controller.loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    widget.controller.onScroll(_scrollController);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final data = widget.controller.data;

        // État initial de chargement
        if (data.status == PaginationStatus.initial ||
            (data.status == PaginationStatus.loading && data.items.isEmpty)) {
          return widget.loadingWidget ?? _buildDefaultLoading();
        }

        // État d'erreur sans données
        if (data.status == PaginationStatus.error && data.items.isEmpty) {
          return widget.errorWidget ?? _buildDefaultError(data.error);
        }

        // Liste vide
        if (data.items.isEmpty && data.status == PaginationStatus.loaded) {
          return widget.emptyWidget ?? _buildDefaultEmpty();
        }

        // Construire la liste
        Widget list = ListView.builder(
          controller: _scrollController,
          padding: widget.padding ?? const EdgeInsets.all(16),
          physics: widget.physics,
          scrollDirection: widget.scrollDirection,
          itemCount: _calculateItemCount(data),
          itemBuilder: (context, index) {
            // Header
            if (widget.headerWidget != null && index == 0) {
              return widget.headerWidget!;
            }

            final adjustedIndex = widget.headerWidget != null
                ? index - 1
                : index;

            // Items de données
            if (adjustedIndex < data.items.length) {
              final item = data.items[adjustedIndex];

              if (widget.separatorBuilder != null && adjustedIndex > 0) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.separatorBuilder!,
                    widget.itemBuilder(context, item, adjustedIndex),
                  ],
                );
              }

              return widget.itemBuilder(context, item, adjustedIndex);
            }

            // Indicateur de chargement en bas
            if (data.status == PaginationStatus.loadingMore) {
              return _buildLoadMoreIndicator();
            }

            // Plus de données
            if (data.status == PaginationStatus.noMoreData) {
              return _buildEndOfListIndicator();
            }

            return const SizedBox.shrink();
          },
        );

        // Ajouter pull-to-refresh si activé
        if (widget.enableRefresh) {
          list = RefreshIndicator(
            onRefresh: widget.controller.refresh,
            color: Theme.of(context).primaryColor,
            child: list,
          );
        }

        return list;
      },
    );
  }

  int _calculateItemCount(PaginatedData<T> data) {
    int count = data.items.length;

    if (widget.headerWidget != null) count++;

    // Ajouter un slot pour le loading indicator ou end indicator
    if (data.status == PaginationStatus.loadingMore ||
        data.status == PaginationStatus.noMoreData) {
      count++;
    }

    return count;
  }

  Widget _buildDefaultLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Chargement...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultError(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Une erreur s\'est produite',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.controller.loadInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun élément',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Il n\'y a pas encore de données à afficher',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEndOfListIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '— Fin de la liste —',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ),
    );
  }
}

/// Widget de grille paginée
class InfinitePaginatedGrid<T> extends StatefulWidget {
  final PaginationController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget? headerWidget;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsets? padding;
  final bool enableRefresh;

  const InfinitePaginatedGrid({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.headerWidget,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.enableRefresh = true,
  });

  @override
  State<InfinitePaginatedGrid<T>> createState() =>
      _InfinitePaginatedGridState<T>();
}

class _InfinitePaginatedGridState<T> extends State<InfinitePaginatedGrid<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.controller.data.status == PaginationStatus.initial) {
      widget.controller.loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    widget.controller.onScroll(_scrollController);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final data = widget.controller.data;

        if (data.status == PaginationStatus.initial ||
            (data.status == PaginationStatus.loading && data.items.isEmpty)) {
          return widget.loadingWidget ?? _buildGridLoading();
        }

        if (data.items.isEmpty && data.status == PaginationStatus.loaded) {
          return widget.emptyWidget ?? _buildEmptyGrid();
        }

        Widget grid = CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (widget.headerWidget != null)
              SliverToBoxAdapter(child: widget.headerWidget!),

            SliverPadding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < data.items.length) {
                    return widget.itemBuilder(
                      context,
                      data.items[index],
                      index,
                    );
                  }
                  return null;
                }, childCount: data.items.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.crossAxisCount,
                  mainAxisSpacing: widget.mainAxisSpacing,
                  crossAxisSpacing: widget.crossAxisSpacing,
                  childAspectRatio: widget.childAspectRatio,
                ),
              ),
            ),

            // Loading indicator
            if (data.status == PaginationStatus.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );

        if (widget.enableRefresh) {
          grid = RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: grid,
          );
        }

        return grid;
      },
    );
  }

  Widget _buildGridLoading() {
    return GridView.builder(
      padding: widget.padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildEmptyGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun élément à afficher',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
