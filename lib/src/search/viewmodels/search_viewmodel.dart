import 'dart:async';

import 'package:gopady/core/viewmodel/viewmodel.dart';
import 'package:gopady/src/restaurant/repositories/restaurant_repository.dart';
import 'package:gopady/src/search/viewmodels/search_state.dart';

class SearchViewModel extends ViewModel<SearchState> {
  SearchViewModel(this._repository) : super(const SearchIdle());

  final RestaurantRepository _repository;

  // Matches the debounce duration already used by HomeDiscoveryViewModel's
  // category switch and MapLocationPickerSheet's own search box.
  static const _debounceDuration = Duration(milliseconds: 350);

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Shows the loading state immediately (instant feedback while typing),
  /// but debounces the actual network call.
  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(const SearchIdle());
      return;
    }

    emit(SearchLoading(query: trimmed));
    _debounce = Timer(_debounceDuration, () => _performSearch(trimmed));
  }

  Future<void> _performSearch(String trimmed) async {
    try {
      final results = await _repository.search(trimmed);
      emit(SearchLoaded(query: trimmed, results: results));
    } catch (e) {
      emit(SearchError(query: trimmed, message: e.toString()));
    }
  }

  void clear() {
    _debounce?.cancel();
    emit(const SearchIdle());
  }
}
