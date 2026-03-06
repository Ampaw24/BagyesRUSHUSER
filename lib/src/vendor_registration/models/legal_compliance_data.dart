import 'package:equatable/equatable.dart';

/// Data model for Step 2 - Legal & Compliance
class LegalComplianceData extends Equatable {
  final String? businessRegistrationCertPath;
  final String? foodSafetyLicensePath;
  final String? ownerIdPath;
  final String? taxIdentificationNumber;

  const LegalComplianceData({
    this.businessRegistrationCertPath,
    this.foodSafetyLicensePath,
    this.ownerIdPath,
    this.taxIdentificationNumber,
  });

  LegalComplianceData copyWith({
    String? businessRegistrationCertPath,
    String? foodSafetyLicensePath,
    String? ownerIdPath,
    String? taxIdentificationNumber,
  }) {
    return LegalComplianceData(
      businessRegistrationCertPath:
          businessRegistrationCertPath ?? this.businessRegistrationCertPath,
      foodSafetyLicensePath:
          foodSafetyLicensePath ?? this.foodSafetyLicensePath,
      ownerIdPath: ownerIdPath ?? this.ownerIdPath,
      taxIdentificationNumber:
          taxIdentificationNumber ?? this.taxIdentificationNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_registration_cert': businessRegistrationCertPath,
      'food_safety_license': foodSafetyLicensePath,
      'owner_id': ownerIdPath,
      'tax_id': taxIdentificationNumber,
    };
  }

  @override
  List<Object?> get props => [
    businessRegistrationCertPath,
    foodSafetyLicensePath,
    ownerIdPath,
    taxIdentificationNumber,
  ];
}
