import 'package:equatable/equatable.dart';
import 'payout_provider_model.dart';

/// A saved payout/payment method (mobile money account) belonging to
/// either a customer or a vendor.
class PaymentMethod extends Equatable {
  const PaymentMethod({
    required this.id,
    required this.payoutProviderId,
    required this.phoneNumber,
    required this.isDefault,
    this.label,
    this.provider,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int payoutProviderId;
  final String phoneNumber;
  final bool isDefault;
  final String? label;
  /// The full provider record, when the API embeds it inline
  /// (`payout_provider`) alongside `payout_provider_id`.
  final PayoutProviderModel? provider;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayTitle {
    if (label != null && label!.trim().isNotEmpty) return label!;
    return provider?.name ?? 'Mobile Money';
  }

  /// Masked for display: +233 *** *** 567
  String get maskedPhone {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phoneNumber;
    final last3 = digits.substring(digits.length - 3);
    if (digits.length >= 12) {
      final cc = '+${digits.substring(0, 3)}';
      return '$cc *** *** $last3';
    }
    return '*** *** $last3';
  }

  PaymentMethod copyWith({
    String? id,
    int? payoutProviderId,
    String? phoneNumber,
    bool? isDefault,
    String? label,
    PayoutProviderModel? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      payoutProviderId: payoutProviderId ?? this.payoutProviderId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final providerJson = json['payout_provider'];
    final provider = providerJson is Map
        ? PayoutProviderModel.fromJson(Map<String, dynamic>.from(providerJson))
        : null;
    final providerId = (json['payout_provider_id'] as num?)?.toInt() ?? provider?.id;

    return PaymentMethod(
      id: (json['id'] ?? '').toString(),
      payoutProviderId: providerId ?? 0,
      phoneNumber: json['phone_number']?.toString() ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      label: json['label']?.toString(),
      provider: provider,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payout_provider_id': payoutProviderId,
        'phone_number': phoneNumber,
        'is_default': isDefault,
        'label': label,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        payoutProviderId,
        phoneNumber,
        isDefault,
        label,
        provider,
        createdAt,
        updatedAt,
      ];
}
