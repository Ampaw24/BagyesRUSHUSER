import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/visa_card_model.dart';

/// Animated 3D credit card preview with front/back flip.
///
/// Pass [isFlipped] = true to show the CVV side.
class CreditCardPreview extends StatefulWidget {
  final String cardNumber;        // raw digits, e.g. "4242424242424242"
  final String cardholderName;
  final String expiry;            // "MM/YY"
  final String cvv;
  final CardBrand brand;
  final bool isFlipped;

  const CreditCardPreview({
    super.key,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiry,
    required this.cvv,
    required this.brand,
    this.isFlipped = false,
  });

  @override
  State<CreditCardPreview> createState() => _CreditCardPreviewState();
}

class _CreditCardPreviewState extends State<CreditCardPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(CreditCardPreview old) {
    super.didUpdateWidget(old);
    if (widget.isFlipped != old.isFlipped) {
      if (widget.isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ── Formatted display ────────────────────────────────────────────────────

  String get _displayNumber {
    final digits = widget.cardNumber.replaceAll(RegExp(r'\D'), '');
    final padded = digits.padRight(16, '•');
    final groups = <String>[];
    for (int i = 0; i < 16; i += 4) {
      groups.add(padded.substring(i, (i + 4).clamp(0, 16)));
    }
    return groups.join('  ');
  }

  String get _displayName =>
      widget.cardholderName.isEmpty ? 'FULL NAME' : widget.cardholderName.toUpperCase();

  String get _displayExpiry =>
      widget.expiry.isEmpty ? 'MM/YY' : widget.expiry;

  // ── Gradient per brand ───────────────────────────────────────────────────

  List<Color> get _gradient => switch (widget.brand) {
        CardBrand.visa => [
            const Color(0xFF1A237E),
            const Color(0xFF3949AB),
          ],
        CardBrand.mastercard => [
            const Color(0xFF212121),
            const Color(0xFF424242),
          ],
        CardBrand.other => [
            AppColors.secondary,
            AppColors.secondaryLight,
          ],
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 40;
    final h = w * 0.58;

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, _) {
          final angle = _flipAnim.value * math.pi;
          // Front when angle < 90°, back when angle >= 90°
          final showBack = angle >= math.pi / 2;
          final displayAngle = showBack ? angle - math.pi : angle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(displayAngle),
            child: showBack
                ? _CardBack(
                    w: w,
                    h: h,
                    gradient: _gradient,
                    cvv: widget.cvv,
                  )
                : _CardFront(
                    w: w,
                    h: h,
                    gradient: _gradient,
                    brand: widget.brand,
                    displayNumber: _displayNumber,
                    displayName: _displayName,
                    displayExpiry: _displayExpiry,
                  ),
          );
        },
      ),
    );
  }
}

// ── Front face ───────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final double w;
  final double h;
  final List<Color> gradient;
  final CardBrand brand;
  final String displayNumber;
  final String displayName;
  final String displayExpiry;

  const _CardFront({
    required this.w,
    required this.h,
    required this.gradient,
    required this.brand,
    required this.displayNumber,
    required this.displayName,
    required this.displayExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle top-right
          Positioned(
            right: -w * 0.1,
            top: -h * 0.2,
            child: Container(
              width: w * 0.55,
              height: w * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -w * 0.15,
            bottom: -h * 0.25,
            child: Container(
              width: w * 0.65,
              height: w * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(w * 0.065),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: chip + brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // EMV chip
                    Container(
                      width: w * 0.11,
                      height: w * 0.08,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFB95F),
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDFB95F), Color(0xFFC8A44A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Brand text
                    Text(
                      brand.displayName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: w * 0.048,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Card number
                Text(
                  displayNumber,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.052,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),

                SizedBox(height: h * 0.06),

                // Name + expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: w * 0.025,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: w * 0.025,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          displayExpiry,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.035,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back face ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final double w;
  final double h;
  final List<Color> gradient;
  final String cvv;

  const _CardBack({
    required this.w,
    required this.h,
    required this.gradient,
    required this.cvv,
  });

  @override
  Widget build(BuildContext context) {
    // Back face must be mirrored so text reads correctly after flip
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Magnetic stripe
            SizedBox(height: h * 0.15),
            Container(
              width: double.infinity,
              height: h * 0.16,
              color: const Color(0xFF1A1A1A),
            ),
            SizedBox(height: h * 0.1),
            // Signature strip + CVV
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.065),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: h * 0.11,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerRight,
                      child: Text(
                        cvv.isEmpty ? 'CVV' : cvv,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CVV',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
