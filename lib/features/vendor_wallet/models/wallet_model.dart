import 'package:equatable/equatable.dart';

/// Snapshot of the vendor's wallet balances.
class WalletModel extends Equatable {
  final String currency;

  /// Funds ready to withdraw.
  final double availableBalance;

  /// Earnings being processed (e.g. orders not yet settled).
  final double pendingBalance;

  /// Lifetime earnings credited to this wallet.
  final double totalEarnings;

  /// Lifetime amount successfully withdrawn.
  final double totalWithdrawn;

  const WalletModel({
    this.currency = 'GH₵',
    this.availableBalance = 0,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalWithdrawn = 0,
  });

  double get totalBalance => availableBalance + pendingBalance;

  String fmt(double amount) =>
      '$currency ${amount.toStringAsFixed(2)}';

  String get availableFormatted => fmt(availableBalance);
  String get pendingFormatted   => fmt(pendingBalance);
  String get totalFormatted     => fmt(totalBalance);
  String get earningsFormatted  => fmt(totalEarnings);
  String get withdrawnFormatted => fmt(totalWithdrawn);

  WalletModel copyWith({
    String? currency,
    double? availableBalance,
    double? pendingBalance,
    double? totalEarnings,
    double? totalWithdrawn,
  }) {
    return WalletModel(
      currency: currency ?? this.currency,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        currency: json['currency'] as String? ?? 'GH₵',
        availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0,
        pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0,
        totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
        totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [
        currency,
        availableBalance,
        pendingBalance,
        totalEarnings,
        totalWithdrawn,
      ];
}
