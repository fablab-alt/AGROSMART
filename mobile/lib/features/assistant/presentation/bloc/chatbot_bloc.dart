import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agriculture/core/services/agri_chatbot_service.dart';

// Events
abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();

  @override
  List<Object?> get props => [];
}

class ChatbotInitialized extends ChatbotEvent {
  const ChatbotInitialized();
}

class ChatbotLanguageChanged extends ChatbotEvent {
  final LocalLanguage language;

  const ChatbotLanguageChanged(this.language);

  @override
  List<Object?> get props => [language];
}

class ChatbotMessageSent extends ChatbotEvent {
  final String message;

  const ChatbotMessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatbotVoiceStarted extends ChatbotEvent {
  const ChatbotVoiceStarted();
}

class ChatbotVoiceStopped extends ChatbotEvent {
  const ChatbotVoiceStopped();
}

class ChatbotVoiceResultReceived extends ChatbotEvent {
  final String transcript;

  const ChatbotVoiceResultReceived(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

class ChatbotSpeakMessage extends ChatbotEvent {
  final ChatMessage message;

  const ChatbotSpeakMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatbotStopSpeaking extends ChatbotEvent {
  const ChatbotStopSpeaking();
}

class ChatbotHistoryCleared extends ChatbotEvent {
  const ChatbotHistoryCleared();
}

class ChatbotQuickActionTapped extends ChatbotEvent {
  final String action;

  const ChatbotQuickActionTapped(this.action);

  @override
  List<Object?> get props => [action];
}

// States
abstract class ChatbotState extends Equatable {
  final LocalLanguage currentLanguage;
  final List<ChatMessage> messages;
  final bool isListening;
  final bool isSpeaking;
  final String? currentTranscript;

  const ChatbotState({
    this.currentLanguage = LocalLanguage.francais,
    this.messages = const [],
    this.isListening = false,
    this.isSpeaking = false,
    this.currentTranscript,
  });

  @override
  List<Object?> get props => [
    currentLanguage,
    messages,
    isListening,
    isSpeaking,
    currentTranscript,
  ];
}

class ChatbotInitial extends ChatbotState {
  const ChatbotInitial() : super();
}

class ChatbotReady extends ChatbotState {
  const ChatbotReady({
    required super.currentLanguage,
    required super.messages,
    super.isListening,
    super.isSpeaking,
    super.currentTranscript,
  });

  ChatbotReady copyWith({
    LocalLanguage? currentLanguage,
    List<ChatMessage>? messages,
    bool? isListening,
    bool? isSpeaking,
    String? currentTranscript,
  }) {
    return ChatbotReady(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      currentTranscript: currentTranscript,
    );
  }
}

class ChatbotProcessing extends ChatbotState {
  const ChatbotProcessing({
    required super.currentLanguage,
    required super.messages,
  });
}

class ChatbotError extends ChatbotState {
  final String errorMessage;

  const ChatbotError({
    required this.errorMessage,
    required super.currentLanguage,
    required super.messages,
  });

  @override
  List<Object?> get props => [...super.props, errorMessage];
}

// Bloc
class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final AgriChatbotService _chatbotService;

  ChatbotBloc({required AgriChatbotService chatbotService})
    : _chatbotService = chatbotService,
      super(const ChatbotInitial()) {
    on<ChatbotInitialized>(_onInitialized);
    on<ChatbotLanguageChanged>(_onLanguageChanged);
    on<ChatbotMessageSent>(_onMessageSent);
    on<ChatbotVoiceStarted>(_onVoiceStarted);
    on<ChatbotVoiceStopped>(_onVoiceStopped);
    on<ChatbotVoiceResultReceived>(_onVoiceResultReceived);
    on<ChatbotSpeakMessage>(_onSpeakMessage);
    on<ChatbotStopSpeaking>(_onStopSpeaking);
    on<ChatbotHistoryCleared>(_onHistoryCleared);
    on<ChatbotQuickActionTapped>(_onQuickActionTapped);
  }

  Future<void> _onInitialized(
    ChatbotInitialized event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotService.initSpeechRecognition();

    // Ajouter le message de bienvenue
    final greeting = _chatbotService.currentLanguage.greeting;
    final welcomeMessage = ChatMessage(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
      language: _chatbotService.currentLanguage,
    );

    emit(
      ChatbotReady(
        currentLanguage: _chatbotService.currentLanguage,
        messages: [welcomeMessage],
      ),
    );
  }

  Future<void> _onLanguageChanged(
    ChatbotLanguageChanged event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotService.setLanguage(event.language);

    final currentState = state;
    if (currentState is ChatbotReady) {
      // Ajouter un message de changement de langue
      final langChangeMsg = ChatMessage(
        text: event.language.greeting,
        isUser: false,
        timestamp: DateTime.now(),
        language: event.language,
      );

      emit(
        currentState.copyWith(
          currentLanguage: event.language,
          messages: [...currentState.messages, langChangeMsg],
        ),
      );
    }
  }

  Future<void> _onMessageSent(
    ChatbotMessageSent event,
    Emitter<ChatbotState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatbotReady) return;

    emit(
      ChatbotProcessing(
        currentLanguage: currentState.currentLanguage,
        messages: currentState.messages,
      ),
    );

    try {
      final response = await _chatbotService.sendMessage(event.message);

      emit(
        ChatbotReady(
          currentLanguage: _chatbotService.currentLanguage,
          messages: List.from(_chatbotService.conversationHistory),
        ),
      );

      // Auto-lecture de la réponse
      await _chatbotService.speak(response.text, audioUrl: response.audioUrl);
    } catch (e) {
      emit(
        ChatbotError(
          errorMessage: 'Erreur lors de l\'envoi du message',
          currentLanguage: currentState.currentLanguage,
          messages: currentState.messages,
        ),
      );
    }
  }

  Future<void> _onVoiceStarted(
    ChatbotVoiceStarted event,
    Emitter<ChatbotState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatbotReady) return;

    await _chatbotService.startListening(
      onResult: (transcript) {
        add(ChatbotVoiceResultReceived(transcript));
      },
      onListeningStarted: () {
        // Rien de spécial
      },
      onListeningStopped: () {
        add(const ChatbotVoiceStopped());
      },
    );

    emit(currentState.copyWith(isListening: true, currentTranscript: ''));
  }

