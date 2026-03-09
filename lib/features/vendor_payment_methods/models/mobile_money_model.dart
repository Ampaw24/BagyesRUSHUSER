import 'package:equatable/equatable.dart';

/// Supported mobile money providers.
enum MobileMoneyProvider {
  mtnMomo,
  vodafoneCash,
  airtelTigo;

  String get displayName => switch (this) {
        MobileMoneyProvider.mtnMomo => 'MTN Mobile Money',
        MobileMoneyProvider.vodafoneCash => 'Vodafone Cash',
        MobileMoneyProvider.airtelTigo => 'AirtelTigo Money',
      };

  String get shortName => switch (this) {
        MobileMoneyProvider.mtnMomo => 'MTN',
        MobileMoneyProvider.vodafoneCash => 'Vodafone',
        MobileMoneyProvider.airtelTigo => 'AirtelTigo',
      };

  /// Expected dial prefix(es) for Ghana (country-code +233 stripped).
  List<String> get dialPrefixes => switch (this) {
        MobileMoneyProvider.mtnMomo => ['024', '054', '055', '059'],
        MobileMoneyProvider.vodafoneCash => ['020', '050'],
        MobileMoneyProvider.airtelTigo => ['026', '027', '056', '057'],
      };

  static MobileMoneyProvider fromString(String value) => switch (value) {
        'mtnMomo' => MobileMoneyProvider.mtnMomo,
        'vodafoneCash' => MobileMoneyProvider.vodafoneCash,
        'airtelTigo' => MobileMoneyProvider.airtelTigo,
        _ => MobileMoneyProvider.mtnMomo,
      };
}

/// Mobile money account data stored/displayed for a payment method.
class MobileMoneyModel extends Equatable {
  final MobileMoneyProvider provider;

  /// Full phone in E.164 format, e.g. "+233541234567".
  final String phoneNumber;
  final String accountName;

  const MobileMoneyModel({
    required this.provider,
    required this.phoneNumber,
    required this.accountName,
  });

  /// Masked for display: +233 *** *** 567
  String get maskedPhone {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phoneNumber;
    final last3 = digits.substring(digits.length - 3);
    if (digits.length >= 12) {
      // E.164 with country code: +233 XX XXX XXXX
      final cc = '+${digits.substring(0, 3)}';
      return '$cc *** *** $last3';
    }
    return '*** *** $last3';
  }

  MobileMoneyModel copyWith({
    MobileMoneyProvider? provider,
    String? phoneNumber,
    String? accountName,
  }) {
    return MobileMoneyModel(
      provider: provider ?? this.provider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountName: accountName ?? this.accountName,
    );
  }

  factory MobileMoneyModel.fromJson(Map<String, dynamic> json) {
    return MobileMoneyModel(
      provider: MobileMoneyProvider.fromString(
        json['provider'] as String? ?? 'mtnMomo',
      ),
      phoneNumber: json['phone_number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'phone_number': phoneNumber,
        'account_name': accountName,
      };

  @override
  List<Object?> get props => [provider, phoneNumber, accountName];
}
