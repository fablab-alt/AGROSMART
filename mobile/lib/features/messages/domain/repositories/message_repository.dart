import 'package:agriculture/core/error/failures.dart';
import 'package:agriculture/features/messages/domain/entities/conversation.dart';
import 'package:agriculture/features/messages/domain/entities/message.dart';
import 'package:dartz/dartz.dart';

abstract class MessageRepository {
  Future<Either<Failure, List<Conversation>>> getConversations();
  Future<Either<Failure, List<Message>>> getMessages(String userId);
  Future<Either<Failure, Message>> sendMessage(String userId, String content);
}
