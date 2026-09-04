import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../../models/vendor_wallet_model.dart';

/// Hero balance card for the vendor wallet hub — on-brand
/// secondary/secondaryDark gradient (matches `_RevenueHeroCard` in
/// vendor_earnings_view.dart), not the old off-brand indigo gradient.
class VendorBalanceCard extends StatefulWidget {
  const VendorBalanceCard({
    super.key,
    required this.wallet,
    required this.onWithdraw,
  });

  final VendorWalletModel wallet;
  final VoidCallback onWithdraw;

  @override
  State<VendorBalanceCard> createState() => _VendorBalanceCardState();
}

class _VendorBalanceCardState extends State<VendorBalanceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: w * 0.05),
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(w * 0.06),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.06),
            child: Stack(
              children: [
                Positioned(
                  right: -w * 0.12,
                  top: -w * 0.12,
                  child: Container(
                    width: w * 0.45,
                    height: w * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vendor Wallet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: w * 0.033,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.025,
                            vertical: w * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(w * 0.05),
                          ),
                          child: Text(
                            widget.wallet.currency,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.028,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.06),
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: w * 0.03,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: w * 0.01),
                    Text(
                      widget.wallet.balance.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.09,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: w * 0.06),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _WithdrawButton(onTap: widget.onWithdraw),
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
  const _WithdrawButton({required this.onTap});
  final VoidCallback onTap;

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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.05,
            vertical: w * 0.025,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.035),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: w * 0.04,
                color: AppColors.primary,
              ),
              SizedBox(width: w * 0.015),
              Text(
                'Withdraw',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: w * 0.035,
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
