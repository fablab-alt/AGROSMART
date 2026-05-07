import 'package:equatable/equatable.dart';

/// Chat conversation
class Conversation extends Equatable {
  final String id;
  final String type; // 'prive', 'groupe', 'support'
  final String? nom;
  final String? description;
  final String? avatarUrl;
  final List<String> participants;
  final String adminId;
  final DateTime? dernierMessageAt;
  final int nbMessages;
  final bool estActif;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.type,
    this.nom,
    this.description,
    this.avatarUrl,
    required this.participants,
    required this.adminId,
    this.dernierMessageAt,
    this.nbMessages = 0,
    this.estActif = true,
    this.unreadCount = 0,
  });

  bool get isPrivate => type == 'prive';
  bool get isGroup => type == 'groupe';

  @override
  List<Object?> get props => [
        id,
        type,
        nom,
        description,
        avatarUrl,
        participants,
        adminId,
        dernierMessageAt,
        nbMessages,
        estActif,
        unreadCount,
      ];
}

/// Chat message
class Message extends Equatable {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String? destinataireId;
  final String message;
  final bool lu;
  final DateTime? luAt;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    this.destinataireId,
    required this.message,
    this.lu = false,
    this.luAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        expediteurId,
        destinataireId,
        message,
        lu,
        luAt,
        createdAt,
      ];
}

/// Gamification entities
class UserPoints extends Equatable {
  final String id;
  final String userId;
  final int pointsTotal;
  final int niveau;
  final int actionsCompletees;
  final int joursConsecutifs;
  final DateTime? derniereActivite;

  const UserPoints({
    required this.id,
    required this.userId,
    this.pointsTotal = 0,
    this.niveau = 1,
    this.actionsCompletees = 0,
    this.joursConsecutifs = 0,
    this.derniereActivite,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        pointsTotal,
        niveau,
        actionsCompletees,
        joursConsecutifs,
        derniereActivite,
      ];
}

class Badge extends Equatable {
  final String id;
  final String nom;
  final String description;
  final String? iconeUrl;
  final String type;
  final String rarete;
  final int? conditionPoints;
  final DateTime? dateObtention;

  const Badge({
    required this.id,
    required this.nom,
    required this.description,
    this.iconeUrl,
    required this.type,
    this.rarete = 'commun',
    this.conditionPoints,
    this.dateObtention,
  });

  @override
  List<Object?> get props => [
        id,
        nom,
        description,
        iconeUrl,
        type,
        rarete,
        conditionPoints,
        dateObtention,
      ];
}

/// Payment transaction
class PaymentTransaction extends Equatable {
  final String id;
  final String userId;
  final String? commandeId;
  final String? locationId;
  final String? achatGroupeId;
  final double montant;
  final String fournisseur; // 'orange_money', 'mtn_money', 'moov_money'
  final String numeroTelephone;
  final String? transactionExterneId;
  final String statut;
  final String? messageStatut;
  final String? description;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    this.commandeId,
    this.locationId,
    this.achatGroupeId,
    required this.montant,
    required this.fournisseur,
    required this.numeroTelephone,
    this.transactionExterneId,
    required this.statut,
    this.messageStatut,
    this.description,
    required this.createdAt,
  });

  bool get isSuccess => statut == 'reussie';
  bool get isPending => statut == 'en_attente' || statut == 'en_cours';
  bool get isFailed => statut == 'echouee';

  @override
  List<Object?> get props => [
        id,
        userId,
        commandeId,
        locationId,
        achatGroupeId,
        montant,
        fournisseur,
        numeroTelephone,
        transactionExterneId,
        statut,
        messageStatut,
        description,
        createdAt,
      ];
}

/// Group purchase
class GroupPurchase extends Equatable {
  final String id;
  final String organisateurId;
  final String produitType;
  final String description;
  final String categorie;
  final int quantiteObjectif;
  final int quantiteActuelle;
  final String unite;
  final double prixUnitaire;
  final double prixGroupe;
  final double economiePourcentage;
  final DateTime dateLimite;
  final String? localisationLivraison;
  final String statut;

  const GroupPurchase({
    required this.id,
    required this.organisateurId,
    required this.produitType,
    required this.description,
    required this.categorie,
    required this.quantiteObjectif,
    this.quantiteActuelle = 0,
    required this.unite,
    required this.prixUnitaire,
    required this.prixGroupe,
    required this.economiePourcentage,
    required this.dateLimite,
    this.localisationLivraison,
    required this.statut,
  });

  double get progressPercentage => (quantiteActuelle / quantiteObjectif * 100).clamp(0, 100);
  bool get isObjectiveReached => quantiteActuelle >= quantiteObjectif;
  bool get isOpen => statut == 'ouvert';

  @override
  List<Object?> get props => [
        id,
        organisateurId,
        produitType,
        description,
        categorie,
        quantiteObjectif,
        quantiteActuelle,
        unite,
        prixUnitaire,
        prixGroupe,
        economiePourcentage,
        dateLimite,
        localisationLivraison,
        statut,
      ];
}
