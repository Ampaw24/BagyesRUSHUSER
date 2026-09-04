import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/restaurant.dart';
import 'package:bagyesrushappusernew/src/restaurant/repositories/restaurant_repository.dart';

/// Sealed states for the "which restaurant?" target picker.
sealed class ReportVendorsState {
  const ReportVendorsState();
}

class ReportVendorsLoading extends ReportVendorsState {
  const ReportVendorsLoading();
}

class ReportVendorsLoaded extends ReportVendorsState {
  final List<Restaurant> restaurants;
  const ReportVendorsLoaded({required this.restaurants});
}

class ReportVendorsError extends ReportVendorsState {
  final String message;
  const ReportVendorsError({required this.message});
}

/// Full, unfiltered vendor list — deliberately independent of Home's
/// selected-category state so picking a category on Home doesn't affect who
/// shows up here. Backed by the real `GET /vendors` endpoint (already live),
/// unlike the rest of this feature which is still on dummy data.
///
/// Screen-scoped (owned/disposed by `_VendorTargetPicker`'s State within the
/// report flow) rather than app-wide singleton, mirroring
/// [RestaurantDetailViewModel] — this list is only ever needed mid-wizard.
class ReportVendorsViewModel extends ViewModel<ReportVendorsState> {
  ReportVendorsViewModel(this._repository) : super(const ReportVendorsLoading()) {
    _load();
  }

  final RestaurantRepository _repository;

  Future<void> _load() async {
    emit(const ReportVendorsLoading());
    try {
      final restaurants = await _repository.getRestaurants();
      emit(ReportVendorsLoaded(restaurants: restaurants));
    } catch (e) {
      emit(ReportVendorsError(message: e.toString()));
    }
  }

  Future<void> retry() => _load();
}
