import 'package:agriculture/features/formations/domain/entities/formation.dart';

class FormationModel extends Formation {
  const FormationModel({
    required super.id,
    required super.titre,
    required super.description,
    required super.type,
    required super.categorie,
    super.url,
    required super.dureeMinutes,
    super.langue,
    super.imageUrl,
    super.progression,
    super.isComplete,
    required super.createdAt,
  });

  factory FormationModel.fromJson(Map<String, dynamic> json) {
    return FormationModel(
      id: json['id'] ?? '',
      titre: json['titre'] ?? 'Sans titre',
      description: json['description'] ?? '',
      type: json['type'] ?? 'inconnu',
      categorie: json['categorie'] ?? 'Autre',
      url: json['url'] ?? '',
      dureeMinutes: json['duree_minutes'] ?? 0,
      langue: json['langue'] ?? 'fr',
      // imageUrl: json['image_url'], // Add when backend supports it
      progression: json['progression'] != null ? (json['progression'] as num).toInt() : 0,
      isComplete: json['complete'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
