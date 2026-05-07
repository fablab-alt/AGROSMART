import 'package:agriculture/features/messages/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.texte,
    required super.envoyeurId,
    required super.date,
    super.type,
    super.mediaUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      texte: json['contenu'] ?? '',
      envoyeurId: json['user_id'],
      date: DateTime.parse(json['created_at']),
      type: json['type'] ?? 'texte',
      mediaUrl: json['media_url'],
    );
  }
}
