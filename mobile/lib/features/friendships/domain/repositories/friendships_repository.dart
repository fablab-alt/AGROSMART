import '../entities/friend.dart';

abstract class FriendshipsRepository {
  Future<List<Friend>> getFriends();
  Future<List<FriendRequest>> getReceivedRequests();
  Future<List<FriendRequest>> getSentRequests();
  Future<List<FriendSuggestion>> getSuggestions();
  Future<FriendshipStatus> getStatus(String userId);
  Future<void> sendRequest(String addresseeId);
  Future<void> acceptRequest(String friendshipId);
  Future<void> rejectRequest(String friendshipId);
  Future<void> removeFriend(String friendshipId);
}
