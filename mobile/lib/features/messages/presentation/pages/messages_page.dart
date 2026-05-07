import 'package:agriculture/features/messages/domain/entities/conversation.dart';
import 'package:agriculture/features/messages/domain/entities/message.dart';
import 'package:agriculture/features/messages/presentation/bloc/message_bloc.dart';
import 'package:agriculture/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MessageBloc>()..add(LoadConversations()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Tous'),
              Tab(text: 'Groupes'),
              Tab(text: 'Support'),
            ],
          ),
        ),
        body: BlocBuilder<MessageBloc, MessageState>(
          buildWhen: (previous, current) =>
              current is ConversationsLoaded ||
              current is ConversationsLoading ||
              current is MessageError,
          builder: (context, state) {
            if (state is ConversationsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MessageError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else if (state is ConversationsLoaded) {
              final conversations = state.conversations;
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildConversationList(conversations),
                  _buildConversationList(
                    conversations.where((c) => c.isGroup).toList(),
                  ),
                  _buildConversationList(
                    conversations.where((c) => c.isSupport).toList(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'messages_new_fab',
          onPressed: () => _showNewMessageDialog(context),
          backgroundColor: const Color(0xFF4285F4),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) =>
          _buildConversationTile(conversations[index]),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    return Container(
      color: conv.nonLus > 0
          ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF4285F4).withOpacity(0.1)
                : const Color(0xFF4285F4).withOpacity(0.1))
          : Theme.of(context).cardColor,
      child: ListTile(
        onTap: () => _openChat(conv),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: conv.isGroup
                  ? Colors.blue.shade100
                  : conv.isSupport
                  ? Colors.green.shade100
                  : Colors.pink.shade100,
              radius: 24,
              child: Icon(
                conv.isGroup
                    ? Icons.group
                    : conv.isSupport
                    ? Icons.support_agent
                    : Icons.person,
                color: conv.isGroup
                    ? Colors.blue
                    : conv.isSupport
                    ? Colors.green
                    : Colors.pink,
              ),
            ),
            if (conv.isOnline && !conv.isGroup)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conv.nom,
                style: TextStyle(
                  fontWeight: conv.nonLus > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            Text(
              _formatTime(conv.dateMessage),
              style: TextStyle(
                fontSize: 12,
                color: conv.nonLus > 0 ? const Color(0xFF4285F4) : Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conv.dernierMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: conv.nonLus > 0
                      ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87)
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            if (conv.nonLus > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conv.nonLus}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openChat(Conversation conv) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<MessageBloc>()..add(LoadMessages(conv.id)),
          child: ChatPage(conversation: conv),
        ),
      ),
    );
    // Reload logic removed as we can't easily access parent context here without state management improvements
    // Ideally we would trigger reload on return if needed.
  }

  void _showNewMessageDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nouvelle conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.pink.shade100,
                child: const Icon(Icons.person_add, color: Colors.pink),
              ),
              title: const Text('Nouveau message'),
              subtitle: const Text('Contacter un autre agriculteur'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.group_add, color: Colors.blue),
              ),
              title: const Text('Créer un groupe'),
              subtitle: const Text('Discuter avec plusieurs personnes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.support_agent, color: Colors.green),
              ),
              title: const Text('Contacter le support'),
              subtitle: const Text('Obtenir de l\'aide'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inDays}j';
    }
  }
}

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(
                widget.conversation.isGroup ? Icons.group : Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.nom,
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.conversation.isOnline)
                  const Text(
                    'En ligne',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MessageBloc, MessageState>(
              listener: (context, state) {
                if (state is ChatLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MessageError) {
                  return Center(child: Text('Erreur: ${state.message}'));
                } else if (state is ChatLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return const Center(child: Text('Aucun message.'));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageBubble(messages[index]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                    color: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {},
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4285F4),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.envoyeurId != widget.conversation.id;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF4285F4)
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.texte,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.date),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<MessageBloc>().add(
      SendMessage(userId: widget.conversation.id, content: text),
    );
    // The Bloc will handle the request and reload messages if successful
    _messageController.clear();
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
