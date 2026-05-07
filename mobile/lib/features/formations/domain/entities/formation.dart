import 'package:equatable/equatable.dart';

class Formation extends Equatable {
  final String id;
  final String titre;
  final String description;
  final String type;
  final String categorie;
  final String? url;
  final int dureeMinutes;
  final String? langue;
  final String? imageUrl;
  final int? progression;
  final bool isComplete;
  final DateTime createdAt;

  const Formation({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    required this.categorie,
    this.url,
    required this.dureeMinutes,
    this.langue,
    this.imageUrl,
    this.progression,
    this.isComplete = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        titre,
        description,
        type,
        categorie,
        url,
        dureeMinutes,
        langue,
        imageUrl,
        progression,
        isComplete,
        createdAt,
      ];

  bool get isNew => DateTime.now().difference(createdAt).inDays < 30;
}
