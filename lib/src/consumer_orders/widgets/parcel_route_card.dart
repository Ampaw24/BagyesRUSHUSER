import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_stop.dart';
import 'tracking_card.dart';

/// Pickup → drop-off route for a parcel, with who's at each end and what's
/// being carried. Renders nothing when the payload carries no route at all.
class ParcelRouteCard extends StatelessWidget {
  const ParcelRouteCard({super.key, required this.order});

  final ConsumerOrder order;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pickup = order.pickupAddress?.trim() ?? '';
    final stops = order.stops;
    final fallbackDropOff = order.deliveryAddress.trim();
    if (pickup.isEmpty && stops.isEmpty && fallbackDropOff.isEmpty) {
      return const SizedBox.shrink();
    }

    final delivered = order.status == OrderStatus.delivered;
    final pickedUp =
        delivered ||
        order.status == OrderStatus.pickedUp ||
        order.status == OrderStatus.onTheWay;

    final rows = <_RouteStop>[
      if (pickup.isNotEmpty)
        _RouteStop(
          kind: _StopKind.pickup,
          label: 'Pickup',
          title: order.pickupContactName,
          address: pickup,
          done: pickedUp,
        ),
      if (stops.isEmpty && fallbackDropOff.isNotEmpty)
        _RouteStop(
          kind: _StopKind.dropOff,
          label: 'Drop-off',
          address: fallbackDropOff,
          done: delivered,
        ),
      for (var i = 0; i < stops.length; i++)
        _RouteStop(
          kind: _StopKind.dropOff,
          label: stops.length > 1 ? 'Drop-off ${i + 1}' : 'Drop-off',
          title: _recipient(stops[i]),
          address: stops[i].address,
          package: stops[i],
          done: delivered,
        ),
    ];

    return TrackingCard(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.045, w * 0.05, w * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery route',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.04),
          for (var i = 0; i < rows.length; i++)
            _RouteSegment(isLast: i == rows.length - 1, child: rows[i]),
        ],
      ),
    );
  }

  static String? _recipient(ParcelStop stop) {
    final name = stop.recipientName?.trim() ?? '';
    final phone = stop.recipientPhone?.trim() ?? '';
    final parts = [if (name.isNotEmpty) name, if (phone.isNotEmpty) phone];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

enum _StopKind { pickup, dropOff }

/// Lays out one stop with the dashed line that links it to the next.
class _RouteSegment extends StatelessWidget {
  const _RouteSegment({required this.isLast, required this.child});

  final bool isLast;
  final _RouteStop child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final marker = w * 0.075;
    final color = child.kind == _StopKind.pickup
        ? AppColors.success
        : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: marker,
            child: Column(
              children: [
                Container(
                  width: marker,
                  height: marker,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    child.done
                        ? Icons.check_rounded
                        : child.kind == _StopKind.pickup
                        ? Icons.radio_button_checked_rounded
                        : Icons.location_on_rounded,
                    size: marker * 0.55,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: w * 0.01),
                      child: CustomPaint(
                        size: Size(w * 0.005, double.infinity),
                        painter: _DashedLinePainter(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? w * 0.03 : w * 0.045),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.kind,
    required this.label,
    required this.address,
    required this.done,
    this.title,
    this.package,
  });

  final _StopKind kind;
  final String label;
  final String? title;
  final String address;
  final bool done;

  /// The stop whose package details to show, for drop-offs.
  final ParcelStop? package;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final title = this.title?.trim() ?? '';
    final chips = _packageChips(package);
    final note = package?.instructions?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: w * 0.026,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            if (done) ...[
              SizedBox(width: w * 0.015),
              Text(
                kind == _StopKind.pickup ? '· Collected' : '· Delivered',
                style: TextStyle(
                  fontSize: w * 0.026,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: w * 0.008),
        if (title.isNotEmpty)
          Text(
            title,
            style: TextStyle(
              fontSize: w * 0.036,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        Text(
          address,
          style: TextStyle(
            fontSize: w * 0.032,
            height: 1.35,
            color: title.isEmpty
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        if (chips.isNotEmpty) ...[
          SizedBox(height: w * 0.02),
          Wrap(spacing: w * 0.015, runSpacing: w * 0.015, children: chips),
        ],
        if (note.isNotEmpty) ...[
          SizedBox(height: w * 0.015),
          Text(
            '“$note”',
            style: TextStyle(
              fontSize: w * 0.03,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  static List<Widget> _packageChips(ParcelStop? stop) {
    if (stop == null) return const [];
    final description = stop.itemDescription?.trim() ?? '';
    final size = stop.size.trim();
    final quantity = stop.quantity;
    return [
      if (description.isNotEmpty)
        _PackageChip(icon: Icons.inventory_2_outlined, label: description),
      if (size.isNotEmpty)
        _PackageChip(
          icon: Icons.straighten_rounded,
          label: size[0].toUpperCase() + size.substring(1),
        ),
      if (quantity != null && quantity > 1)
        _PackageChip(icon: Icons.layers_outlined, label: '$quantity items'),
      if (stop.isFragile == true)
        const _PackageChip(
          icon: Icons.wine_bar_outlined,
          label: 'Fragile',
          color: AppColors.warning,
        ),
    ];
  }
}

class _PackageChip extends StatelessWidget {
  const _PackageChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.022, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.032, color: color),
          SizedBox(width: w * 0.01),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w600,
                color: color == AppColors.textSecondary
                    ? AppColors.textPrimary
                    : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..strokeCap = StrokeCap.round;
    const dash = 4.0, gap = 4.0;
    final x = size.width / 2;
    for (var y = 0.0; y < size.height; y += dash + gap) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
