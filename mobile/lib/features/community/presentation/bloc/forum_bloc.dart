import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/features/community/data/repositories/forum_repository.dart';
import 'package:agriculture/features/community/domain/entities/forum_post.dart';

// Events
abstract class ForumEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPosts extends ForumEvent {
  final String? category;
  LoadPosts({this.category});
}

class LoadPostDetails extends ForumEvent {
  final String id;
  LoadPostDetails(this.id);
}

class CreateForumPost extends ForumEvent {
  final String titre;
  final String contenu;
  final String categorie;
  final List<String> tags;

  CreateForumPost({
    required this.titre,
    required this.contenu,
    required this.categorie,
    required this.tags,
  });
}

class CreateReply extends ForumEvent {
  final String postId;
  final String content;

  CreateReply({required this.postId, required this.content});
}

// States
abstract class ForumState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumLoaded extends ForumState {
  final List<ForumPost> posts;
  ForumLoaded(this.posts);
  @override
  List<Object?> get props => [posts];
}

class ForumPostDetailLoaded extends ForumState {
  final ForumPost post;
  ForumPostDetailLoaded(this.post);
  @override
  List<Object?> get props => [post];
}

class ForumError extends ForumState {
  final String message;
  ForumError(this.message);
  @override
  List<Object?> get props => [message];
}

class ForumActionSuccess extends ForumState {
  final String message;
  ForumActionSuccess(this.message);
}

// Bloc
class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final ForumRepository repository;

  ForumBloc({required this.repository}) : super(ForumInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<LoadPostDetails>(_onLoadPostDetails);
    on<CreateForumPost>(_onCreatePost);
    on<CreateReply>(_onCreateReply);
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    try {
      final posts = await repository.getPosts(category: event.category);
      emit(ForumLoaded(posts));
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }

  Future<void> _onLoadPostDetails(LoadPostDetails event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    try {
      final post = await repository.getPostDetails(event.id);
      emit(ForumPostDetailLoaded(post));
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }

  Future<void> _onCreatePost(CreateForumPost event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    try {
      await repository.createPost(event.titre, event.contenu, event.categorie, event.tags);
      emit(ForumActionSuccess('Post créé avec succès'));
      add(LoadPosts()); // Refresh list
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }

  Future<void> _onCreateReply(CreateReply event, Emitter<ForumState> emit) async {
    // Don't emit loading here to keep UI responsive, or handle carefully
    try {
      await repository.createReply(event.postId, event.content);
      emit(ForumActionSuccess('Réponse ajoutée'));
      add(LoadPostDetails(event.postId)); // Refresh details
    } catch (e) {
      emit(ForumError(e.toString()));
    }
  }
}
