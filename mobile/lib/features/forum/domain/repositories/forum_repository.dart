import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/forum_category.dart';
import '../entities/forum_topic.dart';
import '../entities/forum_post.dart';

abstract class ForumRepository {
  Future<Either<Failure, List<ForumCategory>>> getCategories();
  Future<Either<Failure, List<ForumTopic>>> getTopics(String categoryId);
  Future<Either<Failure, List<ForumPost>>> getPosts(String topicId);
  Future<Either<Failure, ForumTopic>> createTopic(String categoryId, String title, String content, List<String> tags);
  Future<Either<Failure, ForumPost>> createPost(String topicId, String content);
  Future<Either<Failure, List<ForumTopic>>> searchTopics(String query);
}
