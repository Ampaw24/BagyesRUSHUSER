import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../src/notification/viewmodel/notification_viewmodel.dart';

// ─── Customer Drawer ──────────────────────────────────────────────────────────

class CustomerDrawer extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback onClose;
  final VoidCallback? onProfile;
  final VoidCallback? onOrders;
  final VoidCallback? onNotifications;
  final VoidCallback? onTransactions;
  final VoidCallback? onPaymentMethods;
  final VoidCallback? onInviteFriends;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onReportProblem;
  final VoidCallback? onDeleteAccount;
  final VoidCallback? onLogout;

  const CustomerDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.initials,
    this.avatarUrl,
    this.isVerified = false,
    required this.onClose,
    this.onProfile,
    this.onOrders,
    this.onNotifications,
    this.onTransactions,
    this.onPaymentMethods,
    this.onInviteFriends,
    this.onPrivacyPolicy,
    this.onHelpSupport,
    this.onReportProblem,
    this.onDeleteAccount,
    this.onLogout,
  });

  @override
  State<CustomerDrawer> createState() => _CustomerDrawerState();
}

class _CustomerDrawerState extends State<CustomerDrawer>
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
    final start = (0.3 + (index * 0.07)).clamp(0.0, 1.0);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = (0.3 + (index * 0.07)).clamp(0.0, 1.0);
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
    final unreadNotifications =
        context.watch<NotificationViewmodel>().unreadCount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
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
      child: SafeArea(
        child: Container(
          width: drawerWidth,
          margin: EdgeInsets.symmetric(
            vertical: h * 0.02,
            horizontal: w * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.07),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: w * 0.1,
                offset: Offset(w * 0.02, w * 0.01),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.07),
            child: Column(
              children: [
                DrawerHeader(
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                  initials: widget.initials,
                  avatarUrl: widget.avatarUrl,
                  isVerified: widget.isVerified,
                  onClose: _close,
                  animation: _controller,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: const Divider(color: AppColors.divider, height: 1),
                ),
                SizedBox(height: w * 0.025),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            children: [
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedUser,
                                label: 'My Profile',
                                onTap: widget.onProfile,
                                fadeAnim: _staggeredFade(0),
                                slideAnim: _staggeredSlide(0),
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedDeliveryBox01,
                                label: 'My Orders',
                                onTap: widget.onOrders,
                                fadeAnim: _staggeredFade(1),
                                slideAnim: _staggeredSlide(1),
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedNotification01,
                                label: 'Notifications',
                                onTap: widget.onNotifications,
                                fadeAnim: _staggeredFade(2),
                                slideAnim: _staggeredSlide(2),
                                badgeCount: unreadNotifications,
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedTransactionHistory,
                                label: 'Transactions',
                                onTap: widget.onTransactions,
                                fadeAnim: _staggeredFade(3),
                                slideAnim: _staggeredSlide(3),
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedCreditCard,
                                label: 'Payment Methods',
                                onTap: widget.onPaymentMethods,
                                fadeAnim: _staggeredFade(4),
                                slideAnim: _staggeredSlide(4),
                              ),
                              // DrawerTile(
                              //   icon: HugeIcons.strokeRoundedMoneyBag01,
                              //   label: 'Invite Friends',
                              //   onTap: widget.onInviteFriends,
                              //   fadeAnim: _staggeredFade(5),
                              //   slideAnim: _staggeredSlide(5),
                              // ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedShieldKey,
                                label: 'Privacy Policy',
                                onTap: widget.onPrivacyPolicy,
                                fadeAnim: _staggeredFade(6),
                                slideAnim: _staggeredSlide(6),
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedHelpCircle,
                                label: 'Help & Support',
                                onTap: widget.onHelpSupport,
                                fadeAnim: _staggeredFade(7),
                                slideAnim: _staggeredSlide(7),
                              ),
                              DrawerTile(
                                icon: HugeIcons.strokeRoundedFlag02,
                                label: 'Report a Problem',
                                onTap: widget.onReportProblem,
                                fadeAnim: _staggeredFade(8),
                                slideAnim: _staggeredSlide(8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                        child: const Divider(
                          color: AppColors.divider,
                          height: 1,
                        ),
                      ),
                      DrawerTile(
                        icon: HugeIcons.strokeRoundedDelete02,
                        label: 'Delete Account',
                        color: AppColors.warning,
                        onTap: widget.onDeleteAccount,
                        fadeAnim: _staggeredFade(9),
                        slideAnim: _staggeredSlide(9),
                      ),
                      DrawerTile(
                        icon: HugeIcons.strokeRoundedLogout01,
                        label: 'Logout',
                        color: AppColors.error,
                        onTap: widget.onLogout,
                        fadeAnim: _staggeredFade(10),
                        slideAnim: _staggeredSlide(10),
                      ),
                      SizedBox(height: h * 0.015),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Drawer Header ────────────────────────────────────────────────────────────

class DrawerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String initials;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback onClose;
  final AnimationController animation;

  const DrawerHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.initials,
    this.avatarUrl,
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
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.025),
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
          Row(
            children: [
              ScaleTransition(
                scale: avatarScale,
                child: CircleAvatar(
                  radius: w * 0.07,
                  backgroundColor: AppColors.primary,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.05,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
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

// ─── Drawer Tile ──────────────────────────────────────────────────────────────

class DrawerTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final int badgeCount;

  const DrawerTile({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
    required this.fadeAnim,
    required this.slideAnim,
    this.badgeCount = 0,
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
                      borderRadius: BorderRadius.circular(w * 0.025),
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
                  if (badgeCount > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.02,
                        vertical: w * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(w * 0.03),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                  ],
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
