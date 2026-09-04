import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/image_compression_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/model/report_reason.dart';
import 'package:bagyesrushappusernew/src/report/repository/report_repository.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';

/// The steps of the report wizard, in order. A given run only shows a
/// subset of these — [ReportFormState.steps] holds the filtered sequence.
enum ReportWizardStep { targetType, target, reason, details }

enum ReportSubmitStatus { idle, submitting, success, error }

class ReportFormState extends Equatable {
  final ReportRole role;

  /// Whether [targetType] was supplied upfront (e.g. from an order card),
  /// so the wizard skips the "what would you like to report?" step.
  final bool targetTypeLocked;

  /// Whether a specific target was supplied upfront, so the wizard skips
  /// the target-picker step regardless of category.
  final bool targetLocked;

  final int stepIndex;

  final ReportTargetType? targetType;
  final String? orderId;
  final String? targetId;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  final String? reasonCode;
  final String? reasonLabel;

  final ReportReason? reasonCategories;
  final bool reasonsLoading;
  final String? reasonsError;

  final String description;
  final List<File> photos;

  final ReportSubmitStatus submitStatus;
  final String? errorMessage;
  final Report? submittedReport;

  const ReportFormState({
    required this.role,
    required this.targetTypeLocked,
    required this.targetLocked,
    this.stepIndex = 0,
    this.targetType,
    this.orderId,
    this.targetId,
    this.targetName,
    this.targetImageUrl,
    this.targetPhone,
    this.reasonCode,
    this.reasonLabel,
    this.reasonCategories,
    this.reasonsLoading = false,
    this.reasonsError,
    this.description = '',
    this.photos = const [],
    this.submitStatus = ReportSubmitStatus.idle,
    this.errorMessage,
    this.submittedReport,
  });

  factory ReportFormState.start({
    required ReportRole role,
    ReportTargetType? targetType,
    String? orderId,
    String? targetId,
    String? targetName,
    String? targetImageUrl,
    String? targetPhone,
  }) {
    final hasTarget = targetName != null && targetName.isNotEmpty;
    return ReportFormState(
      role: role,
      targetTypeLocked: targetType != null,
      targetLocked: hasTarget,
      targetType: targetType,
      orderId: orderId,
      targetId: targetId,
      targetName: targetName,
      targetImageUrl: targetImageUrl,
      targetPhone: targetPhone,
    );
  }

  /// The wizard steps for the current [targetType]. `target` only appears
  /// when the chosen category actually needs a specific vendor/rider/
  /// customer identified (see [ReportTargetType.requiresTarget]) — before a
  /// category is picked it's included by default so the progress bar
  /// doesn't jump once one is chosen.
  List<ReportWizardStep> get steps => [
        if (!targetTypeLocked) ReportWizardStep.targetType,
        if (!targetLocked && (targetType?.requiresTarget ?? true))
          ReportWizardStep.target,
        ReportWizardStep.reason,
        ReportWizardStep.details,
      ];

  ReportWizardStep get currentStep => steps[stepIndex];
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => stepIndex == steps.length - 1;
  double get progress => (stepIndex + 1) / steps.length;

  bool get hasTarget => targetName != null && targetName!.isNotEmpty;
  bool get needsTarget => targetType?.requiresTarget ?? true;
  bool get hasReason => reasonCode != null;
  bool get canSubmit =>
      targetType != null &&
      (!needsTarget || hasTarget) &&
      hasReason &&
      description.trim().length >= 10;

  /// The reason options for the current [targetType], flattened from the
  /// fetched [reasonCategories].
  List<ReportReasonOption> get currentReasons =>
      targetType == null || reasonCategories == null
          ? const []
          : reasonCategories!.forTargetType(targetType!);

