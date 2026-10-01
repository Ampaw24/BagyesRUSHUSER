import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

enum TicketPart { top, bottom }

/// One half of a ticket-style card. Stack a [TicketPart.top] directly above a
/// [TicketPart.bottom]: their facing corners are notched, and the bottom half
/// draws the dashed tear line between them.
class TicketSection extends StatelessWidget {
  const TicketSection({
    super.key,
    required this.part,
    required this.child,
    this.padding,
  });

  final TicketPart part;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return CustomPaint(
      painter: _TicketPainter(
        part: part,
        radius: w * 0.05,
        notch: w * 0.035,
        dash: w * 0.015,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(horizontal: w * 0.06, vertical: w * 0.05),
          child: child,
        ),
      ),
    );
  }
}

class _TicketPainter extends CustomPainter {
  const _TicketPainter({
    required this.part,
    required this.radius,
    required this.notch,
    required this.dash,
  });

  final TicketPart part;
  final double radius;
  final double notch;
  final double dash;

  static const _borderWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawPath(path, Paint()..color = AppColors.card);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );

    // The two halves share one edge: hide the border there, then (bottom half
    // only) draw the tear line over it.
    final joinY = part == TicketPart.top ? size.height : 0.0;
    final left = notch;
    final right = size.width - notch;
    canvas.drawLine(
      Offset(left, joinY),
      Offset(right, joinY),
      Paint()
        ..color = AppColors.card
        ..strokeWidth = _borderWidth * 3,
    );
    if (part == TicketPart.bottom) {
      final dashPaint = Paint()
        ..color = AppColors.border
        ..strokeWidth = _borderWidth;
      for (var x = left + dash; x + dash < right; x += dash * 2) {
        canvas.drawLine(Offset(x, joinY), Offset(x + dash, joinY), dashPaint);
      }
    }
  }

  Path _path(Size s) {
    final corner = Radius.circular(radius);
    final cut = Radius.circular(notch);
    final path = Path();
    if (part == TicketPart.top) {
      path
        ..moveTo(0, radius)
        ..arcToPoint(Offset(radius, 0), radius: corner)
        ..lineTo(s.width - radius, 0)
        ..arcToPoint(Offset(s.width, radius), radius: corner)
        ..lineTo(s.width, s.height - notch)
        ..arcToPoint(Offset(s.width - notch, s.height),
            radius: cut, clockwise: false)
        ..lineTo(notch, s.height)
        ..arcToPoint(Offset(0, s.height - notch),
            radius: cut, clockwise: false);
    } else {
      path
        ..moveTo(0, notch)
        ..arcToPoint(Offset(notch, 0), radius: cut, clockwise: false)
        ..lineTo(s.width - notch, 0)
        ..arcToPoint(Offset(s.width, notch), radius: cut, clockwise: false)
        ..lineTo(s.width, s.height - radius)
        ..arcToPoint(Offset(s.width - radius, s.height), radius: corner)
        ..lineTo(radius, s.height)
        ..arcToPoint(Offset(0, s.height - radius), radius: corner);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_TicketPainter old) =>
      old.part != part ||
      old.radius != radius ||
      old.notch != notch ||
      old.dash != dash;
}
