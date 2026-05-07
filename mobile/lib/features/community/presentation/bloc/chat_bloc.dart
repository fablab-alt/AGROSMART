import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/core/network/api_client.dart';
import '../../domain/entities/chat_gamification.dart';

// Events
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final String conversationId;
  LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String content;
  SendMessage(this.conversationId, this.content);

  @override
  List<Object?> get props => [conversationId, content];
}

class CreateConversation extends ChatEvent {
  final String type; // 'prive', 'groupe'
  final List<String> participants;
  final String? nom;

  CreateConversation({
    required this.type,
    required this.participants,
    this.nom,
  });

  @override
  List<Object?> get props => [type, participants, nom];
}

// States
abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;
  final String conversationId;

  MessagesLoaded(this.messages, this.conversationId);

  @override
  List<Object?> get props => [messages, conversationId];
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiClient _apiClient;

  ChatBloc({required ApiClient apiClient})
    : _apiClient = apiClient,
      super(ChatInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<CreateConversation>(_onCreateConversation);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final response = await _apiClient.get('/messages/conversations');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final conversations = data
            .map(
              (json) => Conversation(
                id: json['id'] ?? '',
                type: json['type'] ?? 'prive',
                nom: json['nom'],
                participants:
                    (json['participants'] as List?)
                        ?.map((p) => p.toString())
                        .toList() ??
                    [],
                adminId: json['adminId'] ?? '',
                dernierMessageAt: json['dernierMessageAt'] != null
                    ? DateTime.parse(json['dernierMessageAt'])
                    : DateTime.now(),
                nbMessages: json['nbMessages'] ?? 0,
                unreadCount: json['unreadCount'] ?? 0,
              ),
            )
            .toList();
        emit(ConversationsLoaded(conversations));
      } else {
        emit(ChatError(response.data['message'] ?? 'Erreur de chargement'));
      }
    } catch (e) {
      // Fallback avec données vides si erreur API
      emit(ConversationsLoaded([]));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final response = await _apiClient.get(
        '/messages/conversations/${event.conversationId}/messages',
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final messages = data
            .map(
              (json) => Message(
                id: json['id'] ?? '',
                conversationId: event.conversationId,
                expediteurId: json['expediteurId'] ?? '',
                message: json['contenu'] ?? json['message'] ?? '',
                createdAt: json['createdAt'] != null
                    ? DateTime.parse(json['createdAt'])
                    : DateTime.now(),
                lu: json['lu'] ?? false,
              ),
            )
            .toList();
        emit(MessagesLoaded(messages, event.conversationId));
      } else {
        emit(ChatError(response.data['message'] ?? 'Erreur de chargement'));
      }
    } catch (e) {
      emit(MessagesLoaded([], event.conversationId));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _apiClient.post(
        '/messages/conversations/${event.conversationId}/messages',
        data: {'contenu': event.content},
      );

      if (response.data['success'] == true && state is MessagesLoaded) {
        final currentMessages = (state as MessagesLoaded).messages;
        final messageData = response.data['data'];
        final newMessage = Message(
          id:
              messageData?['id'] ??
              'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: event.conversationId,
          expediteurId: messageData?['expediteurId'] ?? 'current_user',
          message: event.content,
          createdAt: DateTime.now(),
        );

        emit(
          MessagesLoaded([
            newMessage,
            ...currentMessages,
          ], event.conversationId),
        );
      }
    } catch (e) {
      // Optimistic update en cas d'erreur
      if (state is MessagesLoaded) {
        final currentMessages = (state as MessagesLoaded).messages;
        final newMessage = Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: event.conversationId,
          expediteurId: 'current_user',
          message: event.content,
          createdAt: DateTime.now(),
        );
        emit(
          MessagesLoaded([
            newMessage,
            ...currentMessages,
          ], event.conversationId),
        );
      }
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final response = await _apiClient.post(
        '/messages/conversations',
        data: {
          'type': event.type,
          'participants': event.participants,
          'nom': event.nom,
        },
      );

      if (response.data['success'] == true) {
        // Recharger les conversations
        add(LoadConversations());
      } else {
        emit(ChatError(response.data['message'] ?? 'Erreur de création'));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}
