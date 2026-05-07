import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/chat_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';

class CommunityUser {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;

  CommunityUser({required this.id, required this.name, this.avatar, this.bio});
}

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CommunityUser> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(
        '/communaute/members',
        queryParameters: {'search': query},
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _isLoading = false;
          _searchResults = data
              .map(
                (u) => CommunityUser(
                  id: u['id']?.toString() ?? '',
                  name: '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim(),
                  bio: u['bio'] ?? u['role'] ?? '',
                  avatar: u['photo_profil'],
                ),
              )
              .toList();
        });
      } else {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      debugPrint('Erreur recherche utilisateurs: $e');
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  void _startChat(CommunityUser user) {
    // Logic to start chat:
    // 1. Check if conversation exists (optional optimization)
    // 2. Create conversation via Bloc
    // 3. Navigate/Pop back to Chat List or specific Chat Page

    context.read<ChatBloc>().add(
      CreateConversation(
        type: 'prive',
        participants: [user.id],
        nom: user.name,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Conversation créée avec ${user.name}')),
    );

    // Ideally wait for Bloc State to change to "ConversationCreated" then navigate
    // For now assuming success
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un utilisateur')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nom, téléphone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),

          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Recherchez des amis ou partenaires'
                              : 'Aucun résultat trouvé',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user.bio ?? 'AgroSmart Membre'),
                        trailing: IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () => _startChat(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