  ReportFormState copyWith({
    int? stepIndex,
    ReportTargetType? targetType,
    String? orderId,
    String? targetId,
    String? targetName,
    String? targetImageUrl,
    String? targetPhone,
    String? reasonCode,
    String? reasonLabel,
    ReportReason? reasonCategories,
    bool? reasonsLoading,
    String? reasonsError,
    String? description,
    List<File>? photos,
    ReportSubmitStatus? submitStatus,
    String? errorMessage,
    Report? submittedReport,
  }) {
    return ReportFormState(
      role: role,
      targetTypeLocked: targetTypeLocked,
      targetLocked: targetLocked,
      stepIndex: stepIndex ?? this.stepIndex,
      targetType: targetType ?? this.targetType,
      orderId: orderId ?? this.orderId,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetImageUrl: targetImageUrl ?? this.targetImageUrl,
      targetPhone: targetPhone ?? this.targetPhone,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      reasonCategories: reasonCategories ?? this.reasonCategories,
      reasonsLoading: reasonsLoading ?? this.reasonsLoading,
      reasonsError: reasonsError,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: errorMessage,
      submittedReport: submittedReport ?? this.submittedReport,
    );
  }

  @override
  List<Object?> get props => [
        role,
        targetTypeLocked,
        targetLocked,
        stepIndex,
        targetType,
        orderId,
        targetId,
        targetName,
        targetImageUrl,
        targetPhone,
        reasonCode,
        reasonLabel,
        reasonCategories,
        reasonsLoading,
        reasonsError,
        description,
        photos,
        submitStatus,
        errorMessage,
        submittedReport,
      ];
}

/// Screen-scoped — one fresh instance per [ReportFlowView] push (mirrors
/// [RestaurantDetailViewModel]/`SendParcelViewModel`), not shared app-wide:
/// the wizard always starts clean for whatever [ReportFlowArgs] the entry
/// point passed in, so there's no `start()`/re-init method — that happens
/// once, in the constructor.
class ReportFormViewModel extends ViewModel<ReportFormState> {
  ReportFormViewModel(this._repository, {required ReportFlowArgs args})
      : super(
          ReportFormState.start(
            role: args.role,
            targetType: args.targetType,
            orderId: args.orderId,
            targetId: args.targetId,
            targetName: args.targetName,
            targetImageUrl: args.targetImageUrl,
            targetPhone: args.targetPhone,
          ),
        ) {
    loadReasons();
  }

  final ReportRepository _repository;

  Future<void> loadReasons() async {
    emit(state.copyWith(reasonsLoading: true, reasonsError: null));
    try {
      final categories = await _repository.getReportReasons();
      emit(
        state.copyWith(reasonCategories: categories, reasonsLoading: false),
      );
    } catch (e) {
      emit(state.copyWith(reasonsLoading: false, reasonsError: e.toString()));
    }
  }

  void selectTargetType(ReportTargetType type) {
    emit(state.copyWith(targetType: type));
    goNext();
  }

  void selectTarget({
    String? orderId,
    String? targetId,
    required String targetName,
    String? targetImageUrl,
    String? targetPhone,
  }) {
    emit(
      state.copyWith(
        orderId: orderId,
        targetId: targetId,
        targetName: targetName,
        targetImageUrl: targetImageUrl,
        targetPhone: targetPhone,
      ),
    );
    goNext();
  }

  void selectReason({required String code, required String label}) {
    emit(state.copyWith(reasonCode: code, reasonLabel: label));
  }

  void updateDescription(String value) =>
      emit(state.copyWith(description: value));

  /// The backend rejects report attachments over 5MB — tighter than
  /// [ImageCompressionUtils.defaultMaxBytes], so it's passed explicitly here.
  static const _maxAttachmentBytes = 5 * 1024 * 1024;

  Future<void> addPhotos(List<File> files) async {
    final compressed = await Future.wait(
      files.map(
        (f) => ImageCompressionUtils.compressIfNeeded(
          f,
          maxBytes: _maxAttachmentBytes,
        ),
      ),
    );
    emit(state.copyWith(photos: [...state.photos, ...compressed]));
  }

  void removePhoto(int index) {
    final updated = [...state.photos]..removeAt(index);
    emit(state.copyWith(photos: updated));
  }

  void goNext() {
    if (!state.isLastStep) {
      emit(state.copyWith(stepIndex: state.stepIndex + 1));
    }
  }

  void goBack() {
    if (!state.isFirstStep) {
      emit(state.copyWith(stepIndex: state.stepIndex - 1));
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(
      state.copyWith(
        submitStatus: ReportSubmitStatus.submitting,
        errorMessage: null,
      ),
    );
    try {
      final report = await _repository.submitReport(
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
      emit(
        state.copyWith(
          submitStatus: ReportSubmitStatus.success,
          submittedReport: report,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: ReportSubmitStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
