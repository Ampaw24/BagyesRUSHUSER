import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/repository/report_repository.dart';

/// Sealed states for a single report's detail fetch.
sealed class ReportDetailState {
  const ReportDetailState();
}

class ReportDetailLoading extends ReportDetailState {
  const ReportDetailLoading();
}

class ReportDetailLoaded extends ReportDetailState {
  final Report report;
  const ReportDetailLoaded({required this.report});
}

class ReportDetailError extends ReportDetailState {
  final String message;
  const ReportDetailError({required this.message});
}

/// Screen-scoped — one fresh instance per [reportId]/[role] pair, owned and
/// disposed directly by `ReportDetailView`'s State (mirrors
/// [RestaurantDetailViewModel]).
class ReportDetailViewModel extends ViewModel<ReportDetailState> {
  ReportDetailViewModel({
    required ReportRepository repository,
    required this.reportId,
    required this.role,
  })  : _repository = repository,
        super(const ReportDetailLoading()) {
    _load();
  }

  final ReportRepository _repository;
  final String reportId;
  final ReportRole role;

  Future<void> _load() async {
    try {
      final report = await _repository.getReportById(reportId, role);
      emit(ReportDetailLoaded(report: report));
    } catch (e) {
      emit(ReportDetailError(message: e.toString()));
    }
  }
}
