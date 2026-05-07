import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/forum_category.dart';
import '../../domain/entities/forum_topic.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

// Events
abstract class ForumEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadForumCategories extends ForumEvent {}

class LoadForumTopics extends ForumEvent {
  final String categoryId;
  LoadForumTopics(this.categoryId);
  @override
  List<Object> get props => [categoryId];
}

class LoadForumPosts extends ForumEvent {
  final String topicId;
  LoadForumPosts(this.topicId);
  @override
  List<Object> get props => [topicId];
}

class CreateForumTopic extends ForumEvent {
  final String categoryId;
  final String title;
  final String content;
  final List<String> tags;
  CreateForumTopic({required this.categoryId, required this.title, required this.content, this.tags = const []});
  @override
  List<Object> get props => [categoryId, title, content, tags];
}

class CreateForumPost extends ForumEvent {
  final String topicId;
  final String content;
  CreateForumPost({required this.topicId, required this.content});
  @override
  List<Object> get props => [topicId, content];
}

// States
abstract class ForumState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ForumInitial extends ForumState {}
class ForumLoading extends ForumState {}

class ForumCategoriesLoaded extends ForumState {
  final List<ForumCategory> categories;
  ForumCategoriesLoaded(this.categories);
  @override
  List<Object> get props => [categories];
}

class ForumTopicsLoaded extends ForumState {
  final List<ForumTopic> topics;
  final String categoryId;
  ForumTopicsLoaded(this.topics, this.categoryId);
  @override
  List<Object> get props => [topics, categoryId];
}

class ForumPostsLoaded extends ForumState {
  final List<ForumPost> posts;
  final String topicId;
  ForumPostsLoaded(this.posts, this.topicId);
  @override
  List<Object> get props => [posts, topicId];
}

class ForumOperationSuccess extends ForumState {
  final String message;
  ForumOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ForumError extends ForumState {
  final String message;
  ForumError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final ForumRepository repository;

  ForumBloc({required this.repository}) : super(ForumInitial()) {
    on<LoadForumCategories>(_onLoadCategories);
    on<LoadForumTopics>(_onLoadTopics);
    on<LoadForumPosts>(_onLoadPosts);
    on<CreateForumTopic>(_onCreateTopic);
    on<CreateForumPost>(_onCreatePost);
  }

  Future<void> _onLoadCategories(LoadForumCategories event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.getCategories();
    result.fold(
      (failure) => emit(ForumError(failure.message)),
      (categories) => emit(ForumCategoriesLoaded(categories)),
    );
  }

  Future<void> _onLoadTopics(LoadForumTopics event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.getTopics(event.categoryId);
    result.fold(
      (failure) => emit(ForumError(failure.message)),
      (topics) => emit(ForumTopicsLoaded(topics, event.categoryId)),
    );
  }

  Future<void> _onLoadPosts(LoadForumPosts event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.getPosts(event.topicId);
    result.fold(
      (failure) => emit(ForumError(failure.message)),
      (posts) => emit(ForumPostsLoaded(posts, event.topicId)),
    );
  }

  Future<void> _onCreateTopic(CreateForumTopic event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.createTopic(event.categoryId, event.title, event.content, event.tags);
    result.fold(
      (failure) => emit(ForumError(failure.message)),
      (_) => emit(ForumOperationSuccess("Sujet créé avec succès")),
    );
  }

  Future<void> _onCreatePost(CreateForumPost event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.createPost(event.topicId, event.content);
    result.fold(
      (failure) => emit(ForumError(failure.message)),
      (_) {
        emit(ForumOperationSuccess("Réponse ajoutée"));
        add(LoadForumPosts(event.topicId)); // Reload posts
      },
    );
  }
}
