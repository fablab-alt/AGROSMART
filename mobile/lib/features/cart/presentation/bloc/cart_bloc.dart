import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../injection_container.dart';

// ============================================
// EVENTS
// ============================================

abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final String produitId;
  final int quantite;
  // Informations du produit pour le panier local
  final String? productName;
  final double? productPrice;
  final String? productUnit;
  final int? productStock;
  final List<String>? productImages;
  final String? productCategory;
  final String? vendeurNom;

  AddToCart({
    required this.produitId,
    this.quantite = 1,
    this.productName,
    this.productPrice,
    this.productUnit,
    this.productStock,
    this.productImages,
    this.productCategory,
    this.vendeurNom,
  });

  @override
  List<Object?> get props => [
    produitId,
    quantite,
    productName,
    productPrice,
    productUnit,
    productStock,
    productImages,
    productCategory,
    vendeurNom,
  ];
}

class UpdateCartItemQuantity extends CartEvent {
  final String itemId;
  final int quantite;

  UpdateCartItemQuantity({required this.itemId, required this.quantite});

  @override
  List<Object> get props => [itemId, quantite];
}

class RemoveFromCart extends CartEvent {
  final String itemId;

  RemoveFromCart({required this.itemId});

  @override
  List<Object> get props => [itemId];
}

class ClearCart extends CartEvent {}

class CheckoutCart extends CartEvent {
  final String adresseLivraison;
  final String methodePaiement;
  final String? numeroTelephone;
  final String? instructions;
  final DateTime? dateLivraisonProgrammee;

  CheckoutCart({
    required this.adresseLivraison,
    required this.methodePaiement,
    this.numeroTelephone,
    this.instructions,
    this.dateLivraisonProgrammee,
  });

  @override
  List<Object?> get props => [
    adresseLivraison,
    methodePaiement,
    numeroTelephone,
    instructions,
    dateLivraisonProgrammee,
  ];
}

/// Event pour ajouter au panier local (sans authentification)
class AddToLocalCart extends CartEvent {
  final CartItem item;

  AddToLocalCart({required this.item});

  @override
  List<Object> get props => [item];
}

/// Event pour synchroniser le panier local avec le serveur après connexion
class SyncLocalCart extends CartEvent {}

// ============================================
// STATES
// ============================================

abstract class CartState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final Cart cart;
  final bool isLocal; // true si panier local (non authentifié)

  CartLoaded({required this.cart, this.isLocal = false});

  int get totalItems => cart.totalItems;
  double get totalPrice => cart.totalPrice;
  List<CartItem> get items => cart.items;
  bool get isEmpty => cart.items.isEmpty;

  @override
  List<Object> get props => [cart, isLocal];
}

class CartError extends CartState {
  final String message;

  CartError({required this.message});

  @override
  List<Object> get props => [message];
}

class CartItemAdded extends CartState {
  final String productName;

  CartItemAdded({required this.productName});

  @override
  List<Object> get props => [productName];
}

class CartProcessing extends CartState {}

class OrderCreated extends CartState {
  final String orderId;

