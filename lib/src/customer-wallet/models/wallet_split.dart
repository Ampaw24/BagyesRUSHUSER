import 'dart:math' as math;

/// Display-only preview of how a payment splits between the customer's
/// wallet and their mobile-money account when "Use wallet balance" is on.
/// The backend performs the real split when the order/parcel is created.
class WalletSplit {
  const WalletSplit._({
    required this.walletAmount,
    required this.remaining,
    this.isKnown = true,
  });

  /// [total] is null while the backend total is still loading — nothing is
  /// considered covered until it's known.
  factory WalletSplit.from({
    required double balance,
    required double? total,
    required bool useWallet,
  }) {
    if (!useWallet || total == null || balance <= 0) {
      return WalletSplit._(walletAmount: 0, remaining: total ?? 0);
    }
    final fromWallet = math.min(balance, total);
    return WalletSplit._(
      walletAmount: fromWallet,
      remaining: math.max(0, total - fromWallet),
    );
  }

  /// The backend's own split (e.g. the cart's `wallet.applied`/`payable`),
  /// used as-is — `applied` is already capped at the total server-side.
  factory WalletSplit.fromServer({
    required bool useWallet,
    required double? applied,
    required double? payable,
    required double? total,
  }) {
    if (!useWallet) return WalletSplit._(walletAmount: 0, remaining: total ?? 0);
    if (applied == null || payable == null) {
      return WalletSplit._(walletAmount: 0, remaining: total ?? 0, isKnown: false);
    }
    return WalletSplit._(walletAmount: applied, remaining: payable);
  }

  final double walletAmount;
  final double remaining;

  /// False when the wallet is on but the backend hasn't priced the split
  /// for this selection — the server still applies it on order creation.
  final bool isKnown;

  bool get usesWallet => walletAmount > 0;
  bool get coversFully => usesWallet && remaining <= 0;
}
