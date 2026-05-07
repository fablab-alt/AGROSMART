import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/search_history.dart';

abstract class SearchHistoryLocalDataSource {
  Future<List<SearchQuery>> getSearchHistory();
  Future<void> addSearchQuery(String query, int resultCount);
  Future<void> removeSearchQuery(String query);
  Future<void> clearSearchHistory();
}

class SearchHistoryLocalDataSourceImpl implements SearchHistoryLocalDataSource {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistorySize = 20;
  final SharedPreferences sharedPreferences;

  SearchHistoryLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<SearchQuery>> getSearchHistory() async {
    final historyJson = sharedPreferences.getStringList(_searchHistoryKey);

    if (historyJson == null || historyJson.isEmpty) {
      return [];
    }

    return historyJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return SearchQuery(
        query: data['query'] as String,
        timestamp: DateTime.parse(data['timestamp'] as String),
        resultCount: data['resultCount'] as int,
      );
    }).toList();
  }

  @override
  Future<void> addSearchQuery(String query, int resultCount) async {
    final history = await getSearchHistory();

    // Remove duplicate if exists
    history.removeWhere((q) => q.query.toLowerCase() == query.toLowerCase());

    // Add new query at the beginning
    final newQuery = SearchQuery(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
    );
    history.insert(0, newQuery);

    // Keep only the most recent queries
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    // Save to shared preferences
    final historyJson = history.map((q) {
      return jsonEncode({
        'query': q.query,
        'timestamp': q.timestamp.toIso8601String(),
        'resultCount': q.resultCount,
      });
    }).toList();

    await sharedPreferences.setStringList(_searchHistoryKey, historyJson);
  }

  @override
  Future<void> removeSearchQuery(String query) async {
    final history = await getSearchHistory();
    history.removeWhere((q) => q.query.toLowerCase() == query.toLowerCase());

    final historyJson = history.map((q) {
      return jsonEncode({
        'query': q.query,
        'timestamp': q.timestamp.toIso8601String(),
        'resultCount': q.resultCount,
      });
    }).toList();

    await sharedPreferences.setStringList(_searchHistoryKey, historyJson);
  }

  @override
  Future<void> clearSearchHistory() async {
    await sharedPreferences.remove(_searchHistoryKey);
  }
}
