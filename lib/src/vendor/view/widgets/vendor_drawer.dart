import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class VendorDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final bool isVerified;
  final VoidCallback onClose;
  final VoidCallback? onLogout;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onPaymentMethods;
  final VoidCallback? onWallet;
  final VoidCallback? onNotifications;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onShopProfile;
  final VoidCallback? onDeleteAccount;

  const VendorDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.initials,
    this.isVerified = true,
    required this.onClose,
    this.onLogout,
    this.onPrivacyPolicy,
    this.onPaymentMethods,
    this.onWallet,
    this.onNotifications,
    this.onHelpSupport,
    this.onShopProfile,
    this.onDeleteAccount,
  });

  @override
  State<VendorDrawer> createState() => _VendorDrawerState();
}

class _VendorDrawerState extends State<VendorDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutExpo),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  Animation<double> _staggeredFade(int index) {
    final start = 0.3 + (index * 0.08);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = 0.3 + (index * 0.08);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final drawerWidth = w * 0.78;
    final drawerHeight = h * 0.72;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Blurred backdrop
            GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnimation.value,
                  sigmaY: _blurAnimation.value,
                ),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.35 * _fadeAnimation.value,
                  ),
                ),
              ),
            ),
            // Drawer panel
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(_slideAnimation.value * drawerWidth, 0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: Container(
        width: drawerWidth,
        height: drawerHeight,
        margin: EdgeInsets.only(left: w * 0.02),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(8, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              // ── Header ──
              _DrawerHeader(
                userName: widget.userName,
                userEmail: widget.userEmail,
                initials: widget.initials,
                isVerified: widget.isVerified,
                onClose: _close,
                animation: _controller,
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                child: const Divider(color: AppColors.divider, height: 1),
              ),
              SizedBox(height: w * 0.025),

              // ── Menu items with staggered animations ──
              Expanded(
                child: Column(
                  children: [
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedStore01,
                      label: 'Shop Profile',
                      onTap: widget.onShopProfile,
                      fadeAnim: _staggeredFade(0),
                      slideAnim: _staggeredSlide(0),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedNotification01,
                      label: 'Notifications',
                      onTap: widget.onNotifications,
                      fadeAnim: _staggeredFade(1),
                      slideAnim: _staggeredSlide(1),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedWallet01,
                      label: 'Wallet',
                      onTap: widget.onWallet,
                      fadeAnim: _staggeredFade(2),
                      slideAnim: _staggeredSlide(2),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedCreditCard,
                      label: 'Payment Methods',
                      onTap: widget.onPaymentMethods,
                      fadeAnim: _staggeredFade(3),
                      slideAnim: _staggeredSlide(3),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedShieldKey,
                      label: 'Privacy Policy',
                      onTap: widget.onPrivacyPolicy,
                      fadeAnim: _staggeredFade(4),
                      slideAnim: _staggeredSlide(4),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      label: 'Help & Support',
                      onTap: widget.onHelpSupport,
                      fadeAnim: _staggeredFade(5),
                      slideAnim: _staggeredSlide(5),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                      child: const Divider(color: AppColors.divider, height: 1),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedDelete02,
                      label: 'Delete Account',
                      color: AppColors.warning,
                      onTap: widget.onDeleteAccount,
                      fadeAnim: _staggeredFade(6),
                      slideAnim: _staggeredSlide(6),
                    ),
                    _AnimatedDrawerTile(
                      icon: HugeIcons.strokeRoundedLogout01,
                      label: 'Logout',
                      color: AppColors.error,
                      onTap: widget.onLogout,
                      fadeAnim: _staggeredFade(7),
                      slideAnim: _staggeredSlide(7),
                    ),
                    SizedBox(height: w * 0.04),
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

// ─── Header ──────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final bool isVerified;
  final VoidCallback onClose;
  final AnimationController animation;

  const _DrawerHeader({
    required this.userName,
    required this.userEmail,
    required this.initials,
    required this.isVerified,
    required this.onClose,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    final avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    final textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.055, w * 0.06, w * 0.04, w * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button row
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: AppColors.textSecondary,
                  size: w * 0.04,
                ),
              ),
            ),
          ),
          SizedBox(height: w * 0.02),

          // Avatar with scale animation
          Row(
            children: [
              ScaleTransition(
                scale: avatarScale,
                child: CircleAvatar(
                  radius: w * 0.07,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: FadeTransition(
                  opacity: textFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: w * 0.042,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            SizedBox(width: w * 0.012),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                              color: AppColors.info,
                              size: w * 0.045,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: w * 0.003),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated drawer tile ────────────────────────────────────────────────

class _AnimatedDrawerTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _AnimatedDrawerTile({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final iconColor = color ?? AppColors.primary;
    final labelColor = color ?? AppColors.textPrimary;

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withValues(alpha: 0.08),
            highlightColor: iconColor.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.055,
                vertical: w * 0.034,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: iconColor,
                      size: w * 0.052,
                    ),
                  ),
                  SizedBox(width: w * 0.035),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (color == null)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: AppColors.primary,
                      size: w * 0.038,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
