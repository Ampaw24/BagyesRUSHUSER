import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_wallet.dart';

/// Hero wallet card for the customer transaction screen — refunds and
/// order-adjustment credits collect here as a running balance (distinct
/// from the transaction list below it, which is the raw payment ledger),
/// withdrawable to mobile money at any time.
///
/// A compact, card-like treatment (layered gradient, contactless glyph,
/// looping light sweep, count-up balance) rather than a plain color block —
/// deliberately shorter than a typical hero card so it doesn't dominate the
/// screen above the transaction list.
class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.isLoading,
    required this.errorMessage,
    required this.onWithdraw,
    required this.onRetry,
  });

  final PaymentWallet? wallet;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onWithdraw;
  final VoidCallback onRetry;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _pulseCtrl;
  late final AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    // Slow, subtle breathing on the decorative orb — purely decorative, no
    // layout cost since it's an absolutely-positioned Stack child.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // A soft light sweep that crosses the card, pauses, then repeats — the
    // "cool" touch, kept slow/low-opacity so it reads as premium rather
    // than distracting.
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _runSweepLoop();
  }

  Future<void> _runSweepLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      await _sweepCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wallet = widget.wallet;
    final showSkeleton = wallet == null && widget.isLoading;
    final showError = wallet == null && !widget.isLoading && widget.errorMessage != null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: EdgeInsets.fromLTRB(w * 0.05, w * 0.025, w * 0.05, w * 0.015),
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.045, w * 0.05, w * 0.045),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary, AppColors.primaryDark],
              stops: [0, 0.45, 1],
            ),
            borderRadius: BorderRadius.circular(w * 0.055),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.055),
            child: Stack(
              children: [
                // Decorative breathing orb.
                Positioned(
                  right: -w * 0.14,
                  top: -w * 0.16,
                  child: ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: w * 0.38,
                      height: w * 0.38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                // Looping diagonal light sweep.
                AnimatedBuilder(
                  animation: _sweepCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_sweepCtrl.value);
                    return Positioned(
                      left: -w * 0.5 + t * (w * 1.7),
                      top: -w * 0.2,
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          width: w * 0.22,
                          height: w * 0.85,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.contactless_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: w * 0.05,
                            ),
                            SizedBox(width: w * 0.018),
                            Text(
                              'My Wallet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: w * 0.032,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.022,
                            vertical: w * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(w * 0.05),
                          ),
                          child: Text(
                            wallet?.currency ?? 'GHS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.026,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.04),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showSkeleton)
                          SizedBox(
                            width: w * 0.07,
                            height: w * 0.07,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        else
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: wallet?.balance ?? 0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Text(
                              value.toStringAsFixed(2),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.076,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      'Available balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: w * 0.027,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: w * 0.028),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            showError
                                ? "Couldn't load your wallet balance."
                                : 'Refunds & order credits collect here.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.66),
                              fontSize: w * 0.028,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        showError
                            ? _RetryPill(onTap: widget.onRetry)
                            : _WithdrawButton(
                                enabled: (wallet?.balance ?? 0) > 0,
                                onTap: widget.onWithdraw,
                              ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WithdrawButton extends StatefulWidget {
  const _WithdrawButton({required this.onTap, required this.enabled});
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_WithdrawButton> createState() => _WithdrawButtonState();
}

class _WithdrawButtonState extends State<_WithdrawButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _ctrl.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(w * 0.03),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward_rounded, size: w * 0.035, color: AppColors.primary),
              SizedBox(width: w * 0.012),
              Text(
                'Withdraw',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryPill extends StatelessWidget {
  const _RetryPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.03),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: w * 0.035, color: AppColors.primary),
            SizedBox(width: w * 0.012),
            Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: w * 0.032,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
