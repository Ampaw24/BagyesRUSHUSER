import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/utils/json_utils.dart';

/// Result of `GET /customer/wallet` — richer than `PaymentWallet`
/// (`/payments/wallet`): splits the balance into a withdrawable slice and a
/// spend-only slice, and carries payout eligibility flags so the UI doesn't
/// have to re-derive them from `balance` alone.
class CustomerWalletModel extends Equatable {
  const CustomerWalletModel({
    required this.balance,
    required this.currency,
    required this.withdrawable,
    required this.spendableOnly,
    required this.lifetimeEarned,
    required this.lifetimeWithdrawn,
    required this.pendingEarnings,
    required this.pendingWithdrawal,
    required this.minimumWithdrawal,
    required this.canWithdraw,
    required this.hasPayoutDetails,
    required this.withdrawalsEnabled,
  });

  final double balance;
  final String currency;
  final double withdrawable;
  final double spendableOnly;
  final double lifetimeEarned;
  final double lifetimeWithdrawn;
  final double pendingEarnings;
  final double pendingWithdrawal;
  final double minimumWithdrawal;
  final bool canWithdraw;
  final bool hasPayoutDetails;
  final bool withdrawalsEnabled;

  String get formattedBalance => '$currency ${balance.toStringAsFixed(2)}';
  String get formattedWithdrawable => '$currency ${withdrawable.toStringAsFixed(2)}';

  factory CustomerWalletModel.fromJson(Map<String, dynamic> json) {
    return CustomerWalletModel(
      balance: JsonUtils.asDouble(json['balance']),
      currency: JsonUtils.asString(json['currency'], 'GHS'),
      withdrawable: JsonUtils.asDouble(json['withdrawable']),
      spendableOnly: JsonUtils.asDouble(json['spendable_only']),
      lifetimeEarned: JsonUtils.asDouble(json['lifetime_earned']),
      lifetimeWithdrawn: JsonUtils.asDouble(json['lifetime_withdrawn']),
      pendingEarnings: JsonUtils.asDouble(json['pending_earnings']),
      pendingWithdrawal: JsonUtils.asDouble(json['pending_withdrawal']),
      minimumWithdrawal: JsonUtils.asDouble(json['minimum_withdrawal']),
      canWithdraw: JsonUtils.asBool(json['can_withdraw']),
      hasPayoutDetails: JsonUtils.asBool(json['has_payout_details']),
      withdrawalsEnabled: JsonUtils.asBool(json['withdrawals_enabled']),
    );
  }

  @override
  List<Object?> get props => [
    balance,
    currency,
    withdrawable,
    spendableOnly,
    lifetimeEarned,
    lifetimeWithdrawn,
    pendingEarnings,
    pendingWithdrawal,
    minimumWithdrawal,
    canWithdraw,
    hasPayoutDetails,
    withdrawalsEnabled,
  ];
}
