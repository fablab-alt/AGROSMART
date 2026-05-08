import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/friend.dart';
import '../bloc/friendships_bloc.dart';

/// Page principale du réseau social — 4 onglets :
/// Mes amis · Demandes reçues · Demandes envoyées · Suggestions
class FriendshipsPage extends StatelessWidget {
  const FriendshipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final bloc = context.read<FriendshipsBloc>();
        bloc.add(LoadFriendships());
        return bloc;
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Réseau & Amis'),
            backgroundColor: Colors.green,
            bottom: const TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.people), text: 'Amis'),
                Tab(icon: Icon(Icons.inbox), text: 'Reçues'),
                Tab(icon: Icon(Icons.outbox), text: 'Envoyées'),
                Tab(icon: Icon(Icons.person_add), text: 'Suggestions'),
              ],
            ),
          ),
          body: BlocBuilder<FriendshipsBloc, FriendshipsState>(
            builder: (context, state) {
              if (state is FriendshipsLoading || state is FriendshipsInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is FriendshipsError) {
                return _ErrorView(message: state.message, onRetry: () {
                  context.read<FriendshipsBloc>().add(LoadFriendships());
                });
              }
              if (state is FriendshipsLoaded) {
                return TabBarView(
                  children: [
                    _FriendsList(friends: state.friends),
                    _ReceivedList(requests: state.received),
                    _SentList(requests: state.sent),
                    _SuggestionsList(suggestions: state.suggestions),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

// ─── Widgets partagés ──────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _Avatar({required this.initials, this.color = Colors.green});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: color,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

// ─── Tab : Amis ────────────────────────────────────────────────────────────
class _FriendsList extends StatelessWidget {
  final List<Friend> friends;
  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return _EmptyView(
        icon: Icons.people_outline,
        title: 'Pas encore d\'amis',
        subtitle: 'Découvrez des suggestions ou recherchez des utilisateurs',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = friends[i];
        return Card(
          child: ListTile(
            leading: _Avatar(initials: f.initiales),
            title: Text(f.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.role, style: const TextStyle(fontSize: 12)),
                if (f.regionNom != null) Text('📍 ${f.regionNom}', style: const TextStyle(fontSize: 12)),
                if (f.amisDepuis != null)
                  Text('Amis depuis ${DateFormat.yMMMd('fr_FR').format(f.amisDepuis!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'remove') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Retirer de mes amis'),
                      content: Text('Retirer ${f.nomComplet} ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () {
                            context.read<FriendshipsBloc>().add(RemoveFriend(f.friendshipId));
                            Navigator.pop(context);
                          },
                          child: const Text('Retirer', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'remove', child: Text('Retirer')),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab : Demandes reçues ─────────────────────────────────────────────────
class _ReceivedList extends StatelessWidget {
  final List<FriendRequest> requests;
  const _ReceivedList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyView(
        icon: Icons.inbox_outlined,
        title: 'Aucune demande en attente',
        subtitle: 'Les demandes que vous recevez apparaîtront ici',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = requests[i];
        final from = r.from!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Avatar(initials: from.initiales, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(from.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(from.role, style: const TextStyle(fontSize: 12)),
                      Text(DateFormat.yMd('fr_FR').format(r.sentAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.read<FriendshipsBloc>().add(AcceptFriendRequest(r.id)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Accepter'),
                    ),
                    TextButton(
                      onPressed: () => context.read<FriendshipsBloc>().add(RejectFriendRequest(r.id)),
                      child: const Text('Refuser', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab : Demandes envoyées ───────────────────────────────────────────────
class _SentList extends StatelessWidget {
  final List<FriendRequest> requests;
  const _SentList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyView(
        icon: Icons.outbox_outlined,
        title: 'Aucune demande envoyée',
        subtitle: 'Vos demandes en attente apparaîtront ici',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = requests[i];
        final to = r.to!;
        return Card(
          child: ListTile(
            leading: _Avatar(initials: to.initiales, color: Colors.grey),
            title: Text(to.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${to.role} · Envoyée ${DateFormat.yMd('fr_FR').format(r.sentAt)}',
                style: const TextStyle(fontSize: 12)),
            trailing: const Chip(
              label: Text('En attente'),
              backgroundColor: Color(0xFFFFF3E0),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab : Suggestions ─────────────────────────────────────────────────────
class _SuggestionsList extends StatelessWidget {
  final List<FriendSuggestion> suggestions;
  const _SuggestionsList({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return _EmptyView(
        icon: Icons.person_add_alt,
        title: 'Aucune suggestion',
        subtitle: 'Revenez plus tard pour découvrir de nouveaux contacts',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = suggestions[i];
        return Card(
          child: ListTile(
            leading: _Avatar(initials: s.initiales, color: Colors.purple),
            title: Text(s.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.role, style: const TextStyle(fontSize: 12)),
                if (s.regionNom != null) Text('📍 ${s.regionNom}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => context.read<FriendshipsBloc>().add(SendFriendRequest(s.id)),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
