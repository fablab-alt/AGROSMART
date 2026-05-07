import 'package:equatable/equatable.dart';

/// Représente un article dans le panier
class CartItem extends Equatable {
  final String id;
  final String produitId;
  final String nom;
  final String? description;
  final double prix;
  final String unite;
  final int quantite;
  final int stockDisponible;
  final List<String>? images;
  final String? categorie;
  final String? vendeurNom;

  const CartItem({
    required this.id,
    required this.produitId,
    required this.nom,
    this.description,
    required this.prix,
    required this.unite,
    required this.quantite,
    required this.stockDisponible,
    this.images,
    this.categorie,
    this.vendeurNom,
  });

  /// Prix total pour cet article (prix * quantité)
  double get totalPrice => prix * quantite;

  /// Première image du produit
  String? get imageUrl => images?.isNotEmpty == true ? images!.first : null;

  /// Copie avec modifications
  CartItem copyWith({
    String? id,
    String? produitId,
    String? nom,
    String? description,
    double? prix,
    String? unite,
    int? quantite,
    int? stockDisponible,
    List<String>? images,
    String? categorie,
    String? vendeurNom,
  }) {
    return CartItem(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      unite: unite ?? this.unite,
      quantite: quantite ?? this.quantite,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      images: images ?? this.images,
      categorie: categorie ?? this.categorie,
      vendeurNom: vendeurNom ?? this.vendeurNom,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final produit = json['produit'] as Map<String, dynamic>?;
    final vendeur = produit?['vendeur'] as Map<String, dynamic>?;

    List<String>? images;
    if (produit?['images'] != null) {
      if (produit!['images'] is List) {
        images = (produit['images'] as List).map((e) => e.toString()).toList();
      }
    }

    return CartItem(
      id: json['id'] as String,
      produitId:
          json['produitId'] as String? ?? produit?['id'] as String? ?? '',
      nom: produit?['nom'] as String? ?? 'Produit',
      description: produit?['description'] as String?,
      prix:
          (produit?['prix'] is String
              ? double.tryParse(produit!['prix'])
              : (produit?['prix'] as num?)?.toDouble()) ??
          0.0,
      unite: produit?['unite'] as String? ?? 'unité',
      quantite: json['quantite'] as int? ?? 1,
      stockDisponible: produit?['stock'] as int? ?? 0,
      images: images,
      categorie: produit?['categorie'] as String?,
      vendeurNom: vendeur != null
          ? '${vendeur['prenoms'] ?? ''} ${vendeur['nom'] ?? ''}'.trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'produitId': produitId, 'quantite': quantite};
  }

  @override
  List<Object?> get props => [
    id,
    produitId,
    nom,
    description,
    prix,
    unite,
    quantite,
    stockDisponible,
    images,
    categorie,
    vendeurNom,
  ];
}

/// Représente le panier complet
class Cart extends Equatable {
  final String id;
  final List<CartItem> items;
  final int totalItems;
  final double totalPrice;

  const Cart({
    required this.id,
    required this.items,
    required this.totalItems,
    required this.totalPrice,
  });

  /// Panier vide
  factory Cart.empty() {
    return const Cart(id: '', items: [], totalItems: 0, totalPrice: 0.0);
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return Cart(
      id: json['id'] as String? ?? '',
      items: items,
      totalItems:
          json['totalItems'] as int? ??
          items.fold(0, (sum, item) => sum + item.quantite),
      totalPrice:
          (json['totalPrice'] is String
              ? double.tryParse(json['totalPrice'])
              : (json['totalPrice'] as num?)?.toDouble()) ??
          items.fold(0.0, (sum, item) => sum + item.totalPrice),
    );
  }

  @override
  List<Object?> get props => [id, items, totalItems, totalPrice];
}
