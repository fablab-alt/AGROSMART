import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/messages/data/datasources/message_remote_datasource.dart';
import 'package:agriculture/features/messages/domain/entities/conversation.dart';
import 'package:agriculture/features/messages/domain/entities/message.dart';
import 'package:agriculture/features/messages/domain/repositories/message_repository.dart';
import 'package:dartz/dartz.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      final remoteConversations = await remoteDataSource.getConversations();
      return Right(remoteConversations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String userId) async {
    try {
      final remoteMessages = await remoteDataSource.getMessages(userId);
      return Right(remoteMessages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(String userId, String content) async {
    try {
      final message = await remoteDataSource.sendMessage(userId, content);
      return Right(message);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
