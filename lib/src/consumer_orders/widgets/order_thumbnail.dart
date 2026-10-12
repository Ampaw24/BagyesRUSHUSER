import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/core/utils/image_cache_size.dart';
import 'package:bagyesrushappusernew/core/widgets/network_avatar.dart';
import 'package:bagyesrushappusernew/resources/resources.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Square picture for an order row: the parcel box for a parcel, otherwise
/// the vendor's logo — or their initials on a name-keyed tint when they have
/// none.
class OrderThumbnail extends StatelessWidget {
  const OrderThumbnail({
    super.key,
    required this.order,
    required this.size,
    required this.radius,
  });

  final ConsumerOrder order;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: order.isParcel
            ? Image.asset(
                Assets.deliveryBoxParcel,
                fit: BoxFit.cover,
                cacheWidth: coverCacheWidth(context, width: size, height: size),
              )
            : NetworkAvatar(
                name: order.restaurantName,
                photoUrl: order.restaurantImageUrl,
                size: size,
                foregroundColor: nameTintColor(order.restaurantName),
                borderRadius: BorderRadius.zero,
              ),
      ),
    );
  }
}
