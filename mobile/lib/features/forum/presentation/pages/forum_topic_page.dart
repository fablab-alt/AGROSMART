import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forum_bloc.dart';
import '../../domain/entities/forum_topic.dart';
import '../../domain/entities/forum_post.dart';
import '../../../../injection_container.dart' as di;

class ForumTopicPage extends StatefulWidget {
  final ForumTopic topic;

  const ForumTopicPage({super.key, required this.topic});

  @override
  State<ForumTopicPage> createState() => _ForumTopicPageState();
}

class _ForumTopicPageState extends State<ForumTopicPage> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ForumBloc>()..add(LoadForumPosts(widget.topic.id)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discussion'),
        ),
        body: Column(
          children: [
             Expanded(
               child: BlocConsumer<ForumBloc, ForumState>(
                listener: (context, state) {
                  if (state is ForumOperationSuccess) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                     _replyController.clear();
                  }
                },
                builder: (context, state) {
                   if (state is ForumLoading) {
                     return const Center(child: CircularProgressIndicator());
                   } else if (state is ForumPostsLoaded) {
                      final posts = state.posts;
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTopicHeader(widget.topic),
                          const SizedBox(height: 24),
                          const Text("Réponses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (posts.isEmpty)
                             const Center(child: Padding(
                               padding: EdgeInsets.all(20.0),
                               child: Text("Aucune réponse pour le moment."),
                             )),
                          ...posts.map((p) => _buildPostCard(p)),
                        ],  
                      );
                   }
                   return const Center(child: CircularProgressIndicator()); // Or Initial
                },
               ),
             ),
             _buildReplyArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicHeader(ForumTopic topic) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(topic.authorName[0])),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(topic.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (topic.authorBadge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: HexColor(topic.authorBadge!.color ?? '#FFD700'),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              topic.authorBadge!.label,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]
                      ],
                    ),
                    Text(_formatDate(topic.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              topic.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              topic.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: topic.tags.map((t) => Chip(
                label: Text('#$t', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.shade50,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16), // Indent for replies
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                   if (post.authorBadge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: HexColor(post.authorBadge!.color ?? '#FFD700'),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          post.authorBadge!.label,
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                   ]
                ],
              ),
              Text(_formatDate(post.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${post.upvotes}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              if (post.isSolution) 
                 const Chip(
                   label: Text("Solution", style: TextStyle(color: Colors.white, fontSize: 10)),
                   backgroundColor: Colors.green,
                   padding: EdgeInsets.zero,
                  )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReplyArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10
          )
        ]
      ),
      child: SafeArea(
        child: Row(
          children: [
             Expanded(
               child: TextField(
                 controller: _replyController,
                 decoration: InputDecoration(
                   hintText: 'Écrire une réponse...',
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                   filled: true,
                   fillColor: Colors.grey.shade100,
                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 ),
                 minLines: 1,
                 maxLines: 3,
               ),
             ),
             const SizedBox(width: 8),
             // Use Builder to get context with Provider
             Builder(
               builder: (context) {
                 return IconButton(
                   icon: const Icon(Icons.send, color: Colors.green),
                   onPressed: () {
                      final content = _replyController.text.trim();
                      if (content.isNotEmpty) {
                        context.read<ForumBloc>().add(CreateForumPost(topicId: widget.topic.id, content: content));
                      }
                   },
                 );
               }
             )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
