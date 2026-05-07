import 'package:equatable/equatable.dart';

class ForumTopic extends Equatable {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final String authorName;
  final String authorId;
  final String? authorAvatar;
  final AuthorBadge? authorBadge;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final int replyCount;
  final int viewCount;
  final int upvotes;
  final int downvotes;
  final bool isSolved;
  final bool isPinned;
  final bool isLocked;
  final bool isHot;
  final List<String> tags;
  final List<String> images;
  final ForumTopic? bestAnswer;

  const ForumTopic({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.authorName,
    required this.authorId,
    this.authorAvatar,
    this.authorBadge,
    required this.createdAt,
    this.lastActivityAt,
    required this.replyCount,
    this.viewCount = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isSolved = false,
    this.isPinned = false,
    this.isLocked = false,
    this.isHot = false,
    this.tags = const [],
    this.images = const [],
    this.bestAnswer,
  });

  /// Score de pertinence pour le tri
  int get score => upvotes - downvotes;

  /// Vérifie si le topic est populaire (plus de 10 réponses ou 50 vues)
  bool get isPopular => replyCount > 10 || viewCount > 50;

  ForumTopic copyWith({
    String? id,
    String? categoryId,
    String? title,
    String? content,
    String? authorName,
    String? authorId,
    String? authorAvatar,
    AuthorBadge? authorBadge,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    int? replyCount,
    int? viewCount,
    int? upvotes,
    int? downvotes,
    bool? isSolved,
    bool? isPinned,
    bool? isLocked,
    bool? isHot,
    List<String>? tags,
    List<String>? images,
    ForumTopic? bestAnswer,
  }) {
    return ForumTopic(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorBadge: authorBadge ?? this.authorBadge,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      replyCount: replyCount ?? this.replyCount,
      viewCount: viewCount ?? this.viewCount,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isSolved: isSolved ?? this.isSolved,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isHot: isHot ?? this.isHot,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      bestAnswer: bestAnswer ?? this.bestAnswer,
    );
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    title,
    content,
    authorName,
    authorId,
    authorAvatar,
    authorBadge,
    createdAt,
    lastActivityAt,
    replyCount,
    viewCount,
    upvotes,
    downvotes,
    isSolved,
    isPinned,
    isLocked,
    isHot,
    tags,
    images,
    bestAnswer,
  ];
}

/// Badge de l'auteur dans le forum
enum AuthorBadgeType {
  expert, // Utilisateur expert validé
  moderator, // Modérateur
  contributor, // Contributeur actif
  helpful, // Aide souvent les autres
  newMember, // Nouveau membre
  verified, // Compte vérifié
}

class AuthorBadge extends Equatable {
  final AuthorBadgeType type;
  final String label;
  final String? color;

  const AuthorBadge({required this.type, required this.label, this.color});

  factory AuthorBadge.expert() => const AuthorBadge(
    type: AuthorBadgeType.expert,
    label: 'Expert',
    color: '#FFD700',
  );

  factory AuthorBadge.moderator() => const AuthorBadge(
    type: AuthorBadgeType.moderator,
    label: 'Modérateur',
    color: '#FF5722',
  );

  factory AuthorBadge.contributor() => const AuthorBadge(
    type: AuthorBadgeType.contributor,
    label: 'Contributeur',
    color: '#2196F3',
  );

  factory AuthorBadge.helpful() => const AuthorBadge(
    type: AuthorBadgeType.helpful,
    label: 'Serviable',
    color: '#4CAF50',
  );

  factory AuthorBadge.newMember() => const AuthorBadge(
    type: AuthorBadgeType.newMember,
    label: 'Nouveau',
    color: '#9E9E9E',
  );

  @override
  List<Object?> get props => [type, label, color];
}
