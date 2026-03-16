import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';

/// Sealed states for the search screen.
sealed class SearchState {
  const SearchState();
}

/// No query entered yet — show suggestions.
class SearchIdle extends SearchState {
  const SearchIdle();
}

/// Query is set, search in progress.
class SearchLoading extends SearchState {
  final String query;
  const SearchLoading({required this.query});
}

/// Search returned results (may be empty list).
class SearchLoaded extends SearchState {
  final String query;
  final List<Restaurant> results;
  const SearchLoaded({required this.query, required this.results});

  bool get hasResults => results.isNotEmpty;
}

/// Search failed.
class SearchError extends SearchState {
  final String query;
  final String message;
  const SearchError({required this.query, required this.message});
}
