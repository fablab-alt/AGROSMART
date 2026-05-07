import 'package:agriculture/features/community/data/datasources/forum_remote_data_source.dart';
import 'package:agriculture/features/community/domain/entities/forum_post.dart';

class ForumRepository {
  final ForumRemoteDataSource remoteDataSource;

  ForumRepository({required this.remoteDataSource});

  Future<List<ForumPost>> getPosts({String? category}) async {
    return await remoteDataSource.getPosts(category: category);
  }

  Future<ForumPost> getPostDetails(String id) async {
    return await remoteDataSource.getPostDetails(id);
  }

  Future<ForumPost> createPost(String titre, String contenu, String categorie, List<String> tags) async {
    return await remoteDataSource.createPost({
      'titre': titre,
      'contenu': contenu,
      'categorie': categorie,
      'tags': tags,
    });
  }

  Future<ForumReponse> createReply(String postId, String content) async {
    return await remoteDataSource.createReply(postId, content);
  }
}
