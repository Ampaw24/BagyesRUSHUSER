import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
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
  final bool isOtpSent;
  /// True when the user's account already exists but phone is unverified —
  /// the flow skips straight to OTP rather than re-registering.
  final bool isResumeFlow;
  final String? errorMessage;
  final Map<VendorRegistrationStep, bool> completedSteps;

  // Category state consolidated here (was scattered as separate VM fields)
  final List<CategoryElement> availableCategories;
  final bool isCategoriesLoading;
  final String? categoriesError;

  const VendorRegistrationState({
    this.currentStep = VendorRegistrationStep.businessDetails,
    this.status = VendorRegistrationStatus.idle,
    this.businessDetails = const BusinessDetailsData(),
    this.legalCompliance = const LegalComplianceData(),
    this.operationalDetails = const OperationalDetailsData(),
    this.payoutDetails = const PayoutDetailsData(),
    this.otpCode,
    this.isOtpVerified = false,
    this.isOtpSent = false,
    this.isResumeFlow = false,
    this.errorMessage,
    this.completedSteps = const {},
    this.availableCategories = const [],
    this.isCategoriesLoading = false,
    this.categoriesError,
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
    bool? isOtpSent,
    bool? isResumeFlow,
    String? errorMessage,
    Map<VendorRegistrationStep, bool>? completedSteps,
    List<CategoryElement>? availableCategories,
    bool? isCategoriesLoading,
    String? categoriesError,
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
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isResumeFlow: isResumeFlow ?? this.isResumeFlow,
      errorMessage: errorMessage,
      completedSteps: completedSteps ?? this.completedSteps,
      availableCategories: availableCategories ?? this.availableCategories,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      categoriesError: categoriesError,
    );
  }

  /// Combine all step data for API submission
  Map<String, dynamic> toSubmissionData() {
    return {
      ...businessDetails.toMap(),
      ...operationalDetails.toMap(),
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
    isOtpSent,
    isResumeFlow,
    errorMessage,
    completedSteps,
    availableCategories,
    isCategoriesLoading,
    categoriesError,
  ];
}
