import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend_model.dart';
import '../../domain/entities/friend.dart';

/// Datasource pour le système d'amitié (réseau social)
abstract class FriendshipsRemoteDataSource {
  Future<List<FriendModel>> getFriends();
  Future<List<FriendRequestModel>> getReceivedRequests();
  Future<List<FriendRequestModel>> getSentRequests();
  Future<List<FriendSuggestionModel>> getSuggestions();
  Future<FriendshipStatus> getStatus(String userId);
  Future<void> sendRequest(String addresseeId);
  Future<void> acceptRequest(String friendshipId);
  Future<void> rejectRequest(String friendshipId);
  Future<void> removeFriend(String friendshipId);
}

class FriendshipsRemoteDataSourceImpl implements FriendshipsRemoteDataSource {
  final Dio dio;
  FriendshipsRemoteDataSourceImpl({required this.dio});

  Future<Options> _opts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<List<FriendModel>> getFriends() async {
    final response = await dio.get('/friendships', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to load friends');
    final data = response.data['data'] as List? ?? [];
    return data.map((j) => FriendModel.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  @override
  Future<List<FriendRequestModel>> getReceivedRequests() async {
    final response = await dio.get('/friendships/requests/received', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to load received requests');
    final data = response.data['data'] as List? ?? [];
    return data.map((j) => FriendRequestModel.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  @override
  Future<List<FriendRequestModel>> getSentRequests() async {
    final response = await dio.get('/friendships/requests/sent', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to load sent requests');
    final data = response.data['data'] as List? ?? [];
    return data.map((j) => FriendRequestModel.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  @override
  Future<List<FriendSuggestionModel>> getSuggestions() async {
    final response = await dio.get('/friendships/suggestions', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to load suggestions');
    final data = response.data['data'] as List? ?? [];
    return data.map((j) => FriendSuggestionModel.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  @override
  Future<FriendshipStatus> getStatus(String userId) async {
    final response = await dio.get('/friendships/status/$userId', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to load status');
    final raw = response.data['data']?['status']?.toString();
    return FriendshipStatusX.fromString(raw);
  }

  @override
  Future<void> sendRequest(String addresseeId) async {
    final response = await dio.post(
      '/friendships',
      data: {'addresseeId': addresseeId},
      options: await _opts(),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'Failed to send request');
    }
  }

  @override
  Future<void> acceptRequest(String friendshipId) async {
    final response = await dio.patch('/friendships/$friendshipId/accept', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to accept');
  }

  @override
  Future<void> rejectRequest(String friendshipId) async {
    final response = await dio.patch('/friendships/$friendshipId/reject', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to reject');
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    final response = await dio.delete('/friendships/$friendshipId', options: await _opts());
    if (response.statusCode != 200) throw Exception('Failed to remove friend');
  }
}
