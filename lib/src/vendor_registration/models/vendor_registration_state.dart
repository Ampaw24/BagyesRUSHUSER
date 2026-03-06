import 'package:equatable/equatable.dart';

import 'vendor_enums.dart';
import 'business_details_data.dart';
import 'legal_compliance_data.dart';
import 'operational_details_data.dart';
import 'payout_details_data.dart';

/// Overall state of the vendor registration flow
class VendorRegistrationState extends Equatable {
  final VendorRegistrationStep currentStep;
  final VendorRegistrationStatus status;
  final BusinessDetailsData businessDetails;
  final LegalComplianceData legalCompliance;
  final OperationalDetailsData operationalDetails;
  final PayoutDetailsData payoutDetails;
  final String? otpCode;
  final bool isOtpVerified;
  final String? errorMessage;
  final Map<VendorRegistrationStep, bool> completedSteps;

  const VendorRegistrationState({
    this.currentStep = VendorRegistrationStep.businessDetails,
    this.status = VendorRegistrationStatus.idle,
    this.businessDetails = const BusinessDetailsData(),
    this.legalCompliance = const LegalComplianceData(),
    this.operationalDetails = const OperationalDetailsData(),
    this.payoutDetails = const PayoutDetailsData(),
    this.otpCode,
    this.isOtpVerified = false,
    this.errorMessage,
    this.completedSteps = const {},
  });

  double get progress =>
      (currentStep.index + 1) / VendorRegistrationStep.totalSteps;

  bool get canGoBack => currentStep.previous != null;

  bool get canGoForward => currentStep.next != null;

  VendorRegistrationState copyWith({
    VendorRegistrationStep? currentStep,
    VendorRegistrationStatus? status,
    BusinessDetailsData? businessDetails,
    LegalComplianceData? legalCompliance,
    OperationalDetailsData? operationalDetails,
    PayoutDetailsData? payoutDetails,
    String? otpCode,
    bool? isOtpVerified,
    String? errorMessage,
    Map<VendorRegistrationStep, bool>? completedSteps,
  }) {
    return VendorRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      businessDetails: businessDetails ?? this.businessDetails,
      legalCompliance: legalCompliance ?? this.legalCompliance,
      operationalDetails: operationalDetails ?? this.operationalDetails,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      otpCode: otpCode ?? this.otpCode,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      errorMessage: errorMessage,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  /// Combine all step data for API submission
  Map<String, dynamic> toSubmissionData() {
    return {
      ...businessDetails.toMap(),
      ...legalCompliance.toMap(),
      ...operationalDetails.toMap(),
      ...payoutDetails.toMap(),
    };
  }

  @override
  List<Object?> get props => [
    currentStep,
    status,
    businessDetails,
    legalCompliance,
    operationalDetails,
    payoutDetails,
    otpCode,
    isOtpVerified,
    errorMessage,
    completedSteps,
  ];
}
