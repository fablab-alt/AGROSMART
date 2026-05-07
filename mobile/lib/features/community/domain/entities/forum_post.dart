class ForumPost {
  final String id;
  final String titre;
  final String contenu;
  final String categorie;
  final List<String> tags;
  final String auteurNom;
  final String? auteurPhoto;
  final int vues;
  final int reponsesCount;
  final DateTime createdAt;
  final bool resolu;
  final List<ForumReponse> reponses;

  ForumPost({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.categorie,
    required this.tags,
    required this.auteurNom,
    this.auteurPhoto,
    required this.vues,
    required this.reponsesCount,
    required this.createdAt,
    this.resolu = false,
    this.reponses = const [],
  });
}

class ForumReponse {
  final String id;
  final String contenu;
  final String auteurNom;
  final String? auteurPhoto;
  final DateTime createdAt;
  final bool estSolution;

  ForumReponse({
    required this.id,
    required this.contenu,
    required this.auteurNom,
    this.auteurPhoto,
    required this.createdAt,
    this.estSolution = false,
  });
}
