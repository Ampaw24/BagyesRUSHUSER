import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';

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
