import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/favorite.dart';

// ============================================
// EVENTS
// ============================================

abstract class FavoritesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Charger les favoris de l'utilisateur
class LoadFavorites extends FavoritesEvent {}

/// Ajouter un produit aux favoris
class AddToFavorites extends FavoritesEvent {
  final String produitId;
  final String? productName;

  AddToFavorites({required this.produitId, this.productName});

  @override
  List<Object?> get props => [produitId, productName];
}

/// Retirer un produit des favoris
class RemoveFromFavorites extends FavoritesEvent {
  final String produitId;

  RemoveFromFavorites({required this.produitId});

  @override
  List<Object> get props => [produitId];
}

/// Vérifier si un produit est en favoris
class CheckIsFavorite extends FavoritesEvent {
  final String produitId;

  CheckIsFavorite({required this.produitId});

  @override
  List<Object> get props => [produitId];
}

/// Toggle un produit dans les favoris
class ToggleFavorite extends FavoritesEvent {
  final String produitId;
  final String? productName;

  ToggleFavorite({required this.produitId, this.productName});

  @override
  List<Object?> get props => [produitId, productName];
}

// ============================================
// STATES
// ============================================

abstract class FavoritesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<FavoriteItem> favorites;
  final Set<String> favoriteIds; // Pour vérification rapide

  FavoritesLoaded({required this.favorites, Set<String>? favoriteIds})
    : favoriteIds = favoriteIds ?? favorites.map((f) => f.produitId).toSet();

  bool isFavorite(String produitId) => favoriteIds.contains(produitId);

  int get count => favorites.length;

  FavoritesLoaded copyWith({
    List<FavoriteItem>? favorites,
    Set<String>? favoriteIds,
  }) {
    return FavoritesLoaded(
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object> get props => [favorites, favoriteIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  FavoritesError({required this.message});

  @override
  List<Object> get props => [message];
}

/// State temporaire après ajout/suppression réussi
class FavoriteToggled extends FavoritesState {
  final String produitId;
  final bool isNowFavorite;
  final String? productName;

  FavoriteToggled({
    required this.produitId,
    required this.isNowFavorite,
    this.productName,
  });

  @override
  List<Object?> get props => [produitId, isNowFavorite, productName];
}

// ============================================
// BLOC
// ============================================

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final ApiClient _apiClient = sl<ApiClient>();

  // Cache local des favoris
  List<FavoriteItem> _cachedFavorites = [];
  Set<String> _cachedFavoriteIds = {};

  FavoritesBloc() : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<CheckIsFavorite>(_onCheckIsFavorite);
  }

  bool isFavorite(String produitId) => _cachedFavoriteIds.contains(produitId);

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());

    try {
      final response = await _apiClient.get('/favorites');
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> items = data['data'] ?? [];
        _cachedFavorites = items
            .map((json) => FavoriteItem.fromJson(json))
            .toList();
        _cachedFavoriteIds = _cachedFavorites.map((f) => f.produitId).toSet();

        emit(
          FavoritesLoaded(
            favorites: _cachedFavorites,
            favoriteIds: _cachedFavoriteIds,
          ),
        );
      } else {
        emit(
          FavoritesError(
            message: data['error'] ?? 'Erreur lors du chargement des favoris',
          ),
        );
      }
    } catch (e) {
      // Si erreur d'auth, retourner liste vide
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        emit(FavoritesLoaded(favorites: [], favoriteIds: {}));
      } else {
        emit(FavoritesError(message: 'Erreur de connexion'));
      }
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final response = await _apiClient.post(
        '/favorites',
        data: {'produitId': event.produitId},
      );
      final data = response.data;

      if (data['success'] == true) {
        _cachedFavoriteIds.add(event.produitId);

        emit(
          FavoriteToggled(
            produitId: event.produitId,
            isNowFavorite: true,
            productName: event.productName,
          ),
        );

        // Recharger la liste complète
        add(LoadFavorites());
      } else {
        emit(
          FavoritesError(
            message: data['error'] ?? 'Impossible d\'ajouter aux favoris',
          ),
        );
        // Restaurer l'état précédent
        emit(
          FavoritesLoaded(
            favorites: _cachedFavorites,
            favoriteIds: _cachedFavoriteIds,
          ),
        );
      }
    } catch (e) {
      emit(FavoritesError(message: 'Erreur de connexion'));
      emit(
        FavoritesLoaded(
          favorites: _cachedFavorites,
          favoriteIds: _cachedFavoriteIds,
        ),
      );
    }
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final response = await _apiClient.delete('/favorites/${event.produitId}');
      final data = response.data;

      if (data['success'] == true) {
        _cachedFavoriteIds.remove(event.produitId);
        _cachedFavorites.removeWhere((f) => f.produitId == event.produitId);

        emit(FavoriteToggled(produitId: event.produitId, isNowFavorite: false));

        emit(
          FavoritesLoaded(
            favorites: _cachedFavorites,
            favoriteIds: _cachedFavoriteIds,
          ),
        );
      } else {
        emit(
          FavoritesError(
            message: data['error'] ?? 'Impossible de retirer des favoris',
          ),
        );
        emit(
          FavoritesLoaded(
            favorites: _cachedFavorites,
            favoriteIds: _cachedFavoriteIds,
          ),
        );
      }
    } catch (e) {
      emit(FavoritesError(message: 'Erreur de connexion'));
      emit(
        FavoritesLoaded(
          favorites: _cachedFavorites,
          favoriteIds: _cachedFavoriteIds,
        ),
      );
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    if (_cachedFavoriteIds.contains(event.produitId)) {
      add(RemoveFromFavorites(produitId: event.produitId));
    } else {
      add(
        AddToFavorites(
          produitId: event.produitId,
          productName: event.productName,
        ),
      );
    }
  }

  Future<void> _onCheckIsFavorite(
    CheckIsFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    // Si on n'a pas encore chargé les favoris, les charger
    if (state is FavoritesInitial) {
      add(LoadFavorites());
    }
  }
}
