import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String produitNom;
  final String produitId;
  final double prixTotal;
  final int quantite;
  final String vendeurNom;
  final String vendeurId;
  final String acheteurId;
  final String statut;
  final DateTime date;

  const Order({
    required this.id,
    required this.produitNom,
    required this.produitId,
    required this.prixTotal,
    required this.quantite,
    required this.vendeurNom,
    required this.vendeurId,
    required this.acheteurId,
    required this.statut,
    required this.date,
  });

  @override
  List<Object?> get props => [id, produitNom, prixTotal, statut, date];
}
