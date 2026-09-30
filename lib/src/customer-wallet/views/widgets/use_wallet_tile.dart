import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_wallet_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/wallet_split.dart';

/// "Use wallet balance" toggle shared by food checkout and the parcel
/// summary. Never blocks payment on its own load state — a slow or failed
/// wallet fetch just leaves the toggle unavailable.
class UseWalletTile extends StatelessWidget {
  const UseWalletTile({
    super.key,
    required this.wallet,
    required this.isLoading,
    required this.hasError,
    required this.useWallet,
    required this.split,
    required this.onChanged,
    this.onRetry,
  });

  final CustomerWalletModel? wallet;
  final bool isLoading;
  final bool hasError;
  final bool useWallet;
  final WalletSplit split;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final balance = wallet?.balance ?? 0;
    final currency = wallet?.currency ?? 'GHS';
    final canUse = wallet != null && balance > 0;
    final isOn = useWallet && canUse;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(
          color: isOn
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: isOn ? AppColors.success : AppColors.textSecondary,
            size: w * 0.06,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use wallet balance',
                  style: TextStyle(
                    fontSize: w * 0.036,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.005),
                // Crossfades as the split changes instead of snapping.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: _Subtitle(
                    key: ValueKey((
                      isLoading && wallet == null,
                      hasError && wallet == null,
                      isOn,
                      balance,
                      split.walletAmount,
                      split.remaining,
                    )),
                    isLoading: isLoading && wallet == null,
                    hasError: hasError && wallet == null,
                    isOn: isOn,
                    balanceLabel: formatMoney(balance, currency: currency),
                    split: split,
                    currency: currency,
                    onRetry: onRetry,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading && wallet == null)
            SizedBox(
              width: w * 0.045,
              height: w * 0.045,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isOn,
              activeTrackColor: AppColors.success,
              onChanged: canUse
                  ? (value) {
                      HapticFeedback.selectionClick();
                      onChanged(value);
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.isOn,
    required this.balanceLabel,
    required this.split,
    required this.currency,
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final bool isOn;
  final String balanceLabel;
  final WalletSplit split;
  final String currency;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final style = TextStyle(fontSize: w * 0.03, color: AppColors.textSecondary);

    if (isLoading) return Text('Checking balance…', style: style);

    if (hasError) {
      return GestureDetector(
        onTap: onRetry,
        child: Text(
          onRetry == null ? 'Balance unavailable' : 'Balance unavailable · Retry',
          style: style.copyWith(color: AppColors.error),
        ),
      );
    }

    if (isOn && !split.isKnown) {
      return Text(
        'Balance applied when you place the order',
        style: style.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
      );
    }

    if (!isOn || !split.usesWallet) {
      return Text('Available: $balanceLabel', style: style);
    }

    if (split.coversFully) {
      return Text(
        'Wallet covers your full payment',
        style: style.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text(
      '${formatMoney(split.walletAmount, currency: currency)} from wallet · '
      '${formatMoney(split.remaining, currency: currency)} via mobile money',
      style: style.copyWith(color: AppColors.textPrimary),
    );
  }
}
