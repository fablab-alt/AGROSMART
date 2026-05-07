import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String texte;
  final String envoyeurId; // or 'me'/'other' logic in UI? Better keep raw ID.
  final DateTime date;
  final String type; // 'texte', 'image', etc.
  final String? mediaUrl;

  const Message({
    required this.id,
    required this.texte,
    required this.envoyeurId,
    required this.date,
    this.type = 'texte',
    this.mediaUrl,
  });

  @override
  List<Object?> get props => [id, texte, envoyeurId, date, type, mediaUrl];
}
