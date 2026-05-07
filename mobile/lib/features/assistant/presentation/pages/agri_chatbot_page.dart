import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/core/services/agri_chatbot_service.dart';
import 'package:agriculture/features/assistant/presentation/bloc/chatbot_bloc.dart';

/// Page du chatbot vocal multilingue agricole
class AgriChatbotPage extends StatefulWidget {
  const AgriChatbotPage({super.key});

  @override
  State<AgriChatbotPage> createState() => _AgriChatbotPageState();
}

class _AgriChatbotPageState extends State<AgriChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialiser le chatbot
    context.read<ChatbotBloc>().add(const ChatbotInitialized());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLanguageSelector(),
          Expanded(child: _buildChatArea()),
          _buildQuickActions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant AgroSmart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'En ligne',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<ChatbotBloc>().add(const ChatbotHistoryCleared());
          },
          tooltip: 'Nouvelle conversation',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            // Options supplémentaires
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Aide'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Paramètres'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return BlocBuilder<ChatbotBloc, ChatbotState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF388E3C),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LocalLanguage.values.map((language) {
                final isSelected = state.currentLanguage == language;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _LanguageChip(
                    language: language,
                    isSelected: isSelected,
                    onTap: () {
                      context.read<ChatbotBloc>().add(
                        ChatbotLanguageChanged(language),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatArea() {
    return BlocConsumer<ChatbotBloc, ChatbotState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        if (state is ChatbotInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }

        if (state.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              state.messages.length + (state is ChatbotProcessing ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messages.length && state is ChatbotProcessing) {
              return _buildTypingIndicator();
            }
            return _MessageBubble(
              message: state.messages[index],
              onSpeak: () {
                context.read<ChatbotBloc>().add(
                  ChatbotSpeakMessage(state.messages[index]),
                );
              },
              isSpeaking: state.isSpeaking,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              size: 50,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Votre Assistant Agricole',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Posez vos questions en français ou en\nlangue locale (Baoulé, Dioula, Sénoufo...)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.grey[300],
                          const Color(0xFF2E7D32),
                          value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickActionChip(
              icon: Icons.wb_sunny,
              label: 'Météo',
              onTap: () => _sendQuickAction('weather'),
            ),
            _QuickActionChip(
              icon: Icons.water_drop,
              label: 'Irrigation',
              onTap: () => _sendQuickAction('irrigation'),
            ),
            _QuickActionChip(
              icon: Icons.bug_report,
              label: 'Maladies',
              onTap: () => _sendQuickAction('disease'),
            ),
            _QuickActionChip(
              icon: Icons.store,
              label: 'Marché',
              onTap: () => _sendQuickAction('market'),
            ),
            _QuickActionChip(
              icon: Icons.eco,
              label: 'Engrais',
              onTap: () => _sendQuickAction('fertilizer'),
            ),
            _QuickActionChip(
              icon: Icons.grass,
              label: 'Récolte',
              onTap: () => _sendQuickAction('harvest'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuickAction(String action) {
    context.read<ChatbotBloc>().add(ChatbotQuickActionTapped(action));
  }

  Widget _buildInputArea() {
    return BlocBuilder<ChatbotBloc, ChatbotState>(
      builder: (context, state) {
        final isListening = state.isListening;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Bouton micro
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isListening ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTapDown: (_) {
                          context.read<ChatbotBloc>().add(
                            const ChatbotVoiceStarted(),
                          );
                        },
                        onTapUp: (_) {
                          context.read<ChatbotBloc>().add(
                            const ChatbotVoiceStopped(),
                          );
                        },
                        onTapCancel: () {
                          context.read<ChatbotBloc>().add(
                            const ChatbotVoiceStopped(),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isListening
                                ? Colors.red
                                : const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Champ de texte
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: isListening
                          ? 'Parlez maintenant...'
                          : 'Tapez votre message...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton envoyer
                GestureDetector(
                  onTap: () => _sendMessage(_textController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatbotBloc>().add(ChatbotMessageSent(text.trim()));
    _textController.clear();
  }
}

/// Chip de sélection de langue
class _LanguageChip extends StatelessWidget {
  final LocalLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          language.displayName,
          style: TextStyle(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Bulle de message
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onSpeak;
  final bool isSpeaking;

  const _MessageBubble({
    required this.message,
    required this.onSpeak,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onSpeak,
                          child: Icon(
                            isSpeaking
                                ? Icons.volume_up
                                : Icons.volume_up_outlined,
                            size: 18,
                            color: isSpeaking
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF81C784),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Chip d'action rapide
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 12),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        onPressed: onTap,
      ),
    );
  }
}
