import '../../domain/entities/friend.dart';

/// Modèle JSON ↔ entity pour Friend
class FriendModel extends Friend {
  const FriendModel({
    required super.friendshipId,
    required super.id,
    required super.nom,
    required super.prenoms,
    required super.telephone,
    super.email,
    required super.role,
    super.photoProfil,
    super.niveau,
    super.points,
    super.badge,
    super.regionNom,
    super.amisDepuis,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final region = json['region'];
    return FriendModel(
      friendshipId: json['friendshipId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenoms: json['prenoms']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'PRODUCTEUR',
      photoProfil: json['photoProfil']?.toString(),
      niveau: json['niveau']?.toString(),
      points: json['points'] is int ? json['points'] as int : null,
      badge: json['badge']?.toString(),
      regionNom: region is Map ? region['nom']?.toString() : null,
      amisDepuis: json['amisDepuis'] != null
          ? DateTime.tryParse(json['amisDepuis'].toString())
          : null,
    );
  }
}

class FriendRequestModel extends FriendRequest {
  const FriendRequestModel({
    required super.id,
    super.from,
    super.to,
    required super.sentAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    Friend? parseUser(dynamic raw, {String? fsid}) {
      if (raw is! Map) return null;
      final r = raw as Map<String, dynamic>;
      return Friend(
        friendshipId: fsid ?? '',
        id: r['id']?.toString() ?? '',
        nom: r['nom']?.toString() ?? '',
        prenoms: r['prenoms']?.toString() ?? '',
        telephone: r['telephone']?.toString() ?? '',
        email: r['email']?.toString(),
        role: r['role']?.toString() ?? 'PRODUCTEUR',
        photoProfil: r['photoProfil']?.toString(),
        niveau: r['niveau']?.toString(),
        points: r['points'] is int ? r['points'] as int : null,
        regionNom: r['region'] is Map ? (r['region'] as Map)['nom']?.toString() : null,
      );
    }

    return FriendRequestModel(
      id: json['id']?.toString() ?? '',
      from: parseUser(json['from'], fsid: json['id']?.toString()),
      to: parseUser(json['to'], fsid: json['id']?.toString()),
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class FriendSuggestionModel extends FriendSuggestion {
  const FriendSuggestionModel({
    required super.id,
    required super.nom,
    required super.prenoms,
    super.email,
    required super.role,
    super.photoProfil,
    super.niveau,
    super.points,
    super.regionNom,
  });

  factory FriendSuggestionModel.fromJson(Map<String, dynamic> json) {
    return FriendSuggestionModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenoms: json['prenoms']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'PRODUCTEUR',
      photoProfil: json['photoProfil']?.toString(),
      niveau: json['niveau']?.toString(),
      points: json['points'] is int ? json['points'] as int : null,
      regionNom: json['region'] is Map ? (json['region'] as Map)['nom']?.toString() : null,
    );
  }
}
