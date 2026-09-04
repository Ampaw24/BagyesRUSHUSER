import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/image_compression_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/repository/report_repository.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';

/// The steps of the report wizard, in order. A given run only shows a
/// subset of these — [ReportFormState.steps] holds the filtered sequence.
enum ReportWizardStep { targetType, target, reason, details }

enum ReportSubmitStatus { idle, submitting, success, error }

class ReportFormState extends Equatable {
  final ReportRole role;
  final List<ReportWizardStep> steps;
  final int stepIndex;

  final ReportTargetType? targetType;
  final String? orderId;
  final String? targetId;
  final String? targetName;
  final String? targetImageUrl;
  final String? targetPhone;

  final String? reasonCode;
  final String? reasonLabel;
  final bool reasonIsUrgent;

  final String description;
  final List<File> photos;

  final ReportSubmitStatus submitStatus;
  final String? errorMessage;
  final Report? submittedReport;

  const ReportFormState({
    required this.role,
    required this.steps,
    this.stepIndex = 0,
    this.targetType,
    this.orderId,
    this.targetId,
    this.targetName,
    this.targetImageUrl,
    this.targetPhone,
    this.reasonCode,
    this.reasonLabel,
    this.reasonIsUrgent = false,
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
      steps: [
        if (targetType == null) ReportWizardStep.targetType,
        if (!hasTarget) ReportWizardStep.target,
        ReportWizardStep.reason,
        ReportWizardStep.details,
      ],
      targetType: targetType,
      orderId: orderId,
      targetId: targetId,
      targetName: targetName,
      targetImageUrl: targetImageUrl,
      targetPhone: targetPhone,
    );
  }

  ReportWizardStep get currentStep => steps[stepIndex];
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => stepIndex == steps.length - 1;
  double get progress => (stepIndex + 1) / steps.length;

  bool get hasTarget => targetName != null && targetName!.isNotEmpty;
  bool get hasReason => reasonCode != null;
  bool get canSubmit =>
      targetType != null &&
      hasTarget &&
      hasReason &&
      description.trim().length >= 10;

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
    bool? reasonIsUrgent,
    String? description,
    List<File>? photos,
    ReportSubmitStatus? submitStatus,
    String? errorMessage,
    Report? submittedReport,
  }) {
    return ReportFormState(
      role: role,
      steps: steps,
      stepIndex: stepIndex ?? this.stepIndex,
      targetType: targetType ?? this.targetType,
      orderId: orderId ?? this.orderId,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      targetImageUrl: targetImageUrl ?? this.targetImageUrl,
      targetPhone: targetPhone ?? this.targetPhone,
      reasonCode: reasonCode ?? this.reasonCode,
      reasonLabel: reasonLabel ?? this.reasonLabel,
      reasonIsUrgent: reasonIsUrgent ?? this.reasonIsUrgent,
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
        steps,
        stepIndex,
        targetType,
        orderId,
        targetId,
        targetName,
        targetImageUrl,
        targetPhone,
        reasonCode,
        reasonLabel,
        reasonIsUrgent,
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
        );

  final ReportRepository _repository;

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

  void selectReason({
    required String code,
    required String label,
    bool isUrgent = false,
  }) {
    emit(
      state.copyWith(
        reasonCode: code,
        reasonLabel: label,
        reasonIsUrgent: isUrgent,
      ),
    );
  }

  void updateDescription(String value) =>
      emit(state.copyWith(description: value));

  Future<void> addPhotos(List<File> files) async {
    final compressed = await Future.wait(
      files.map((f) => ImageCompressionUtils.compressIfNeeded(f)),
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
