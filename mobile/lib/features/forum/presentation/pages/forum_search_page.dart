import 'package:flutter/material.dart';

class ForumSearchPage extends StatefulWidget {
  const ForumSearchPage({super.key});

  @override
  State<ForumSearchPage> createState() => _ForumSearchPageState();
}

class _ForumSearchPageState extends State<ForumSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _selectedFilter = 'all';
  String _selectedSort = 'relevance';
  List<String> _selectedTags = [];
  bool _showFilters = false;

  final List<String> _recentSearches = [
    'maladie cacao',
    'irrigation goutte à goutte',
    'fertilisant NPK',
    'taille cacaoyer',
  ];

  final List<String> _suggestedTags = [
    'Cacao',
    'Café',
    'Hévéa',
    'Maladie',
    'Irrigation',
    'Fertilisation',
    'Récolte',
    'Semis',
    'Bio',
    'Technique',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: 'Rechercher dans le forum...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showFilters ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          if (_showFilters) _buildFiltersSection(),

          // Contenu principal
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildInitialContent()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type de contenu
          const Text(
            'Type de contenu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tout', Icons.all_inclusive),
                _buildFilterChip('topics', 'Sujets', Icons.article),
                _buildFilterChip('answers', 'Réponses', Icons.question_answer),
                _buildFilterChip('solved', 'Résolus', Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tri
          const Text(
            'Trier par',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('relevance', 'Pertinence'),
                _buildSortChip('recent', 'Plus récent'),
                _buildSortChip('popular', 'Plus populaire'),
                _buildSortChip('votes', 'Plus voté'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tags
          const Text(
            'Tags',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTags.map((tag) => _buildTagChip(tag)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.green.shade100,
        checkmarkColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _selectedSort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedSort = value;
          });
        },
        selectedColor: Colors.green.shade100,
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    return FilterChip(
      selected: isSelected,
      label: Text(tag, style: const TextStyle(fontSize: 12)),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: const Color(0xFF2E7D32),
    );
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherches récentes
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recherches récentes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: const Text('Effacer'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentSearches.map(
              (search) => ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west, size: 16),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                ),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              ),
            ),
            const Divider(height: 32),
          ],

          // Suggestions populaires
          const Text(
            'Recherches populaires',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPopularSearchChip('🌱 Semis cacao'),
              _buildPopularSearchChip('🐛 Maladies courantes'),
              _buildPopularSearchChip('💧 Irrigation'),
              _buildPopularSearchChip('🌿 Agriculture bio'),
              _buildPopularSearchChip('📈 Rendement'),
              _buildPopularSearchChip('🔧 Outils agricoles'),
            ],
          ),

          const SizedBox(height: 32),

          // Questions fréquentes
          const Text(
            'Questions fréquentes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildFAQItem(
            'Comment traiter la pourriture brune du cacao?',
            '23 réponses',
          ),
          _buildFAQItem(
            'Quel est le meilleur moment pour la récolte?',
            '18 réponses',
          ),
          _buildFAQItem('Comment améliorer la qualité du sol?', '31 réponses'),
        ],
      ),
    );
  }

  Widget _buildPopularSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .trim();
        _performSearch(_searchController.text);
      },
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildFAQItem(String question, String answers) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.help_outline, color: Colors.green.shade700),
      ),
      title: Text(question, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(answers),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap: () {},
    );
  }

  Widget _buildSearchResults() {
    // Simuler des résultats de recherche
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        return _SearchResultItem(
          title: 'Résultat pour "${_searchController.text}" #${index + 1}',
          snippet:
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
          author: 'Utilisateur ${index + 1}',
          date: 'Il y a ${index + 1} jours',
          replies: (index + 1) * 2,
          isSolved: index % 3 == 0,
          matchedTags: index % 2 == 0 ? ['Cacao', 'Maladie'] : ['Irrigation'],
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      // Ajouter aux recherches récentes
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
      // En production, lancer la recherche via le BLoC
    }
  }
}

class _SearchResultItem extends StatelessWidget {
  final String title;
  final String snippet;
  final String author;
  final String date;
  final int replies;
  final bool isSolved;
  final List<String> matchedTags;

  const _SearchResultItem({
    required this.title,
    required this.snippet,
    required this.author,
    required this.date,
    required this.replies,
    required this.isSolved,
    required this.matchedTags,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Résolu',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                snippet,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Tags
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: matchedTags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      author[0],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    author,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$replies',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