  OrderCreated({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

// ============================================
// BLOC
// ============================================

class CartBloc extends Bloc<CartEvent, CartState> {
  final ApiClient _apiClient = sl<ApiClient>();
  final SecureStorageService _secureStorage = sl<SecureStorageService>();

  // Panier local pour les utilisateurs non authentifiés
  Cart _localCart = Cart.empty();

  CartBloc() : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<CheckoutCart>(_onCheckoutCart);
    on<AddToLocalCart>(_onAddToLocalCart);
    on<SyncLocalCart>(_onSyncLocalCart);
  }

  /// Vérifie si l'utilisateur est authentifié en regardant le token
  Future<bool> _isAuthenticated() async {
    final token = await _secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading());

    try {
      // Vérifier si l'utilisateur est authentifié
      final isAuthenticated = await _isAuthenticated();

      if (!isAuthenticated) {
        // Retourner le panier local
        emit(CartLoaded(cart: _localCart, isLocal: true));
        return;
      }

      final response = await _apiClient.get('/cart');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final cart = Cart.fromJson(response.data['data']);
        emit(CartLoaded(cart: cart));
      } else {
        emit(CartLoaded(cart: Cart.empty()));
      }
    } catch (e) {
      // En cas d'erreur, afficher le panier local
      emit(CartLoaded(cart: _localCart, isLocal: true));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      final isAuthenticated = await _isAuthenticated();

      if (!isAuthenticated) {
        // Ajouter au panier local pour les utilisateurs non connectés
        final newItem = CartItem(
          id: 'local_${event.produitId}_${DateTime.now().millisecondsSinceEpoch}',
          produitId: event.produitId,
          nom: event.productName ?? 'Produit',
          prix: event.productPrice ?? 0.0,
          unite: event.productUnit ?? 'unité',
          quantite: event.quantite,
          stockDisponible: event.productStock ?? 100,
          images: event.productImages,
          categorie: event.productCategory,
          vendeurNom: event.vendeurNom,
        );

        // Vérifier si le produit existe déjà dans le panier local
        final existingIndex = _localCart.items.indexWhere(
          (item) => item.produitId == event.produitId,
        );

        List<CartItem> updatedItems;
        if (existingIndex >= 0) {
          // Mettre à jour la quantité
          updatedItems = List.from(_localCart.items);
          final existing = updatedItems[existingIndex];
          updatedItems[existingIndex] = existing.copyWith(
            quantite: existing.quantite + event.quantite,
          );
        } else {
          // Ajouter le nouvel article
          updatedItems = [..._localCart.items, newItem];
        }

        _localCart = Cart(
          id: 'local',
          items: updatedItems,
          totalItems: updatedItems.fold(0, (sum, item) => sum + item.quantite),
          totalPrice: updatedItems.fold(
            0.0,
            (sum, item) => sum + item.totalPrice,
          ),
        );

        emit(CartItemAdded(productName: event.productName ?? 'Produit'));
        emit(CartLoaded(cart: _localCart, isLocal: true));
        return;
      }

      final response = await _apiClient.post(
        '/cart/items',
        data: {'produitId': event.produitId, 'quantite': event.quantite},
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        emit(CartItemAdded(productName: event.productName ?? 'Produit'));
        // Recharger le panier
        add(LoadCart());
      } else {
        emit(
          CartError(
            message:
                response.data['error'] ?? 'Erreur lors de l\'ajout au panier',
          ),
        );
      }
    } catch (e) {
      emit(CartError(message: 'Erreur de connexion'));
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    try {
      if (currentState.isLocal) {
        // Mise à jour locale
        final updatedItems = currentState.items.map((item) {
          if (item.id == event.itemId) {
            return item.copyWith(quantite: event.quantite);
          }
          return item;
        }).toList();

        _localCart = Cart(
          id: _localCart.id,
          items: updatedItems,
          totalItems: updatedItems.fold(0, (sum, item) => sum + item.quantite),
          totalPrice: updatedItems.fold(
            0.0,
            (sum, item) => sum + item.totalPrice,
          ),
        );

        emit(CartLoaded(cart: _localCart, isLocal: true));
        return;
      }

      final response = await _apiClient.put(
        '/cart/items/${event.itemId}',
        data: {'quantite': event.quantite},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        add(LoadCart());
      } else {
        emit(
          CartError(
            message: response.data['error'] ?? 'Erreur lors de la mise à jour',
          ),
        );
      }
    } catch (e) {
      emit(CartError(message: 'Erreur de connexion'));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    try {
      if (currentState.isLocal) {
        // Suppression locale
        final updatedItems = currentState.items
            .where((item) => item.id != event.itemId)
            .toList();

        _localCart = Cart(
          id: _localCart.id,
          items: updatedItems,
          totalItems: updatedItems.fold(0, (sum, item) => sum + item.quantite),
          totalPrice: updatedItems.fold(
            0.0,
            (sum, item) => sum + item.totalPrice,
          ),
        );

        emit(CartLoaded(cart: _localCart, isLocal: true));
        return;
      }

      final response = await _apiClient.delete('/cart/items/${event.itemId}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        add(LoadCart());
      } else {
        emit(
          CartError(
            message: response.data['error'] ?? 'Erreur lors de la suppression',
          ),
        );
      }
    } catch (e) {
      emit(CartError(message: 'Erreur de connexion'));
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    try {
      if (currentState.isLocal) {
        _localCart = Cart.empty();
        emit(CartLoaded(cart: _localCart, isLocal: true));
        return;
      }

      final response = await _apiClient.delete('/cart');

      if (response.statusCode == 200 && response.data['success'] == true) {
        emit(CartLoaded(cart: Cart.empty()));
      } else {
        emit(CartError(message: 'Erreur lors du vidage du panier'));
      }
    } catch (e) {
      emit(CartError(message: 'Erreur de connexion'));
    }
  }

  void _onAddToLocalCart(AddToLocalCart event, Emitter<CartState> emit) {
    // Vérifier si le produit existe déjà
    final existingIndex = _localCart.items.indexWhere(
      (item) => item.produitId == event.item.produitId,
    );

    List<CartItem> updatedItems;

    if (existingIndex >= 0) {
      // Mettre à jour la quantité
      updatedItems = List.from(_localCart.items);
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantite: existing.quantite + event.item.quantite,
      );
    } else {
      // Ajouter le nouvel article
      updatedItems = [..._localCart.items, event.item];
    }

    _localCart = Cart(
      id: 'local',
      items: updatedItems,
      totalItems: updatedItems.fold(0, (sum, item) => sum + item.quantite),
      totalPrice: updatedItems.fold(0.0, (sum, item) => sum + item.totalPrice),
    );

    emit(CartLoaded(cart: _localCart, isLocal: true));
  }

  Future<void> _onSyncLocalCart(
    SyncLocalCart event,
    Emitter<CartState> emit,
  ) async {
    if (_localCart.items.isEmpty) {
      add(LoadCart());
      return;
    }

    emit(CartLoading());

    try {
      // Ajouter chaque article local au panier serveur
      for (final item in _localCart.items) {
        await _apiClient.post(
          '/cart/items',
          data: {'produitId': item.produitId, 'quantite': item.quantite},
        );
      }

      // Vider le panier local
      _localCart = Cart.empty();

      // Recharger le panier depuis le serveur
      add(LoadCart());
    } catch (e) {
      emit(CartError(message: 'Erreur lors de la synchronisation'));
    }
  }

  Future<void> _onCheckoutCart(
    CheckoutCart event,
    Emitter<CartState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CartLoaded) return;

    emit(CartProcessing());

    try {
      final orderData = {
        'adresseLivraison': event.adresseLivraison,
        'methodePaiement': event.methodePaiement,
        if (event.numeroTelephone != null)
          'numeroTelephone': event.numeroTelephone,
        if (event.instructions != null) 'instructions': event.instructions,
        if (event.dateLivraisonProgrammee != null)
          'dateLivraisonProgrammee': event.dateLivraisonProgrammee!
              .toIso8601String(),
      };

      final response = await _apiClient.post('/orders', data: orderData);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final orderId = response.data['data']['id'];

        // Vider le panier
        if (currentState.isLocal) {
          _localCart = Cart.empty();
        }

        emit(OrderCreated(orderId: orderId));
        // Recharger le panier vide
        add(LoadCart());
      } else {
        emit(
          CartError(
            message:
                response.data['error'] ??
                'Erreur lors de la création de la commande',
          ),
        );
        emit(currentState); // Revenir à l'état précédent
      }
    } catch (e) {
      emit(CartError(message: 'Erreur de connexion: $e'));
      emit(currentState); // Revenir à l'état précédent
    }
  }
}
