import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/router.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/services/auth.service.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/view/widgets/floating_nav_bar.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  String _initialsOf(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  void _confirmLogout(BuildContext context) {
    CustomDialog.showConfirmation(
      context: context,
      title: "Logout?",
      subtitle:
          "You sure want to logout?\nYou will be returned to the login screen.",
      onConfirm: () async {
        await context.read<AuthViewmodel>().logout();
        if (!context.mounted) return;
        final appState = context.read<AppState>();
        appState.setUser(IUser());
        appState.setPayload(ISignup());
        context.go(AppRoutes.login);
      },
      confirmText: 'Log out',
      cancelText: 'Cancel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    // Watch (not read) so the avatar/name refresh immediately when
    // EditProfile's save or avatar upload updates CurrentUserProvider —
    // no need to leave and re-enter this screen to see the change.
    final user = context.watch<CurrentUserProvider>().user;
    final profile =
        user?.profile is CustomerProfile ? user!.profile as CustomerProfile : null;
    final fullName = [profile?.firstName, profile?.lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    final avatarUrl = profile?.profilePictureUrl;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            w: w,
            fullName: fullName.isNotEmpty ? fullName : (user?.phone ?? ''),
            email: email,
            avatarUrl: avatarUrl,
            initials: _initialsOf(
              fullName.isNotEmpty ? fullName : (user?.phone ?? '?'),
            ),
            onEdit: () => context.push(AppRoutes.editProfile),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.06,
              w * 0.05,
              // This bar floats above the tab in a Stack rather than sitting
              // in Scaffold.bottomNavigationBar, so nothing reserves space
              // for it automatically — without this, the last card would
              // scroll to rest behind it instead of clear above it.
              FloatingNavBar.reservedHeight(context) + w * 0.04,
            ),
            child: Column(
              children: [
                _SectionCard(
                  label: 'Account',
                  w: w,
                  tiles: [
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedUser,
                      label: 'Personal Information',
                      onTap: () => context.push(AppRoutes.editProfile),
                      w: w,
                    ),
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedCreditCard,
                      label: 'Payment Methods',
                      onTap: () =>
                          context.push(AppRoutes.customerPaymentMethods),
                      w: w,
                    ),
                  ],
                ),
                SizedBox(height: w * 0.05),
                _SectionCard(
                  label: 'Orders & Wallet',
                  w: w,
                  tiles: [
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedReceiptDollar,
                      label: 'Order History',
                      onTap: () {},
                      w: w,
                    ),
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedTransactionHistory,
                      label: 'Transactions',
                      onTap: () => context.push(AppRoutes.wallet),
                      w: w,
                    ),
                  ],
                ),
                SizedBox(height: w * 0.05),
                _SectionCard(
                  label: 'Support',
                  w: w,
                  tiles: [
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      label: 'Help & Support',
                      onTap: () => context.push(AppRoutes.helpSupport),
                      w: w,
                    ),
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedPolicy,
                      label: 'Privacy Policy',
                      onTap: () {},
                      w: w,
                    ),
                  ],
                ),
                SizedBox(height: w * 0.05),
                _SectionCard(
                  w: w,
                  tiles: [
                    _ProfileTile(
                      icon: HugeIcons.strokeRoundedDoor01,
                      label: 'Log Out',
                      color: AppColors.error,
                      onTap: () => _confirmLogout(context),
                      w: w,
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double w;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onEdit;

  const _Header({
    required this.w,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.initials,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
      color: AppColors.scaffold,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: w * 0.06,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.all(w * 0.024),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPencilEdit02,
                    color: AppColors.textPrimary,
                    size: w * 0.045,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.05),
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: w * 0.14,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      avatarUrl != null && avatarUrl!.isNotEmpty
                          ? NetworkImage(avatarUrl!)
                          : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.09,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: Colors.white,
                      size: w * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.035),
          Text(
            fullName,
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (email.isNotEmpty) ...[
            SizedBox(height: w * 0.006),
            Text(
              email,
              style: TextStyle(
                fontSize: w * 0.033,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? label;
  final double w;
  final List<Widget> tiles;

  const _SectionCard({this.label, required this.w, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.025, left: w * 0.01),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(w * 0.045),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final double w;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.w,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.03),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.026),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: color ?? AppColors.primary,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w600,
                    color: c,
                  ),
                ),
              ),
              if (color == null)
                Container(
                  width: w * 0.07,
                  height: w * 0.07,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
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
    );
  }
}
