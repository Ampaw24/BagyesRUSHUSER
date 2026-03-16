import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/search/presentation/states/search_state.dart';

// ─── Search ViewModel ─────────────────────────────────────────────────────

class SearchViewModel extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchIdle();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchIdle();
      return;
    }

    state = SearchLoading(query: trimmed);
    try {
      final results = await ref
          .read(restaurantRepositoryProvider)
          .search(trimmed);
      state = SearchLoaded(query: trimmed, results: results);
    } catch (e) {
      state = SearchError(query: trimmed, message: e.toString());
    }
  }

  void clear() => state = const SearchIdle();
}

final searchProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);
