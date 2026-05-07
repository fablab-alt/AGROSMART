import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/features/messages/domain/entities/conversation.dart';
import 'package:agriculture/features/messages/domain/entities/message.dart';
import 'package:agriculture/features/messages/domain/repositories/message_repository.dart';

// Events
abstract class MessageEvent extends Equatable {
  const MessageEvent();
  @override
  List<Object> get props => [];
}

class LoadConversations extends MessageEvent {}

class LoadMessages extends MessageEvent {
  final String userId;
  const LoadMessages(this.userId);
  @override
  List<Object> get props => [userId];
}

class SendMessage extends MessageEvent {
  final String userId;
  final String content;
  const SendMessage({required this.userId, required this.content});
  @override
  List<Object> get props => [userId, content];
}

class RefreshMessages extends MessageEvent {
  final String userId;
  const RefreshMessages(this.userId);
}

// States
abstract class MessageState extends Equatable {
  const MessageState();
  @override
  List<Object> get props => [];
}

class MessageInitial extends MessageState {}

class ConversationsLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);
  @override
  List<Object> get props => [conversations];
}

class ChatLoading extends MessageState {}

class ChatLoaded extends MessageState {
  final List<Message> messages;
  const ChatLoaded(this.messages);
  @override
  List<Object> get props => [messages];
}

class MessageError extends MessageState {
  final String message;
  const MessageError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final MessageRepository repository;

  MessageBloc({required this.repository}) : super(MessageInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onLoadConversations(LoadConversations event, Emitter<MessageState> emit) async {
    emit(ConversationsLoading());
    final result = await repository.getConversations();
    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (conversations) => emit(ConversationsLoaded(conversations)),
    );
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<MessageState> emit) async {
    emit(ChatLoading());
    final result = await repository.getMessages(event.userId);
    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (messages) => emit(ChatLoaded(messages)),
    );
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<MessageState> emit) async {
    // Optimistic update could be implemented here, but for now simple request
    final result = await repository.sendMessage(event.userId, event.content);
    
    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (message) {
        // Ideally append to current state if valid, or reload
        add(LoadMessages(event.userId));
      },
    );
  }
}
