import 'package:dio/dio.dart';
import 'package:agriculture/features/community/data/models/forum_post_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumPostModel>> getPosts({String? category});
  Future<ForumPostModel> getPostDetails(String id);
  Future<ForumPostModel> createPost(Map<String, dynamic> data);
  Future<ForumReponseModel> createReply(String postId, String content);
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
}
