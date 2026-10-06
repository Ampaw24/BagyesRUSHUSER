import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'customer_wallet_model.dart';

/// Why a customer can't withdraw right now — drives the message shown when
/// they tap "Withdraw", instead of a silently dead button.
enum WithdrawBlock {
  /// The backend has withdrawals switched off.
  unavailable,

  /// The account has no payout details on file to send the money to.
  noPayoutDetails,

  /// Nothing withdrawable (e.g. only spend-only credit).
  nothingWithdrawable,

  /// Withdrawable, but under the minimum.
  belowMinimum,

  /// The backend says no for a reason this app doesn't model.
  notAllowed,
}

extension WithdrawEligibility on CustomerWalletModel {
  /// Null when the customer can withdraw. All figures are the backend's —
  /// nothing is derived beyond comparing them.
  WithdrawBlock? get withdrawBlock {
    if (!withdrawalsEnabled) return WithdrawBlock.unavailable;
    if (!hasPayoutDetails) return WithdrawBlock.noPayoutDetails;
    if (withdrawable <= 0) return WithdrawBlock.nothingWithdrawable;
    if (withdrawable < minimumWithdrawal) return WithdrawBlock.belowMinimum;
    if (!canWithdraw) return WithdrawBlock.notAllowed;
    return null;
  }

  String blockMessage(WithdrawBlock block) => switch (block) {
    WithdrawBlock.unavailable => 'Withdrawals are temporarily unavailable.',
    WithdrawBlock.noPayoutDetails =>
      'Your account has no payout details on file yet, so a withdrawal may be declined.',
    WithdrawBlock.nothingWithdrawable =>
      'You have no withdrawable balance yet.',
    WithdrawBlock.belowMinimum =>
      'The minimum withdrawal is ${formatMoney(minimumWithdrawal, currency: currency)}. '
          'You can withdraw ${formatMoney(withdrawable, currency: currency)} right now.',
    WithdrawBlock.notAllowed =>
      'Withdrawals aren\'t available for your account right now.',
  };
}
