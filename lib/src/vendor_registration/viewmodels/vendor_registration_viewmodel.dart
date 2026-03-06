import 'package:flutter/foundation.dart';
import '../models/vendor_enums.dart';
import '../models/business_details_data.dart';
import '../models/legal_compliance_data.dart';
import '../models/operational_details_data.dart';
import '../models/payout_details_data.dart';
import '../models/vendor_registration_state.dart';
import '../repositories/vendor_repository.dart';
import 'step_validator.dart';

/// ViewModel for managing the vendor registration wizard flow
class VendorRegistrationViewModel extends ChangeNotifier {
  final VendorRepository _repository;
  final StepValidator _validator;

  VendorRegistrationState _state = const VendorRegistrationState();
  VendorRegistrationState get state => _state;

  VendorRegistrationViewModel(this._repository, this._validator);

  // ── Navigation ──

  void goToStep(VendorRegistrationStep step) {
    _state = _state.copyWith(currentStep: step, errorMessage: null);
    notifyListeners();
  }

  /// Validate current step and proceed to next
  bool nextStep() {
    final error = _validator.validate(_state.currentStep, _state);
    if (error != null) {
      _state = _state.copyWith(errorMessage: error);
      notifyListeners();
      return false;
    }

    final updatedCompleted = Map<VendorRegistrationStep, bool>.from(
      _state.completedSteps,
    );
    updatedCompleted[_state.currentStep] = true;

    final next = _state.currentStep.next;
    if (next != null) {
      _state = _state.copyWith(
        currentStep: next,
        completedSteps: updatedCompleted,
        errorMessage: null,
      );
      notifyListeners();
    }
    return true;
  }

  void previousStep() {
    final prev = _state.currentStep.previous;
    if (prev != null) {
      _state = _state.copyWith(currentStep: prev, errorMessage: null);
      notifyListeners();
    }
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }

  // ── Step 1: Business Details ──

  void updateBusinessDetails(BusinessDetailsData data) {
    _state = _state.copyWith(businessDetails: data);
    notifyListeners();
  }

  // ── Step 2: Legal & Compliance ──

  void updateLegalCompliance(LegalComplianceData data) {
    _state = _state.copyWith(legalCompliance: data);
    notifyListeners();
  }

  Future<void> uploadDocument(String filePath, String documentType) async {
    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();

    final result = await _repository.uploadDocument(filePath, documentType);
    result.fold(
      (failure) {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.error,
          errorMessage: failure.message,
        );
      },
      (url) {
        var updated = _state.legalCompliance;
        switch (documentType) {
          case 'business_registration':
            updated = updated.copyWith(businessRegistrationCertPath: url);
          case 'food_safety_license':
            updated = updated.copyWith(foodSafetyLicensePath: url);
          case 'owner_id':
            updated = updated.copyWith(ownerIdPath: url);
        }
        _state = _state.copyWith(
          status: VendorRegistrationStatus.idle,
          legalCompliance: updated,
        );
      },
    );
    notifyListeners();
  }

  // ── Step 3: Operational Details ──

  void updateOperationalDetails(OperationalDetailsData data) {
    _state = _state.copyWith(operationalDetails: data);
    notifyListeners();
  }

  // ── Step 4: Payout Details ──

  void updatePayoutDetails(PayoutDetailsData data) {
    _state = _state.copyWith(payoutDetails: data);
    notifyListeners();
  }

  // ── Step 5: Verification ──

  Future<void> sendOtp() async {
    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();

    final result = await _repository.sendVerificationOtp({
      'phone': _state.businessDetails.phone,
      'email': _state.businessDetails.email,
    });

    result.fold(
      (failure) {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        _state = _state.copyWith(status: VendorRegistrationStatus.otpSent);
      },
    );
    notifyListeners();
  }

  Future<void> verifyOtp(String code) async {
    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();

    final result = await _repository.verifyOtp({
      'phone': _state.businessDetails.phone,
      'otp': code,
    });

    result.fold(
      (failure) {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.error,
          errorMessage: failure.message,
        );
      },
      (_) {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.otpVerified,
          isOtpVerified: true,
        );
      },
    );
    notifyListeners();
  }

  // ── Step 6: Submit ──

  Future<bool> submitRegistration() async {
    _state = _state.copyWith(status: VendorRegistrationStatus.submitting);
    notifyListeners();

    final result = await _repository.submitRegistration(
      _state.toSubmissionData(),
    );

    return result.fold(
      (failure) {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.error,
          errorMessage: failure.message,
        );
        notifyListeners();
        return false;
      },
      (_) {
        _state = _state.copyWith(status: VendorRegistrationStatus.submitted);
        notifyListeners();
        return true;
      },
    );
  }

  /// Reset the entire registration flow
  void reset() {
    _state = const VendorRegistrationState();
    notifyListeners();
  }
}
