import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/image_compression_utils.dart';
import 'package:bagyesrushappusernew/features/report/data/repositories/report_repository_impl.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/domain/repositories/i_report_repository.dart';
import 'package:bagyesrushappusernew/features/report/presentation/states/my_reports_state.dart';
import 'package:bagyesrushappusernew/features/report/presentation/states/report_form_state.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final reportRepositoryProvider = Provider<IReportRepository>(
  (_) => ReportRepositoryImpl(client: sl<Dio>()),
);

// ─── Report form (wizard) ViewModel ───────────────────────────────────────

class ReportFormViewModel extends Notifier<ReportFormState> {
  IReportRepository get _repo => ref.read(reportRepositoryProvider);

  @override
  ReportFormState build() => ReportFormState.start(role: ReportRole.customer);

  /// Re-initializes the wizard for a new report. Called right after
  /// navigating in, with whatever context the entry point already knows
  /// (e.g. a contextual "Report" action skips straight to the reason step).
  void start({
    required ReportRole role,
    ReportTargetType? targetType,
    String? orderId,
    String? targetId,
    String? targetName,
    String? targetImageUrl,
    String? targetPhone,
  }) {
    state = ReportFormState.start(
      role: role,
      targetType: targetType,
      orderId: orderId,
      targetId: targetId,
      targetName: targetName,
      targetImageUrl: targetImageUrl,
      targetPhone: targetPhone,
    );
  }

  void selectTargetType(ReportTargetType type) {
    state = state.copyWith(targetType: type);
    goNext();
  }

  void selectTarget({
    String? orderId,
    String? targetId,
    required String targetName,
    String? targetImageUrl,
    String? targetPhone,
  }) {
    state = state.copyWith(
      orderId: orderId,
      targetId: targetId,
      targetName: targetName,
      targetImageUrl: targetImageUrl,
      targetPhone: targetPhone,
    );
    goNext();
  }

  void selectReason({
    required String code,
    required String label,
    bool isUrgent = false,
  }) {
    state = state.copyWith(
      reasonCode: code,
      reasonLabel: label,
      reasonIsUrgent: isUrgent,
    );
  }

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  Future<void> addPhotos(List<File> files) async {
    final compressed = await Future.wait(
      files.map((f) => ImageCompressionUtils.compressIfNeeded(f)),
    );
    state = state.copyWith(photos: [...state.photos, ...compressed]);
  }

  void removePhoto(int index) {
    final updated = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  void goNext() {
    if (!state.isLastStep) {
      state = state.copyWith(stepIndex: state.stepIndex + 1);
    }
  }

  void goBack() {
    if (!state.isFirstStep) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(
      submitStatus: ReportSubmitStatus.submitting,
      errorMessage: null,
    );
    try {
      final report = await _repo.submitReport(
        role: state.role,
        targetType: state.targetType!,
        orderId: state.orderId,
        targetId: state.targetId,
        targetName: state.targetName ?? '',
        targetPhone: state.targetPhone,
        reasonCode: state.reasonCode!,
        reasonLabel: state.reasonLabel!,
        description: state.description.trim(),
        attachments: state.photos,
      );
      state = state.copyWith(
        submitStatus: ReportSubmitStatus.success,
        submittedReport: report,
      );
      ref.invalidate(myReportsProvider(state.role));
    } catch (e) {
      state = state.copyWith(
        submitStatus: ReportSubmitStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final reportFormProvider =
    NotifierProvider<ReportFormViewModel, ReportFormState>(
  ReportFormViewModel.new,
);

// ─── My Reports (history) ViewModel ───────────────────────────────────────

class MyReportsViewModel extends FamilyNotifier<MyReportsState, ReportRole> {
  IReportRepository get _repo => ref.read(reportRepositoryProvider);

  @override
  MyReportsState build(ReportRole arg) {
    _load(arg);
    return const MyReportsLoading();
  }

  Future<void> _load(ReportRole role) async {
    try {
      final reports = await _repo.getMyReports(role);
      state = MyReportsLoaded(reports: reports);
    } catch (e) {
      state = MyReportsError(message: e.toString());
    }
  }

  Future<void> refresh() => _load(arg);
}

final myReportsProvider =
    NotifierProvider.family<MyReportsViewModel, MyReportsState, ReportRole>(
  MyReportsViewModel.new,
);

final reportByIdProvider = FutureProvider.family
    .autoDispose<Report, ({String id, ReportRole role})>((ref, args) {
  return ref.read(reportRepositoryProvider).getReportById(args.id, args.role);
});
