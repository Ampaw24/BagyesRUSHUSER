/// Represents the steps in the vendor registration wizard
enum VendorRegistrationStep {
  businessDetails('Business Details', 'Tell us about your business'),
  operationalDetails('Operations', 'Set up your operations'),
  createPassword('Create Password', 'Secure your vendor account'),
  verifySubmit('Verify & Submit', 'Verify your number and go live');

  const VendorRegistrationStep(this.title, this.subtitle);

  final String title;
  final String subtitle;

  static int get totalSteps => VendorRegistrationStep.values.length;

  VendorRegistrationStep? get next {
    final nextIndex = index + 1;
    if (nextIndex >= totalSteps) return null;
    return VendorRegistrationStep.values[nextIndex];
  }

  VendorRegistrationStep? get previous {
    final prevIndex = index - 1;
    if (prevIndex < 0) return null;
    return VendorRegistrationStep.values[prevIndex];
  }
}

/// Status of the registration process
enum VendorRegistrationStatus {
  idle,
  loading,
  validating,
  submitting,
  otpSent,
  otpVerified,
  complete,
  submitted,
  error,
}
