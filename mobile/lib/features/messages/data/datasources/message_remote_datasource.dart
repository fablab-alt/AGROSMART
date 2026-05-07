import 'package:dio/dio.dart';
import 'package:agriculture/features/messages/data/models/conversation_model.dart';
import 'package:agriculture/features/messages/data/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class MessageRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(String userId);
  Future<MessageModel> sendMessage(String userId, String content);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final Dio dio;

  MessageRemoteDataSourceImpl({required this.dio});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/messages/conversations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ConversationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String userId) async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/messages/conversations/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MessageModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage(String userId, String content) async {
    final token = await _getToken();
    try {
      final response = await dio.post(
        '/messages',
        data: {'destinataire_id': userId, 'contenu': content, 'type': 'texte'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return MessageModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
