import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/search_history_local_datasource.dart';
import '../../domain/entities/search_history.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchProducts extends SearchEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadSearchHistory extends SearchEvent {}

class AddSearchQuery extends SearchEvent {
  final String query;
  final int resultCount;

  const AddSearchQuery(this.query, this.resultCount);

  @override
  List<Object?> get props => [query, resultCount];
}

class RemoveSearchQuery extends SearchEvent {
  final String query;

  const RemoveSearchQuery(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchHistory extends SearchEvent {}

// States
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<dynamic> results;

  const SearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

class SearchHistoryLoaded extends SearchState {
  final List<SearchQuery> history;

  const SearchHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchHistoryLocalDataSource localDataSource;

  SearchBloc({required this.localDataSource}) : super(SearchInitial()) {
    on<SearchProducts>(_onSearchProducts);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<AddSearchQuery>(_onAddSearchQuery);
    on<RemoveSearchQuery>(_onRemoveSearchQuery);
    on<ClearSearchHistory>(_onClearSearchHistory);
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());

    try {
      // TODO: Implement actual search API call
      // For now, just save to history
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock results
      final results = <dynamic>[];

      // Save search query to history
      await localDataSource.addSearchQuery(event.query, results.length);

      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final history = await localDataSource.getSearchHistory();
      emit(SearchHistoryLoaded(history));
    } catch (e) {
      emit(SearchError('Erreur lors du chargement de l\'historique'));
    }
  }

  Future<void> _onAddSearchQuery(
    AddSearchQuery event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await localDataSource.addSearchQuery(event.query, event.resultCount);
      final history = await localDataSource.getSearchHistory();
      emit(SearchHistoryLoaded(history));
    } catch (e) {
      emit(SearchError('Erreur lors de l\'ajout à l\'historique'));
    }
  }

  Future<void> _onRemoveSearchQuery(
    RemoveSearchQuery event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await localDataSource.removeSearchQuery(event.query);
      final history = await localDataSource.getSearchHistory();
      emit(SearchHistoryLoaded(history));
    } catch (e) {
      emit(SearchError('Erreur lors de la suppression'));
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await localDataSource.clearSearchHistory();
      emit(const SearchHistoryLoaded([]));
    } catch (e) {
      emit(SearchError('Erreur lors de l\'effacement'));
    }
  }
}
