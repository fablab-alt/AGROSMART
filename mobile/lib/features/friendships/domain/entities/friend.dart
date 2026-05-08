/// Entité Friend — un ami confirmé
class Friend {
  final String friendshipId;
  final String id;
  final String nom;
  final String prenoms;
  final String telephone;
  final String? email;
  final String role;
  final String? photoProfil;
  final String? niveau;
  final int? points;
  final String? badge;
  final String? regionNom;
  final DateTime? amisDepuis;

  const Friend({
    required this.friendshipId,
    required this.id,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    this.email,
    required this.role,
    this.photoProfil,
    this.niveau,
    this.points,
    this.badge,
    this.regionNom,
    this.amisDepuis,
  });

  String get nomComplet => '$prenoms $nom';
  String get initiales {
    final p = prenoms.isNotEmpty ? prenoms[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}

/// Demande d'amitié reçue ou envoyée
class FriendRequest {
  final String id;
  final Friend? from;
  final Friend? to;
  final DateTime sentAt;

  const FriendRequest({
    required this.id,
    this.from,
    this.to,
    required this.sentAt,
  });

  bool get isReceived => from != null;
  bool get isSent => to != null;
}

/// Suggestion d'utilisateur à ajouter en ami
class FriendSuggestion {
  final String id;
  final String nom;
  final String prenoms;
  final String? email;
  final String role;
  final String? photoProfil;
  final String? niveau;
  final int? points;
  final String? regionNom;

  const FriendSuggestion({
    required this.id,
    required this.nom,
    required this.prenoms,
    this.email,
    required this.role,
    this.photoProfil,
    this.niveau,
    this.points,
    this.regionNom,
  });

  String get nomComplet => '$prenoms $nom';
  String get initiales {
    final p = prenoms.isNotEmpty ? prenoms[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}

/// Statut d'amitié entre deux utilisateurs
enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  accepted,
  rejected,
  blocked,
  self,
}

extension FriendshipStatusX on FriendshipStatus {
  static FriendshipStatus fromString(String? value) {
    switch (value) {
      case 'NONE': return FriendshipStatus.none;
      case 'PENDING_SENT': return FriendshipStatus.pendingSent;
      case 'PENDING_RECEIVED': return FriendshipStatus.pendingReceived;
      case 'ACCEPTED': return FriendshipStatus.accepted;
      case 'REJECTED': return FriendshipStatus.rejected;
      case 'BLOCKED': return FriendshipStatus.blocked;
      case 'SELF': return FriendshipStatus.self;
      default: return FriendshipStatus.none;
    }
  }
}
