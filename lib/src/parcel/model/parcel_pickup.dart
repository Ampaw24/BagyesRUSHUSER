import 'package:equatable/equatable.dart';

/// Nested `pickup` block of a parcel. For `receive` parcels it carries the
/// collection code the pickup contact gives the rider.
class ParcelPickup extends Equatable {
  const ParcelPickup({
    required this.address,
    this.contactName,
    this.contactPhone,
    this.requiresCode = false,
    this.code,
    this.codeNotifiedAt,
    this.codeVerifiedAt,
    this.collectionFailedAt,
    this.collectionFailureReason,
  });

  final String address;
  final String? contactName;
  final String? contactPhone;
  final bool requiresCode;
  final String? code;
  final DateTime? codeNotifiedAt;
  final DateTime? codeVerifiedAt;
  final DateTime? collectionFailedAt;
  final String? collectionFailureReason;

  bool get isCodeVerified => codeVerifiedAt != null;
  bool get hasCollectionFailed => collectionFailedAt != null;

  factory ParcelPickup.fromJson(Map<String, dynamic> json) => ParcelPickup(
        address: json['address']?.toString() ?? '',
        contactName: json['contact_name']?.toString(),
        contactPhone: json['contact_phone']?.toString(),
        requiresCode: json['requires_code'] == true,
        code: json['code']?.toString(),
        codeNotifiedAt: _date(json['code_notified_at']),
        codeVerifiedAt: _date(json['code_verified_at']),
        collectionFailedAt: _date(json['collection_failed_at']),
        collectionFailureReason: json['collection_failure_reason']?.toString(),
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  @override
  List<Object?> get props => [
        address,
        contactName,
        contactPhone,
        requiresCode,
        code,
        codeNotifiedAt,
        codeVerifiedAt,
        collectionFailedAt,
        collectionFailureReason,
      ];
}
