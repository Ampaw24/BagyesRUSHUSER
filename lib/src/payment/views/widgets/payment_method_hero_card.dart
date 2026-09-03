import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../model/payment_method.dart';
import 'payout_provider_visuals.dart';

/// "Kwame Owusu" → "Kwame O." — first name plus last-initial, matching the
/// compact holder-name convention used on the hero card.
String shortHolderName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'))..removeWhere((p) => p.isEmpty);
  if (parts.isEmpty) return fullName;
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last[0].toUpperCase()}.';
}

/// "Mobile money" / "Bank account" — derived from the provider's real
/// `type`, not fabricated, so it stays accurate if bank-type providers
/// start coming back from the API.
String paymentMethodKindLabel(PaymentMethod method) {
  if (method.provider?.isBank == true) return 'Bank account';
  return 'Mobile money';
}

// ── Hero card (default method) ────────────────────────────────────────────────

/// The prominent, brand-gradient card for the user's default payout method.
/// Shared between the consumer and vendor Payment Methods screens.
class PaymentMethodHeroCard extends StatelessWidget {
  const PaymentMethodHeroCard({
    super.key,
    required this.method,
    required this.holderName,
    required this.holderVerified,
    required this.isProcessing,
    required this.onManage,
  });

  final PaymentMethod method;
  final String holderName;
  final bool holderVerified;
  final bool isProcessing;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final provider = method.provider;
    final gradientBase = provider != null
        ? payoutProviderVisual(provider).color
        : AppColors.primary;
    final gradient = [
      gradientBase,
      Color.alphaBlend(Colors.black.withValues(alpha: 0.24), gradientBase),
    ];
    final onGradient = provider != null && gradientBase.computeLuminance() > 0.5
        ? const Color(0xFF1A1A1A)
        : Colors.white;
    final radius = w * 0.06;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: brand avatar + default badge ─────────────────────────
          Row(
            children: [
              if (provider != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.025),
                  child: PayoutProviderAvatar(provider: provider, size: w * 0.11),
                )
              else
                Container(
                  width: w * 0.11,
                  height: w * 0.11,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onGradient.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(w * 0.025),
                  ),
                  child: Text(
                    'MM',
                    style: TextStyle(
                      color: onGradient,
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.035,
                    ),
                  ),
                ),
              const Spacer(),
              _DefaultPill(color: onGradient),
            ],
          ),
          SizedBox(height: w * 0.035),

          // ── Title + kind, each on its own line so long names never
          // crowd the badge above or clip mid-word.
          Text(
            method.displayTitle,
            style: TextStyle(
              color: onGradient,
              fontSize: w * 0.048,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: w * 0.004),
          Text(
            paymentMethodKindLabel(method),
            style: TextStyle(
              color: onGradient.withValues(alpha: 0.75),
              fontSize: w * 0.032,
            ),
          ),

          SizedBox(height: w * 0.045),
          Text(
            'LINKED NUMBER',
            style: TextStyle(
              color: onGradient.withValues(alpha: 0.65),
              fontSize: w * 0.027,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: w * 0.012),
          Text(
            method.maskedPhone,
            style: TextStyle(
              color: onGradient,
              fontSize: w * 0.048,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: w * 0.04),

          // ── Bottom: holder name + manage ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  holderVerified ? '$holderName · verified' : holderName,
                  style: TextStyle(
                    color: onGradient.withValues(alpha: 0.85),
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: w * 0.02),
              if (isProcessing)
                SizedBox(
                  width: w * 0.05,
                  height: w * 0.05,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onGradient.withValues(alpha: 0.8),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: onManage,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.035,
                      vertical: w * 0.018,
                    ),
                    decoration: BoxDecoration(
                      color: onGradient.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(w * 0.05),
                    ),
                    child: Text(
                      'Manage',
                      style: TextStyle(
                        color: onGradient,
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.02),
                GestureDetector(
                  onTap: onManage,
                  child: Container(
                    width: w * 0.09,
                    height: w * 0.09,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: onGradient.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: onGradient,
                      size: w * 0.05,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DefaultPill extends StatelessWidget {
  const _DefaultPill({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.012),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.014,
            height: w * 0.014,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.012),
          Text(
            'DEFAULT',
            style: TextStyle(
              color: color,
              fontSize: w * 0.025,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact row (other methods) ───────────────────────────────────────────────

/// A single row inside the "OTHER METHODS" list — avatar, title/subtitle,
/// and a trailing affordance that opens the manage/delete sheet.
class PaymentMethodRow extends StatelessWidget {
  const PaymentMethodRow({
    super.key,
    required this.method,
    required this.isProcessing,
    required this.onTap,
    this.showDivider = true,
  });

  final PaymentMethod method;
  final bool isProcessing;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final provider = method.provider;
    final visual = provider != null ? payoutProviderVisual(provider) : null;

    return Column(
      children: [
        InkWell(
          onTap: isProcessing ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.033),
            child: Row(
              children: [
                if (provider != null)
                  Container(
                    width: w * 0.105,
                    height: w * 0.105,
                    padding: EdgeInsets.all(w * 0.006),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(w * 0.024),
                      border: Border.all(color: (visual?.color ?? AppColors.border).withValues(alpha: 0.18)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(w * 0.018),
                      child: PayoutProviderAvatar(provider: provider, size: w * 0.093),
                    ),
                  )
                else
                  Container(
                    width: w * 0.105,
                    height: w * 0.105,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.024),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
                SizedBox(width: w * 0.032),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.displayTitle,
                        style: TextStyle(
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${paymentMethodKindLabel(method)} · ${method.maskedPhone}',
                        style: TextStyle(
                          fontSize: w * 0.031,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isProcessing)
                  SizedBox(
                    width: w * 0.045,
                    height: w * 0.045,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    width: w * 0.075,
                    height: w * 0.075,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: w * 0.04 + w * 0.105 + w * 0.032),
            child: const Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}

// ── Dashed "add a method" tile ────────────────────────────────────────────────

/// A dashed-outline container drawn with [CustomPaint] — no extra package
/// needed for a simple rectangular dash border.
class DottedBorderContainer extends StatelessWidget {
  const DottedBorderContainer({super.key, required this.child, required this.w});
  final Widget child;
  final double w;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: w * 0.04, color: AppColors.border),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const gapWidth = 4.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// The "Add a payment method" call-to-action tile shown at the end of the
/// list — shared between consumer and vendor screens.
class AddPaymentMethodTile extends StatelessWidget {
  const AddPaymentMethodTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: DottedBorderContainer(
        w: w,
        child: Padding(
          padding: EdgeInsets.all(w * 0.035),
          child: Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded, color: AppColors.primary, size: w * 0.055),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a payment method',
                      style: TextStyle(
                        fontSize: w * 0.037,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Mobile money account',
                      style: TextStyle(fontSize: w * 0.031, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
