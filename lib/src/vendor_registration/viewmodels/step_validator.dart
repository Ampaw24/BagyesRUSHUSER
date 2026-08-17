import '../models/vendor_enums.dart';
import '../models/vendor_registration_state.dart';

/// Single responsibility: validates each step's data
class StepValidator {
  /// Returns null if valid, or an error message if invalid
  String? validate(VendorRegistrationStep step, VendorRegistrationState state) {
    switch (step) {
      case VendorRegistrationStep.businessDetails:
        return _validateBusinessDetails(state);
      case VendorRegistrationStep.createPassword:
        return _validateCreatePassword(state);
      case VendorRegistrationStep.operationalDetails:
        return _validateOperationalDetails(state);
      case VendorRegistrationStep.verifySubmit:
        return _validateVerification(state);
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
    final description = data.description?.trim() ?? '';
    if (description.isNotEmpty && description.length < 20) {
      return 'Business description must be at least 20 characters';
    }
    return null;
  }

  String? _validateCreatePassword(VendorRegistrationState state) {
    final data = state.businessDetails;
    if (data.password.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (data.password != data.confirmPassword) {
      return 'Passwords do not match';
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


  String? _validateVerification(VendorRegistrationState state) {
    if (!state.isOtpVerified) {
      return 'Please verify your phone number';
    }
    return null;
  }
}
