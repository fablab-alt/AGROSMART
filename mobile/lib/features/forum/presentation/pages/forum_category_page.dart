import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forum_bloc.dart';
import '../../domain/entities/forum_category.dart';
import '../../domain/entities/forum_topic.dart';
import '../../../../injection_container.dart' as di;
import 'forum_topic_page.dart';
import 'create_topic_page.dart';

class ForumCategoryPage extends StatelessWidget {
  final ForumCategory category;

  const ForumCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<ForumBloc>()..add(LoadForumTopics(category.id)),
      child: Scaffold(
        appBar: AppBar(title: Text(category.name)),
        body: BlocBuilder<ForumBloc, ForumState>(
          builder: (context, state) {
            if (state is ForumLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ForumTopicsLoaded) {
              final topics = state.topics;
              if (topics.isEmpty) {
                return const Center(
                  child: Text("Aucun sujet pour le moment. Soyez le premier !"),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: topics.length,
                separatorBuilder: (ctx, i) => const Divider(),
                itemBuilder: (ctx, index) {
                  return _buildTopicTile(context, topics[index]);
                },
              );
            } else if (state is ForumError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              heroTag: 'forum_category_fab',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTopicPage(category: category),
                  ),
                );
                if (result == true) {
                  // Refresh
                  if (context.mounted) {
                    context.read<ForumBloc>().add(LoadForumTopics(category.id));
                  }
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, ForumTopic topic) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ForumTopicPage(topic: topic)),
        );
      },
      title: Text(
        topic.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(topic.content, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                topic.authorName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Icon(Icons.message, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${topic.replyCount} rép.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                _formatDate(topic.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
      trailing: topic.isSolved
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}min';
  }
}
