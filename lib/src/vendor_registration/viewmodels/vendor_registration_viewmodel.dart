import 'package:bagyesrushappusernew/constant/config.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/home/repositories/home_repository.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_enums.dart';
import '../models/business_details_data.dart';
import '../models/operational_details_data.dart';
import '../models/vendor_registration_state.dart';
import 'step_validator.dart';

/// Substrings from server error messages that indicate the phone/account
/// already exists. Matched case-insensitively.
const _kAlreadyExistsPatterns = [
  'already exists',
  'already registered',
  'phone already',
  'duplicate',
  'account exists',
];

/// ViewModel for managing the vendor registration wizard flow
class VendorRegistrationViewModel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  final StepValidator _validator;
  final AuthViewmodel _authViewmodel;
  final CurrentUserProvider _currentUserProvider;

  VendorRegistrationState _state = const VendorRegistrationState();
  VendorRegistrationState get state => _state;

  VendorRegistrationViewModel(
    this._homeRepository,
    this._validator,
    this._authViewmodel,
    this._currentUserProvider,
  ) {
    _authViewmodel.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authViewmodel.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // ── Auth state bridge ──

  void _onAuthStateChanged() {
    final authState = _authViewmodel.state;

    if (authState is VendorRegistered) {
      // Scrub credentials now that registration succeeded.
      _state = _state.copyWith(
        businessDetails: _state.businessDetails.copyWith(
          password: '',
          confirmPassword: '',
        ),
      );
      // Backend returns the user — check phoneVerified to decide next step.
      final user = _currentUserProvider.user;
      if (user != null && user.phoneVerified) {
        // Already verified (edge case) — go straight to success.
        _state = _state.copyWith(
          status: VendorRegistrationStatus.complete,
          isOtpVerified: true,
        );
        notifyListeners();
      } else {
        // Normal path — go to OTP step and auto-send the code immediately
        // so the user lands straight on the input fields, not a button screen.
        _state = _state.copyWith(
          status: VendorRegistrationStatus.loading,
          currentStep: VendorRegistrationStep.verifySubmit,
          errorMessage: null,
        );
        notifyListeners();
        _authViewmodel.resetState();
        _authViewmodel.sendOtp('${Config.defaultCountryCode}${_state.businessDetails.phone}');
        return;
      }
      _authViewmodel.resetState();
    } else if (authState is OTPSent) {
      _state = _state.copyWith(
        status: VendorRegistrationStatus.otpSent,
        isOtpSent: true,
      );
      notifyListeners();
      _authViewmodel.resetState();
    } else if (authState is OTPVerified) {
      _state = _state.copyWith(
        status: VendorRegistrationStatus.complete,
        isOtpVerified: true,
      );
      notifyListeners();
      _authViewmodel.resetState();
    } else if (authState is AuthError) {
      // Detect "phone already exists / already registered" — resume path.
      final msg = authState.message.toLowerCase();
      final isAlreadyExists = _kAlreadyExistsPatterns.any(msg.contains);

      if (isAlreadyExists && _state.currentStep == VendorRegistrationStep.createPassword) {
        // Account exists but phone is unverified. Skip re-registration,
        // jump to OTP and send the code immediately.
        _state = _state.copyWith(
          status: VendorRegistrationStatus.loading,
          isResumeFlow: true,
          errorMessage: null,
          currentStep: VendorRegistrationStep.verifySubmit,
          businessDetails: _state.businessDetails.copyWith(
            password: '',
            confirmPassword: '',
          ),
        );
        notifyListeners();
        _authViewmodel.resetState();
        // Kick off OTP send — result handled by next _onAuthStateChanged cycle.
        _authViewmodel.sendOtp('${Config.defaultCountryCode}${_state.businessDetails.phone}');
      } else {
        _state = _state.copyWith(
          status: VendorRegistrationStatus.error,
          errorMessage: authState.message,
        );
        notifyListeners();
        _authViewmodel.resetState();
      }
    } else if (authState is BusinessTypesFetched) {
      _state = _state.copyWith(
        isBusinessTypesLoading: false,
        availableBusinessTypes:
            authState.businessTypes.where((t) => t.isActive).toList(),
      );
      notifyListeners();
      _authViewmodel.resetState();
    }
  }

  Future<void> loadBusinessTypes() async {
    _state = _state.copyWith(
      isBusinessTypesLoading: true,
      businessTypesError: null,
    );
    notifyListeners();

    await _authViewmodel.fetchBusinessTypes();
    // Result handled in _onAuthStateChanged
  }

  // ── Cuisine Types (fetched from API) ──

  Future<void> loadCuisineTypes() async {
    _state = _state.copyWith(isCategoriesLoading: true, categoriesError: null);
    notifyListeners();

    final result = await _homeRepository.getCategories();

    result.fold(
      (failure) {
        _state = _state.copyWith(
          isCategoriesLoading: false,
          categoriesError: failure.message,
        );
      },
      (categories) {
        final flat = categories
            .expand((c) => c.categories)
            .where((c) => c.isActive)
            .toList();
        _state = _state.copyWith(
          isCategoriesLoading: false,
          availableCategories: flat,
        );
      },
    );

    notifyListeners();
  }

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

  /// Validates the current step and marks it complete without navigating.
  /// Returns true if valid, false (with errorMessage set) if not.
  bool validateAndMarkComplete() {
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
    _state = _state.copyWith(
      completedSteps: updatedCompleted,
      errorMessage: null,
    );
    notifyListeners();
    return true;
  }

  void setError(String message) {
    _state = _state.copyWith(
      status: VendorRegistrationStatus.error,
      errorMessage: message,
    );
    notifyListeners();
  }

  /// Resets status back to idle after the View has handled a terminal state
  /// (e.g. `complete` → showed success dialog).
  void resetStatus() {
    _state = _state.copyWith(status: VendorRegistrationStatus.idle);
    notifyListeners();
  }

  // ── Step 1 & 2: Business Details / Password ──

  void updateBusinessDetails(BusinessDetailsData data) {
    _state = _state.copyWith(businessDetails: data);
    notifyListeners();
  }

  // ── Step 3: Operational Details ──

  void updateOperationalDetails(OperationalDetailsData data) {
    _state = _state.copyWith(operationalDetails: data);
    notifyListeners();
  }

  // ── Submit (Step 2 → triggers vendorRegister via AuthViewmodel) ──

  /// Validates the password step, then calls `AuthViewmodel.vendorRegister`.
  /// The result is handled asynchronously via `_onAuthStateChanged`.
  Future<void> submitRegistration() async {
    if (!validateAndMarkComplete()) return;

    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();

    final b = _state.businessDetails;
    final o = _state.operationalDetails;

    // The phone field stores bare digits (e.g. 544548232) with the country
    // code shown only as a UI prefix. Prepend it before sending to the server
    // which expects the full E.164 form (+233544548232).
    final fullPhone = '${Config.defaultCountryCode}${b.phone}';

    await _authViewmodel.vendorRegister(
      email: b.email,
      phone: fullPhone,
      password: b.password,
      confirmPassword: b.confirmPassword,
      
      businessName: b.businessName,
      businessTypeID: b.businessType?.id ?? '',
      contactPersonName: b.contactPersonName,
      businessAddress: b.businessAddress,
      city: b.city,
      description: b.description ?? '',
      taxIdentificationNumber: b.taxIdentificationNumber ?? '',
      cuisineTypes: o.cuisineTypes,
      deliveryRadiusKm: o.deliveryRadiusKm,
      openingTime: o.openingTime,
      closingTime: o.closingTime,
      operatingDays: o.operatingDays.map((d) => d.toLowerCase()).toList(),
      estimatedPrepTimeMinutes: o.estimatedPrepTimeMinutes,
    );

    // Credentials are scrubbed in _onAuthStateChanged once the outcome is known
    // (success → VendorRegistered, resume → isAlreadyExists branch).
    // Scrubbing here unconditionally caused retries to fail validation because
    // the state had an empty password before the field's focus listener could
    // re-emit the controller value.
    // Result handled by _onAuthStateChanged
  }

  // ── OTP (Step 4 / verifySubmit) ──

  Future<void> sendOtp() async {
    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();
    final fullPhone = '${Config.defaultCountryCode}${_state.businessDetails.phone}';
    await _authViewmodel.sendOtp(fullPhone);
    // Result (OTPSent / AuthError) handled by _onAuthStateChanged
  }

  Future<void> verifyOtp(String otp) async {
    _state = _state.copyWith(status: VendorRegistrationStatus.loading);
    notifyListeners();
    final fullPhone = '${Config.defaultCountryCode}${_state.businessDetails.phone}';
    await _authViewmodel.verifyOtp(
      phone: fullPhone,
      otp: otp,
    );
    // Result (OTPVerified / AuthError) handled by _onAuthStateChanged
  }

  /// Reset the entire registration flow
  void reset() {
    _state = const VendorRegistrationState();
    notifyListeners();
  }
}
