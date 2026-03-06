/// Represents the steps in the vendor registration wizard
enum VendorRegistrationStep {
  businessDetails('Business Details', 'Tell us about your business'),
  legalCompliance('Legal & Compliance', 'Upload required documents'),
  operationalDetails('Operations', 'Set up your operations'),
  payoutDetails('Payout Details', 'How you get paid'),
  verification('Verification', 'Verify your contact'),
  reviewSubmit('Review & Submit', 'Confirm your details');

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
  submitted,
  error,
}

/// Cuisine type options
enum CuisineType {
  local('Local / Traditional'),
  continental('Continental'),
  chinese('Chinese'),
  indian('Indian'),
  fastFood('Fast Food'),
  bakery('Bakery & Pastries'),
  beverages('Beverages'),
  seafood('Seafood'),
  vegan('Vegan / Vegetarian'),
  other('Other');

  const CuisineType(this.label);
  final String label;
}

/// Business type options
enum BusinessType {
  restaurant('Restaurant'),
  foodTruck('Food Truck'),
  cloudKitchen('Cloud Kitchen'),
  bakery('Bakery'),
  catering('Catering Service'),
  grocery('Grocery Store'),
  other('Other');

  const BusinessType(this.label);
  final String label;
}
