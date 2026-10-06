import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Stands where a saved-payment-method picker used to be: Paystack's secure
/// page, shown after the order or parcel is placed, is where the customer
/// chooses how to pay. [walletCoversFully] swaps the wording for orders the
/// wallet pays in full, where Paystack isn't involved.
class PaystackNote extends StatelessWidget {
  const PaystackNote({super.key, this.walletCoversFully = false});

  final bool walletCoversFully;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            walletCoversFully
                ? Icons.account_balance_wallet_outlined
                : Icons.lock_outline_rounded,
            color: AppColors.primary,
            size: w * 0.055,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              walletCoversFully
                  ? 'Nothing more to pay — your wallet covers this order.'
                  : 'You\'ll choose how to pay on the secure Paystack page '
                      'after you place the order.',
              style: TextStyle(
                fontSize: w * 0.032,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
