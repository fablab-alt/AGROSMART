import '../../domain/entities/friend.dart';
import '../../domain/repositories/friendships_repository.dart';
import '../datasources/friendships_remote_datasource.dart';

class FriendshipsRepositoryImpl implements FriendshipsRepository {
  final FriendshipsRemoteDataSource remote;
  FriendshipsRepositoryImpl({required this.remote});

  @override
  Future<List<Friend>> getFriends() => remote.getFriends();

  @override
  Future<List<FriendRequest>> getReceivedRequests() => remote.getReceivedRequests();

  @override
  Future<List<FriendRequest>> getSentRequests() => remote.getSentRequests();

  @override
  Future<List<FriendSuggestion>> getSuggestions() => remote.getSuggestions();

  @override
  Future<FriendshipStatus> getStatus(String userId) => remote.getStatus(userId);

  @override
  Future<void> sendRequest(String addresseeId) => remote.sendRequest(addresseeId);

  @override
  Future<void> acceptRequest(String friendshipId) => remote.acceptRequest(friendshipId);

  @override
  Future<void> rejectRequest(String friendshipId) => remote.rejectRequest(friendshipId);

  @override
  Future<void> removeFriend(String friendshipId) => remote.removeFriend(friendshipId);
}
