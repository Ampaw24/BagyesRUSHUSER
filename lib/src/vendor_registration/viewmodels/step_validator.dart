import '../models/vendor_enums.dart';
import '../models/vendor_registration_state.dart';

/// Single responsibility: validates each step's data
class StepValidator {
  /// Returns null if valid, or an error message if invalid
  String? validate(VendorRegistrationStep step, VendorRegistrationState state) {
    switch (step) {
      case VendorRegistrationStep.businessDetails:
        return _validateBusinessDetails(state);
      case VendorRegistrationStep.legalCompliance:
        return _validateLegalCompliance(state);
      case VendorRegistrationStep.operationalDetails:
        return _validateOperationalDetails(state);
      case VendorRegistrationStep.payoutDetails:
        return _validatePayoutDetails(state);
      case VendorRegistrationStep.verification:
        return _validateVerification(state);
      case VendorRegistrationStep.reviewSubmit:
        return null;
    }
  }

  String? _validateBusinessDetails(VendorRegistrationState state) {
    final data = state.businessDetails;
    if (data.businessName.trim().isEmpty) {
      return 'Business name is required';
    }
    if (data.businessType == null) {
      return 'Please select a business type';
    }
    if (data.contactPersonName.trim().isEmpty) {
      return 'Contact person name is required';
    }
    if (data.phone.trim().length < 9) {
      return 'Please enter a valid phone number';
    }
    if (data.email.trim().isEmpty || !data.email.contains('@')) {
      return 'Please enter a valid email address';
    }
    if (data.businessAddress.trim().isEmpty) {
      return 'Business address is required';
    }
    if (data.city.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? _validateLegalCompliance(VendorRegistrationState state) {
    final data = state.legalCompliance;
    if (data.ownerIdPath == null || data.ownerIdPath!.isEmpty) {
      return 'Owner ID document is required';
    }
    return null;
  }

  String? _validateOperationalDetails(VendorRegistrationState state) {
    final data = state.operationalDetails;
    if (data.cuisineTypes.isEmpty) {
      return 'Please select at least one cuisine type';
    }
    if (data.operatingDays.isEmpty) {
      return 'Please select at least one operating day';
    }
    return null;
  }

  String? _validatePayoutDetails(VendorRegistrationState state) {
    final data = state.payoutDetails;
    final hasBankDetails = data.bankName.trim().isNotEmpty &&
        data.accountNumber.trim().isNotEmpty &&
        data.accountName.trim().isNotEmpty;
    final hasMobileMoney = data.mobileMoneyNumber != null &&
        data.mobileMoneyNumber!.trim().isNotEmpty &&
        data.mobileMoneyProvider != null &&
        data.mobileMoneyProvider!.trim().isNotEmpty;

    if (!hasBankDetails && !hasMobileMoney) {
      return 'Please provide bank details or mobile money info';
    }
    return null;
  }

  String? _validateVerification(VendorRegistrationState state) {
    if (!state.isOtpVerified) {
      return 'Please verify your phone number';
    }
    return null;
  }
}
