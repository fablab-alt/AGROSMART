import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friendships_repository.dart';

// ─── EVENTS ────────────────────────────────────────────────────────────────
abstract class FriendshipsEvent extends Equatable {
  const FriendshipsEvent();
  @override
  List<Object?> get props => [];
}

class LoadFriendships extends FriendshipsEvent {}

class SendFriendRequest extends FriendshipsEvent {
  final String userId;
  const SendFriendRequest(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AcceptFriendRequest extends FriendshipsEvent {
  final String friendshipId;
  const AcceptFriendRequest(this.friendshipId);
  @override
  List<Object?> get props => [friendshipId];
}

class RejectFriendRequest extends FriendshipsEvent {
  final String friendshipId;
  const RejectFriendRequest(this.friendshipId);
  @override
  List<Object?> get props => [friendshipId];
}

class RemoveFriend extends FriendshipsEvent {
  final String friendshipId;
  const RemoveFriend(this.friendshipId);
  @override
  List<Object?> get props => [friendshipId];
}

// ─── STATES ────────────────────────────────────────────────────────────────
abstract class FriendshipsState extends Equatable {
  const FriendshipsState();
  @override
  List<Object?> get props => [];
}

class FriendshipsInitial extends FriendshipsState {}

class FriendshipsLoading extends FriendshipsState {}

class FriendshipsLoaded extends FriendshipsState {
  final List<Friend> friends;
  final List<FriendRequest> received;
  final List<FriendRequest> sent;
  final List<FriendSuggestion> suggestions;

  const FriendshipsLoaded({
    required this.friends,
    required this.received,
    required this.sent,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [friends, received, sent, suggestions];
}

class FriendshipsError extends FriendshipsState {
  final String message;
  const FriendshipsError(this.message);
  @override
  List<Object?> get props => [message];
}

class FriendshipActionSuccess extends FriendshipsState {
  final String message;
  const FriendshipActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLOC ──────────────────────────────────────────────────────────────────
class FriendshipsBloc extends Bloc<FriendshipsEvent, FriendshipsState> {
  final FriendshipsRepository repository;

  FriendshipsBloc({required this.repository}) : super(FriendshipsInitial()) {
    on<LoadFriendships>(_onLoad);
    on<SendFriendRequest>(_onSend);
    on<AcceptFriendRequest>(_onAccept);
    on<RejectFriendRequest>(_onReject);
    on<RemoveFriend>(_onRemove);
  }

  Future<void> _onLoad(LoadFriendships event, Emitter<FriendshipsState> emit) async {
    emit(FriendshipsLoading());
    try {
      final results = await Future.wait([
        repository.getFriends(),
        repository.getReceivedRequests(),
        repository.getSentRequests(),
        repository.getSuggestions(),
      ]);
      emit(FriendshipsLoaded(
        friends: results[0] as List<Friend>,
        received: results[1] as List<FriendRequest>,
        sent: results[2] as List<FriendRequest>,
        suggestions: results[3] as List<FriendSuggestion>,
      ));
    } catch (e) {
      emit(FriendshipsError(e.toString()));
    }
  }

  Future<void> _onSend(SendFriendRequest event, Emitter<FriendshipsState> emit) async {
    try {
      await repository.sendRequest(event.userId);
      add(LoadFriendships());
    } catch (e) {
      emit(FriendshipsError('Erreur envoi demande : $e'));
    }
  }

  Future<void> _onAccept(AcceptFriendRequest event, Emitter<FriendshipsState> emit) async {
    try {
      await repository.acceptRequest(event.friendshipId);
      add(LoadFriendships());
    } catch (e) {
      emit(FriendshipsError('Erreur acceptation : $e'));
    }
  }

  Future<void> _onReject(RejectFriendRequest event, Emitter<FriendshipsState> emit) async {
    try {
      await repository.rejectRequest(event.friendshipId);
      add(LoadFriendships());
    } catch (e) {
      emit(FriendshipsError('Erreur refus : $e'));
    }
  }

  Future<void> _onRemove(RemoveFriend event, Emitter<FriendshipsState> emit) async {
    try {
      await repository.removeFriend(event.friendshipId);
      add(LoadFriendships());
    } catch (e) {
      emit(FriendshipsError('Erreur suppression : $e'));
    }
  }
}
