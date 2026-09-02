import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../../../src/payment/model/payment_method.dart';
import '../../../../src/payment/views/widgets/payout_provider_visuals.dart';

/// Last 4 digits of a saved method's phone number, for the hero card's
/// dot-masked "linked number" display.
String lastFourDigits(String phoneNumber) {
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '••••';
  return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
}

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
      Color.alphaBlend(Colors.black.withValues(alpha: 0.28), gradientBase),
    ];
    final onGradient = provider != null && gradientBase.computeLuminance() > 0.5
        ? const Color(0xFF1A1A1A)
        : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.055),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: w * 0.04,
            offset: Offset(0, w * 0.015),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -w * 0.06,
            top: -w * 0.06,
            child: Container(
              width: w * 0.26,
              height: w * 0.26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.displayTitle,
                          style: TextStyle(
                            color: onGradient,
                            fontSize: w * 0.048,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          paymentMethodKindLabel(method),
                          style: TextStyle(
                            color: onGradient.withValues(alpha: 0.75),
                            fontSize: w * 0.033,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DefaultPill(color: onGradient),
                ],
              ),
              SizedBox(height: w * 0.07),
              Text(
                'LINKED NUMBER',
                style: TextStyle(
                  color: onGradient.withValues(alpha: 0.65),
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: w * 0.015),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '•  •  •  •  •  •  •  •  ',
                    style: TextStyle(
                      color: onGradient,
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    lastFourDigits(method.phoneNumber),
                    style: TextStyle(
                      color: onGradient,
                      fontSize: w * 0.06,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.06),
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

    return Column(
      children: [
        InkWell(
          onTap: isProcessing ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
            child: Row(
              children: [
                if (provider != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(w * 0.02),
                    child: PayoutProviderAvatar(provider: provider, size: w * 0.1),
                  )
                else
                  Container(
                    width: w * 0.1,
                    height: w * 0.1,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
                SizedBox(width: w * 0.03),
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: w * 0.055,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: w * 0.04 + w * 0.1 + w * 0.03),
            child: const Divider(height: 1, color: AppColors.divider),
          ),
      ],
    );
  }
}
