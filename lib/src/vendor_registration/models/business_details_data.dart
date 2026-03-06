import 'package:equatable/equatable.dart';
import 'vendor_enums.dart';

/// Data model for Step 1 - Business Details
class BusinessDetailsData extends Equatable {
  final String businessName;
  final BusinessType? businessType;
  final String contactPersonName;
  final String phone;
  final String email;
  final String businessAddress;
  final String city;
  final String? description;

  const BusinessDetailsData({
    this.businessName = '',
    this.businessType,
    this.contactPersonName = '',
    this.phone = '',
    this.email = '',
    this.businessAddress = '',
    this.city = '',
    this.description,
  });

  BusinessDetailsData copyWith({
    String? businessName,
    BusinessType? businessType,
    String? contactPersonName,
    String? phone,
    String? email,
    String? businessAddress,
    String? city,
    String? description,
  }) {
    return BusinessDetailsData(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'business_type': businessType?.name,
      'contact_person': contactPersonName,
      'phone': phone,
      'email': email,
      'address': businessAddress,
      'city': city,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
    businessName,
    businessType,
    contactPersonName,
    phone,
    email,
    businessAddress,
    city,
    description,
  ];
}
