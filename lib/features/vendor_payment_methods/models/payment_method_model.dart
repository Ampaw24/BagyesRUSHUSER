import 'package:equatable/equatable.dart';
import 'mobile_money_model.dart';
import 'visa_card_model.dart';

/// The type of payment method.
enum PaymentMethodType { mobileMoney, visaCard }

/// Verification/activation status of a payment method.
enum PaymentMethodStatus { pending, verified, disabled }

/// Unified payment method model used throughout the feature.
/// Uses a sealed-style approach: only one of [mobileMoney] or [visaCard]
/// will be non-null, determined by [type].
class PaymentMethodModel extends Equatable {
  final String id;
  final PaymentMethodType type;
  final PaymentMethodStatus status;
  final bool isDefault;
  final bool isEnabled;
  final DateTime createdAt;

  // Type-specific payloads — exactly one will be populated
  final MobileMoneyModel? mobileMoney;
  final VisaCardModel? visaCard;

  const PaymentMethodModel({
    required this.id,
    required this.type,
    required this.status,
    required this.isDefault,
    required this.isEnabled,
    required this.createdAt,
    this.mobileMoney,
    this.visaCard,
  });

  // ── Derived helpers ────────────────────────────────────────────────────

  /// Human-readable display title (e.g. "MTN Mobile Money", "Visa ••••4242").
  String get displayTitle {
    switch (type) {
      case PaymentMethodType.mobileMoney:
        return mobileMoney?.provider.displayName ?? 'Mobile Money';
      case PaymentMethodType.visaCard:
        final card = visaCard;
        if (card == null) return 'Visa Card';
        return '${card.brand.displayName} ••••${card.cardLast4}';
    }
  }

  /// Masked secondary label (phone or expiry).
  String get displaySubtitle {
    switch (type) {
      case PaymentMethodType.mobileMoney:
        return mobileMoney?.maskedPhone ?? '';
      case PaymentMethodType.visaCard:
        final card = visaCard;
        if (card == null) return '';
        return 'Expires ${card.expiryMonth}/${card.expiryYear}';
    }
  }

  bool get isVerified => status == PaymentMethodStatus.verified;

  // ── copyWith ───────────────────────────────────────────────────────────

  PaymentMethodModel copyWith({
    String? id,
    PaymentMethodType? type,
    PaymentMethodStatus? status,
    bool? isDefault,
    bool? isEnabled,
    DateTime? createdAt,
    MobileMoneyModel? mobileMoney,
    VisaCardModel? visaCard,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      mobileMoney: mobileMoney ?? this.mobileMoney,
      visaCard: visaCard ?? this.visaCard,
    );
  }

  // ── JSON ───────────────────────────────────────────────────────────────

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'mobileMoney';
    final type = typeStr == 'visaCard'
        ? PaymentMethodType.visaCard
        : PaymentMethodType.mobileMoney;

    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'verified' => PaymentMethodStatus.verified,
      'disabled' => PaymentMethodStatus.disabled,
      _ => PaymentMethodStatus.pending,
    };

    return PaymentMethodModel(
      id: json['id'] as String? ?? '',
      type: type,
      status: status,
      isDefault: json['is_default'] as bool? ?? false,
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      mobileMoney: type == PaymentMethodType.mobileMoney && json['data'] != null
          ? MobileMoneyModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      visaCard: type == PaymentMethodType.visaCard && json['data'] != null
          ? VisaCardModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'is_default': isDefault,
        'is_enabled': isEnabled,
        'created_at': createdAt.toIso8601String(),
        'data': type == PaymentMethodType.mobileMoney
            ? mobileMoney?.toJson()
            : visaCard?.toJson(),
      };

  @override
  List<Object?> get props => [
        id,
        type,
        status,
        isDefault,
        isEnabled,
        createdAt,
        mobileMoney,
        visaCard,
      ];
}
