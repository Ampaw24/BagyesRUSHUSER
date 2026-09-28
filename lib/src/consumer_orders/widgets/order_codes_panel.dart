import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'order_code_card.dart';

/// Every code the customer may need on the tracking screen, each labelled by
/// who uses it. Renders nothing for codes the backend hasn't returned.
class OrderCodesPanel extends StatelessWidget {
  final ConsumerOrder order;

  const OrderCodesPanel({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final collection = order.collection;
    final collectionCode = collection?.code?.trim() ?? '';
    final deliveryPin = order.deliveryPin?.trim() ?? '';
    final showCollectionCode = collection != null &&
        collectionCode.isNotEmpty &&
        !collection.isVerified &&
        !collection.hasFailed &&
        order.status.isActive;

    final children = <Widget>[
      if (collection != null && collection.hasFailed)
        _CollectionFailedBanner(reason: collection.failureReason),
      if (showCollectionCode)
        _collectionCard(collection, collectionCode),
      if (deliveryPin.isNotEmpty)
        OrderCodeCard(
          title: 'Delivery PIN',
          subtitle: order.isReceiveParcel || collection != null
              ? 'Give this to the rider when they arrive with your package'
              : 'Share this with your rider to confirm delivery',
          code: deliveryPin,
        ),
    ];
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.05),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: w * 0.03),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _collectionCard(OrderCollection collection, String code) {
    final sender = collection.contactName?.trim();
    final senderLabel = sender == null || sender.isEmpty ? 'The sender' : sender;
    final shareTarget = sender == null || sender.isEmpty ? 'sender' : sender;

    return OrderCodeCard(
      title: 'Collection code',
      subtitle: '$senderLabel gives this to the rider at pickup. '
          'Never share it with the rider yourself.',
      code: code,
      icon: Icons.lock_open_rounded,
      shareLabel: 'Send to $shareTarget',
      onShare: () => SharePlus.instance.share(
        ShareParams(
          text: 'Your bagyesRUSH collection code is $code. A rider is '
              'coming to collect the package — give them this code when '
              'they arrive.',
        ),
      ),
    );
  }
}

class _CollectionFailedBanner extends StatelessWidget {
  final String? reason;

  const _CollectionFailedBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final detail = reason?.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: w * 0.06),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "The rider couldn't collect the package",
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  SizedBox(height: w * 0.01),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: w * 0.031,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                SizedBox(height: w * 0.01),
                Text(
                  'Contact support, or cancel the order below.',
                  style: TextStyle(
                    fontSize: w * 0.03,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
