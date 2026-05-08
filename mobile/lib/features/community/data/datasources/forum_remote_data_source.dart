import 'package:dio/dio.dart';
import 'package:agriculture/features/community/data/models/forum_post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumPostModel>> getPosts({String? category});
  Future<ForumPostModel> getPostDetails(String id);
  Future<ForumPostModel> createPost(Map<String, dynamic> data);
  Future<ForumReponseModel> createReply(String postId, String content);
  // Édition / suppression (auteur ou admin)
  Future<void> updatePost(String id, Map<String, dynamic> data);
  Future<void> deletePost(String id);
  Future<void> updateReply(String postId, String reponseId, String content);
  Future<void> deleteReply(String postId, String reponseId);
  // Likes & upvotes (toggle)
  Future<Map<String, dynamic>> toggleLikePost(String postId);
  Future<Map<String, dynamic>> toggleUpvoteReply(String postId, String reponseId);
  // Marquer comme solution
  Future<void> markSolution(String postId, String reponseId);
  // Catégories
  Future<List<Map<String, dynamic>>> getCategories();
}

class ForumRemoteDataSourceImpl implements ForumRemoteDataSource {
  final Dio dio;

  ForumRemoteDataSourceImpl({required this.dio});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<List<ForumPostModel>> getPosts({String? category}) async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/communaute/posts',
        queryParameters: category != null ? {'categorie': category} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ForumPostModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<ForumPostModel> getPostDetails(String id) async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/communaute/posts/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return ForumPostModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load post details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<ForumPostModel> createPost(Map<String, dynamic> data) async {
    final token = await _getToken();
    try {
      final response = await dio.post(
        '/communaute/posts',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return ForumPostModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<ForumReponseModel> createReply(String postId, String content) async {
    final token = await _getToken();
    try {
      final response = await dio.post(
        '/communaute/posts/$postId/reponses',
        data: {'contenu': content},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return ForumReponseModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await dio.put(
      '/communaute/posts/$id',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update post');
  }

  @override
  Future<void> deletePost(String id) async {
    final token = await _getToken();
    final response = await dio.delete(
      '/communaute/posts/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete post');
  }

  @override
  Future<void> updateReply(String postId, String reponseId, String content) async {
    final token = await _getToken();
    final response = await dio.put(
      '/communaute/posts/$postId/reponses/$reponseId',
      data: {'contenu': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update reply');
  }

  @override
  Future<void> deleteReply(String postId, String reponseId) async {
    final token = await _getToken();
    final response = await dio.delete(
      '/communaute/posts/$postId/reponses/$reponseId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to delete reply');
  }

  @override
  Future<Map<String, dynamic>> toggleLikePost(String postId) async {
    final token = await _getToken();
    final response = await dio.post(
      '/communaute/posts/$postId/like',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to toggle like');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  @override
  Future<Map<String, dynamic>> toggleUpvoteReply(String postId, String reponseId) async {
    final token = await _getToken();
    final response = await dio.post(
      '/communaute/posts/$postId/reponses/$reponseId/upvote',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to toggle upvote');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  @override
  Future<void> markSolution(String postId, String reponseId) async {
    final token = await _getToken();
    final response = await dio.put(
      '/communaute/posts/$postId/reponses/$reponseId/solution',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to mark solution');
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final token = await _getToken();
    final response = await dio.get(
      '/communaute/categories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) throw Exception('Failed to load categories');
    return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
  }
}
