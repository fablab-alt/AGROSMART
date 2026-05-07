import 'package:agriculture/features/community/domain/entities/forum_post.dart';

class ForumPostModel extends ForumPost {
  ForumPostModel({
    required super.id,
    required super.titre,
    required super.contenu,
    required super.categorie,
    required super.tags,
    required super.auteurNom,
    super.auteurPhoto,
    required super.vues,
    required super.reponsesCount,
    required super.createdAt,
    super.resolu,
    super.reponses,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      categorie: json['categorie'],
      tags: List<String>.from(json['tags'] ?? []),
      auteurNom: "${json['auteur_nom'] ?? ''} ${json['auteur_prenom'] ?? ''}".trim(),
      auteurPhoto: json['auteur_photo'],
      vues: json['vues'] ?? 0,
      reponsesCount: json['reponses_count'] != null ? int.parse(json['reponses_count'].toString()) : 0,
      createdAt: DateTime.parse(json['created_at']),
      resolu: json['resolu'] ?? false,
      reponses: (json['reponses'] as List<dynamic>?)
              ?.map((e) => ForumReponseModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ForumReponseModel extends ForumReponse {
  ForumReponseModel({
    required super.id,
    required super.contenu,
    required super.auteurNom,
    super.auteurPhoto,
    required super.createdAt,
    super.estSolution,
  });

  factory ForumReponseModel.fromJson(Map<String, dynamic> json) {
    return ForumReponseModel(
      id: json['id'],
      contenu: json['contenu'],
      auteurNom: "${json['auteur_nom'] ?? ''} ${json['auteur_prenom'] ?? ''}".trim(),
      auteurPhoto: json['auteur_photo'],
      createdAt: DateTime.parse(json['created_at']),
      estSolution: json['est_solution'] ?? false,
    );
  }
}
