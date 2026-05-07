import 'package:agriculture/features/messages/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.nom,
    super.avatar,
    required super.dernierMessage,
    required super.dateMessage,
    required super.nonLus,
    super.isOnline,
    super.isGroup,
    super.isSupport,
    super.role,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Determine isSupport based on role if available
    final role = json['contact_role'] as String?;
    final isSupport = role == 'conseiller' || role == 'admin';

    return ConversationModel(
      id: json['contact_id'], // Using contact_id as conversation identifier for now
      nom: '${json['contact_nom']} ${json['contact_prenom'] ?? ''}'.trim(),
      avatar: json['avatar'], // null for now
      dernierMessage: json['dernier_message'] ?? '',
      dateMessage: DateTime.parse(json['dernier_message_date'] ?? DateTime.now().toIso8601String()),
      nonLus: int.tryParse(json['non_lus'].toString()) ?? 0,
      isGroup: false, // Backend currently only supports P2P
      isSupport: isSupport,
      role: role,
      // isOnline: json['is_online'] ?? false, // Not available from backend yet
    );
  }
}
