import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';

/// Pinned bottom bar: tracking is always the main way forward, with home and
/// (when paid) sharing as secondary choices. A failed payment leads with
/// "Try again".
class ReceiptActions extends StatelessWidget {
  const ReceiptActions({
    super.key,
    required this.status,
    required this.isParcel,
    required this.onTrack,
    required this.onHome,
    required this.onRetry,
    required this.onShare,
    this.isSharing = false,
  });

  final ReceiptStatus status;
  final bool isParcel;
  final VoidCallback onTrack;
  final VoidCallback onHome;
  final VoidCallback onRetry;
  final VoidCallback onShare;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final failed = status == ReceiptStatus.failed;
    final trackLabel = isParcel ? 'Track parcel' : 'Track order';
    final secondary = OutlinedButton.styleFrom(
      minimumSize: Size(0, w * 0.12),
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.border),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: failed ? onRetry : onTrack,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, w * 0.13),
          ),
          child: Text(failed ? 'Try again' : trackLabel),
        ),
        SizedBox(height: w * 0.03),
        Row(
          children: [
            Expanded(
              child: failed
                  ? OutlinedButton(
                      onPressed: onTrack,
                      style: secondary,
                      child: Text(trackLabel),
                    )
                  : OutlinedButton.icon(
                      onPressed: status == ReceiptStatus.paid && !isSharing
                          ? onShare
                          : null,
                      style: secondary,
                      icon: isSharing
                          ? SizedBox(
                              width: w * 0.04,
                              height: w * 0.04,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.ios_share_rounded, size: w * 0.045),
                      label: const Text('Share'),
                    ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onHome,
                style: secondary,
                icon: Icon(Icons.home_rounded, size: w * 0.045),
                label: const Text('Home'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
