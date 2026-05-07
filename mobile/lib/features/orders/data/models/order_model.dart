import 'package:agriculture/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.produitNom,
    required super.produitId,
    required super.prixTotal,
    required super.quantite,
    required super.vendeurNom,
    required super.vendeurId,
    required super.acheteurId,
    required super.statut,
    required super.date,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      produitNom: json['produit_nom'] ?? 'Produit inconnu',
      produitId: json['produit_id']?.toString() ?? '',
      prixTotal: double.tryParse(json['prix_total']?.toString() ?? '0') ?? 0.0,
      quantite: int.tryParse(json['quantite']?.toString() ?? '1') ?? 1,
      vendeurNom: json['vendeur_nom'] ?? 'Vendeur inconnu',
      vendeurId: json['vendeur_id']?.toString() ?? '',
      acheteurId: json['acheteur_id']?.toString() ?? '',
      statut: json['statut'] ?? 'En attente',
      date: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