  Future<void> _onVoiceStopped(
    ChatbotVoiceStopped event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotService.stopListening();

    final currentState = state;
    if (currentState is ChatbotReady) {
      emit(currentState.copyWith(isListening: false));
    }
  }

  Future<void> _onVoiceResultReceived(
    ChatbotVoiceResultReceived event,
    Emitter<ChatbotState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatbotReady) return;

    emit(currentState.copyWith(isListening: false));

    if (event.transcript.isNotEmpty) {
      add(ChatbotMessageSent(event.transcript));
    }
  }

  Future<void> _onSpeakMessage(
    ChatbotSpeakMessage event,
    Emitter<ChatbotState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatbotReady) return;

    emit(currentState.copyWith(isSpeaking: true));

    await _chatbotService.speak(
      event.message.text,
      audioUrl: event.message.audioUrl,
    );

    emit(currentState.copyWith(isSpeaking: false));
  }

  Future<void> _onStopSpeaking(
    ChatbotStopSpeaking event,
    Emitter<ChatbotState> emit,
  ) async {
    await _chatbotService.stopSpeaking();

    final currentState = state;
    if (currentState is ChatbotReady) {
      emit(currentState.copyWith(isSpeaking: false));
    }
  }

  Future<void> _onHistoryCleared(
    ChatbotHistoryCleared event,
    Emitter<ChatbotState> emit,
  ) async {
    _chatbotService.clearHistory();

    final currentState = state;
    if (currentState is ChatbotReady) {
      final welcomeMessage = ChatMessage(
        text: currentState.currentLanguage.greeting,
        isUser: false,
        timestamp: DateTime.now(),
        language: currentState.currentLanguage,
      );
      emit(currentState.copyWith(messages: [welcomeMessage]));
    }
  }

  Future<void> _onQuickActionTapped(
    ChatbotQuickActionTapped event,
    Emitter<ChatbotState> emit,
  ) async {
    // Convertir l'action en message
    String message;
    switch (event.action) {
      case 'weather':
        message = 'Quel temps fait-il aujourd\'hui?';
        break;
      case 'irrigation':
        message = 'Comment dois-je irriguer mes cultures?';
        break;
      case 'disease':
        message = 'Comment détecter les maladies de mes plantes?';
        break;
      case 'market':
        message = 'Quels sont les prix du marché?';
        break;
      case 'fertilizer':
        message = 'Quel engrais utiliser pour mes cultures?';
        break;
      case 'harvest':
        message = 'Quand dois-je récolter?';
        break;
      default:
        message = event.action;
    }

    add(ChatbotMessageSent(message));
  }

  @override
  Future<void> close() {
    _chatbotService.dispose();
    return super.close();
  }
}
