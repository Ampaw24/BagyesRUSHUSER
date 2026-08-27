import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/viewmodels/restaurant_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/search/presentation/states/search_state.dart';

// ─── Search ViewModel ─────────────────────────────────────────────────────

class SearchViewModel extends Notifier<SearchState> {
  // Matches the debounce duration already used by SelectedCategoryNotifier
  // and MapLocationPickerSheet's own search box.
  static const _debounceDuration = Duration(milliseconds: 350);

  Timer? _debounce;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchIdle();
  }

  /// Shows the loading state immediately (instant feedback while typing),
  /// but debounces the actual network call.
  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchIdle();
      return;
    }

    state = SearchLoading(query: trimmed);
    _debounce = Timer(_debounceDuration, () => _performSearch(trimmed));
  }

  Future<void> _performSearch(String trimmed) async {
    try {
      final results = await ref
          .read(restaurantRepositoryProvider)
          .search(trimmed);
      state = SearchLoaded(query: trimmed, results: results);
    } catch (e) {
      state = SearchError(query: trimmed, message: e.toString());
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchIdle();
  }
}

final searchProvider =
    NotifierProvider<SearchViewModel, SearchState>(SearchViewModel.new);
