import 'package:equatable/equatable.dart';

class PaymentTransaction extends Equatable {
  final String id;
  final String userId;
  final double montant;
  final String fournisseur;
  final String numeroTelephone;
  final String statut;
  final DateTime createdAt;
  final String? description;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.montant,
    required this.fournisseur,
    required this.numeroTelephone,
    required this.statut,
    required this.createdAt,
    this.description,
  });

  @override
  List<Object?> get props => [
    id, userId, montant, fournisseur, numeroTelephone, statut, createdAt, description
  ];
}
