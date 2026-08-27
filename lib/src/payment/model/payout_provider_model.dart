import 'package:equatable/equatable.dart';

/// A bank or mobile-money payout provider fetched from `GET /payout-providers`.
class PayoutProviderModel extends Equatable {
  const PayoutProviderModel({
    required this.id,
    required this.type,
    required this.name,
    required this.shortName,
    required this.slug,
    this.code,
    this.logoUrl,
    this.isActive = true,
    this.displayOrder = 0,
  });

  final int id;
  final String type;
  final String name;
  final String shortName;
  final String slug;
  final String? code;
  final String? logoUrl;
  final bool isActive;
  final int displayOrder;

  bool get isBank => type == 'bank';
  bool get isMobileMoney => type == 'mobile_money';

  factory PayoutProviderModel.fromJson(Map<String, dynamic> json) {
    return PayoutProviderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      code: json['code']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'short_name': shortName,
        'slug': slug,
        'code': code,
        'logo_url': logoUrl,
        'is_active': isActive,
        'display_order': displayOrder,
      };

  @override
  List<Object?> get props => [
        id,
        type,
        name,
        shortName,
        slug,
        code,
        logoUrl,
        isActive,
        displayOrder,
      ];
}
