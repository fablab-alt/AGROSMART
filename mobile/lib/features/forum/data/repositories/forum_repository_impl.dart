import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/forum_category.dart';
import '../../domain/entities/forum_topic.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/repositories/forum_repository.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ApiClient _apiClient = di.sl<ApiClient>();

  // Catégories statiques (pas d'API backend pour les catégories)
  final List<ForumCategory> _categories = const [
    ForumCategory(
      id: 'cultures',
      name: 'Cultures',
      description: 'Discussions sur le cacao, maïs, anacarde...',
      iconName: 'local_florist',
      topicCount: 0,
    ),
    ForumCategory(
      id: 'maladies',
      name: 'Maladies & Ravageurs',
      description: 'Identifier et traiter les problèmes',
      iconName: 'bug_report',
      topicCount: 0,
    ),
    ForumCategory(
      id: 'equipements',
      name: 'Équipements',
      description: 'Avis sur le matériel agricole',
      iconName: 'handyman',
      topicCount: 0,
    ),
    ForumCategory(
      id: 'marche',
      name: 'Marché & Prix',
      description: 'Tendances et prix bord champ',
      iconName: 'trending_up',
      topicCount: 0,
    ),
    ForumCategory(
      id: 'entraide',
      name: 'Entraide Générale',
      description: 'Questions diverses',
      iconName: 'people',
      topicCount: 0,
    ),
  ];

  @override
  Future<Either<Failure, List<ForumCategory>>> getCategories() async {
    try {
      // Get stats from API to update topic counts
      final response = await _apiClient.get('/communaute/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // For now return base categories - could update counts from stats
        return Right(_categories);
      }
      return Right(_categories);
    } catch (e) {
      // Return categories even if API fails
      return Right(_categories);
    }
  }

  @override
  Future<Either<Failure, List<ForumTopic>>> getTopics(String categoryId) async {
    try {
      final response = await _apiClient.get(
        '/communaute/posts',
        queryParameters: {'categorie': categoryId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final postsData = response.data['data'] as List<dynamic>;
        final topics = postsData.map((json) => _topicFromJson(json)).toList();
        return Right(topics);
      }
      return Left(ServerFailure('Erreur lors du chargement des discussions'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ForumPost>>> getPosts(String topicId) async {
    try {
      final response = await _apiClient.get('/communaute/posts/$topicId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final reponses = data['reponses'] as List<dynamic>? ?? [];
        final posts = reponses.map((json) => _postFromJson(json)).toList();
        return Right(posts);
      }
      return Left(ServerFailure('Erreur lors du chargement des réponses'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ForumTopic>> createTopic(
    String categoryId,
    String title,
    String content,
    List<String> tags,
  ) async {
    try {
      final response = await _apiClient.post(
        '/communaute/posts',
        data: {
          'titre': title,
          'contenu': content,
          'categorie': categoryId,
          'tags': tags,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final postData = response.data['data'];
        return Right(_topicFromJson(postData));
      }
      return Left(ServerFailure('Erreur lors de la création du sujet'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ForumPost>> createPost(
    String topicId,
    String content,
  ) async {
    try {
      final response = await _apiClient.post(
        '/communaute/posts/$topicId/reponses',
        data: {'contenu': content},
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final postData = response.data['data'];
        return Right(_postFromJson(postData));
      }
      return Left(ServerFailure('Erreur lors de l\'envoi de la réponse'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ForumTopic>>> searchTopics(String query) async {
    try {
      final response = await _apiClient.get(
        '/communaute/posts',
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final postsData = response.data['data'] as List<dynamic>;
        final topics = postsData.map((json) => _topicFromJson(json)).toList();
        return Right(topics);
      }
      return Left(ServerFailure('Erreur lors de la recherche'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erreur réseau'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Helper methods to convert API JSON to entities
  ForumTopic _topicFromJson(Map<String, dynamic> json) {
    return ForumTopic(
      id: json['id'] ?? '',
      categoryId: json['categorie'] ?? 'entraide',
      title: json['titre'] ?? '',
      content: json['contenu'] ?? '',
      authorName: '${json['auteur_prenom'] ?? ''} ${json['auteur_nom'] ?? ''}'
          .trim(),
      authorId: json['auteurId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      replyCount: json['reponses_count'] ?? json['_count']?['reponses'] ?? 0,
      isSolved: json['resolu'] ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      viewCount: json['vues'] ?? 0,
    );
  }

  ForumPost _postFromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] ?? '',
      topicId: json['postId'] ?? '',
      content: json['contenu'] ?? '',
      authorName: '${json['auteur_prenom'] ?? ''} ${json['auteur_nom'] ?? ''}'
          .trim(),
      authorId: json['auteurId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isSolution: json['estSolution'] ?? false,
    );
  }
}
