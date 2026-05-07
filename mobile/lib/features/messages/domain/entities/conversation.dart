import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id; // contact_id
  final String nom; // contact_nom + contact_prenom
  final String? avatar;
  final String dernierMessage;
  final DateTime dateMessage;
  final int nonLus;
  final bool isOnline;
  final bool isGroup;
  final bool isSupport;
  final String? role; // e.g., 'conseiller', 'producteur'

  const Conversation({
    required this.id,
    required this.nom,
    this.avatar,
    required this.dernierMessage,
    required this.dateMessage,
    required this.nonLus,
    this.isOnline = false,
    this.isGroup = false,
    this.isSupport = false,
    this.role,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        avatar,
        dernierMessage,
        dateMessage,
        nonLus,
        isOnline,
        isGroup,
        isSupport,
        role,
      ];
}
