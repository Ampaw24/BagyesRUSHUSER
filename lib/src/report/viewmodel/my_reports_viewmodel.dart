import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/repository/report_repository.dart';

/// Sealed states for the "My Reports" list.
sealed class MyReportsState {
  const MyReportsState();
}

class MyReportsLoading extends MyReportsState {
  const MyReportsLoading();
}

class MyReportsLoaded extends MyReportsState {
  final List<Report> reports;
  const MyReportsLoaded({required this.reports});
}

class MyReportsError extends MyReportsState {
  final String message;
  const MyReportsError({required this.message});
}

/// Screen-scoped — one fresh instance per [role], owned/disposed directly by
/// `MyReportsView`'s State (mirrors [RestaurantDetailViewModel]). Being
/// re-created on every visit rather than cached across the app also means a
/// fresh submission always shows up: no manual cache-invalidation call is
/// needed when `ReportFormViewModel.submit()` succeeds elsewhere.
class MyReportsViewModel extends ViewModel<MyReportsState> {
  MyReportsViewModel({required ReportRepository repository, required this.role})
      : _repository = repository,
        super(const MyReportsLoading()) {
    _load();
  }

  final ReportRepository _repository;
  final ReportRole role;

  Future<void> _load() async {
    try {
      final reports = await _repository.getMyReports(role);
      emit(MyReportsLoaded(reports: reports));
    } catch (e) {
      emit(MyReportsError(message: e.toString()));
    }
  }

  Future<void> refresh() => _load();
}
