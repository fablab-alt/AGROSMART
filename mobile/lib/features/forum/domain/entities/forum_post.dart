import 'package:equatable/equatable.dart';
import 'forum_topic.dart';

class ForumPost extends Equatable {
  final String id;
  final String topicId;
  final String content;
  final String authorName;
  final String authorId;
  final String? authorAvatar;
  final AuthorBadge? authorBadge;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isSolution;
  final int upvotes;
  final int downvotes;
  final String? replyToId;
  final String? replyToAuthor;
  final List<String> images;
  final List<PostReaction> reactions;
  final bool isEdited;
  final bool isDeleted;

  const ForumPost({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorName,
    required this.authorId,
    this.authorAvatar,
    this.authorBadge,
    required this.createdAt,
    this.editedAt,
    this.isSolution = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.replyToId,
    this.replyToAuthor,
    this.images = const [],
    this.reactions = const [],
    this.isEdited = false,
    this.isDeleted = false,
  });

  /// Score du post
  int get score => upvotes - downvotes;

  ForumPost copyWith({
    String? id,
    String? topicId,
    String? content,
    String? authorName,
    String? authorId,
    String? authorAvatar,
    AuthorBadge? authorBadge,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isSolution,
    int? upvotes,
    int? downvotes,
    String? replyToId,
    String? replyToAuthor,
    List<String>? images,
    List<PostReaction>? reactions,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return ForumPost(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorBadge: authorBadge ?? this.authorBadge,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isSolution: isSolution ?? this.isSolution,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      replyToId: replyToId ?? this.replyToId,
      replyToAuthor: replyToAuthor ?? this.replyToAuthor,
      images: images ?? this.images,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    topicId,
    content,
    authorName,
    authorId,
    authorAvatar,
    authorBadge,
    createdAt,
    editedAt,
    isSolution,
    upvotes,
    downvotes,
    replyToId,
    replyToAuthor,
    images,
    reactions,
    isEdited,
    isDeleted,
  ];
}

/// Réaction à un post
class PostReaction extends Equatable {
  final String emoji;
  final int count;
  final bool hasReacted;

  const PostReaction({
    required this.emoji,
    required this.count,
    this.hasReacted = false,
  });

  @override
  List<Object?> get props => [emoji, count, hasReacted];
}

/// Types de signalement
enum ReportReason { spam, offensive, offTopic, misinformation, other }

/// Signalement d'un post
class PostReport extends Equatable {
  final String id;
  final String postId;
  final String reporterId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;

  const PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    postId,
    reporterId,
    reason,
    description,
    createdAt,
  ];
}
