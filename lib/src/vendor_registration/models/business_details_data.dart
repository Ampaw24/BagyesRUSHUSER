import 'package:bagyesrushappusernew/src/auth/models/business_type_model.dart';
import 'package:equatable/equatable.dart';

/// Data model for Step 1 - Business Details
class BusinessDetailsData extends Equatable {
  final String businessName;
  final BusinessTypeModel? businessType;
  final String contactPersonName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final String businessAddress;
  // Populated by the map location picker (KYC-grade geo-pin, not derived
  // from free-text geocoding) — required by the backend's PostGIS
  // `ST_DWithin` nearby-vendor queries and delivery-radius calculations.
  final double? businessLatitude;
  final double? businessLongitude;
  final String city;
  final String? description;
  final String? taxIdentificationNumber;

  const BusinessDetailsData({
    this.businessName = '',
    this.businessType,
    this.contactPersonName = '',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.businessAddress = '',
    this.businessLatitude,
    this.businessLongitude,
    this.city = '',
    this.description,
    this.taxIdentificationNumber,
  });

  BusinessDetailsData copyWith({
    String? businessName,
    BusinessTypeModel? businessType,
    String? contactPersonName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    String? businessAddress,
    double? businessLatitude,
    double? businessLongitude,
    String? city,
    String? description,
    String? taxIdentificationNumber,
  }) {
    return BusinessDetailsData(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLatitude: businessLatitude ?? this.businessLatitude,
      businessLongitude: businessLongitude ?? this.businessLongitude,
      city: city ?? this.city,
      description: description ?? this.description,
      taxIdentificationNumber:
          taxIdentificationNumber ?? this.taxIdentificationNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      // password and confirmPassword are intentionally excluded from toMap()
      // to prevent credentials appearing in logs, analytics, or crash reports.
      'role': 'vendor',
      'business_name': businessName,
      'business_type': businessType?.name,
      'contact_person_name': contactPersonName,
      'business_address': businessAddress,
      'latitude': businessLatitude,
      'longitude': businessLongitude,
      'city': city,
      'description': description,
      'tax_identification_number': taxIdentificationNumber,
    };
  }

  @override
  List<Object?> get props => [
    businessName,
    businessType,
    contactPersonName,
    phone,
    email,
    // password and confirmPassword excluded from props to prevent
    // credentials appearing in Equatable toString() output.
    businessAddress,
    businessLatitude,
    businessLongitude,
    city,
    description,
    taxIdentificationNumber,
  ];
}
