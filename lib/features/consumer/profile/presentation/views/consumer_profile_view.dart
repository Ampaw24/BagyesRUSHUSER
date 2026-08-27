import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/domain/entities/consumer_profile.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/presentation/states/profile_state.dart';
import 'package:bagyesrushappusernew/features/consumer/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bagyesrushappusernew/services/auth.service.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';

class ConsumerProfileView extends ConsumerWidget {
  const ConsumerProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit02,
              color: AppColors.textPrimary,
              size: w * 0.042,
            ),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: switch (profileState) {
        ProfileLoading() => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        ProfileError(:final message) => Center(child: Text(message)),
        ProfileLoaded(:final profile) ||
        ProfileUpdating(:final profile) => _ProfileBody(profile: profile, w: w),
      },
    );
  }
}

// ─── Profile Body ─────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final ConsumerProfile profile;
  final double w;

  const _ProfileBody({required this.profile, required this.w});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.02,
        w * 0.05,
        w * 0.06 +
            MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight,
      ),
      children: [
        // ── Avatar + name ──
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoutes.editProfile),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: w * 0.13,
                      backgroundColor: AppColors.primary,
                      backgroundImage:
                          profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                      child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                          ? Text(
                              profile.initials,
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
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
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
                profile.fullName,
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.008),
              Text(
                profile.email,
                style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textSecondary,
                ),
              ),
              if (profile.isVerified) ...[
                SizedBox(height: w * 0.02),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                      color: AppColors.info,
                      size: w * 0.032,
                    ),
                    SizedBox(width: w * 0.015),
                    Text(
                      'Verified Account',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: w * 0.06),

        // ── Stats row ──
        Row(
          children: [
            _StatBox(label: 'Orders', value: '${profile.orderCount}'),
            SizedBox(width: w * 0.03),
            _StatBox(label: 'Reviews', value: '${profile.reviewCount}'),
            SizedBox(width: w * 0.03),
            _StatBox(label: 'Wallet', value: profile.formattedWallet),
          ],
        ),
        SizedBox(height: w * 0.05),

        // ── Account section ──
        _SectionLabel('Account'),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedUser,
          label: 'Personal Information',
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedCreditCard,
          label: 'Payment Methods',
          onTap: () => context.push(AppRoutes.customerPaymentMethods),
        ),

        SizedBox(height: w * 0.02),
        _SectionLabel('Orders & Wallet'),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedReceiptDollar,
          label: 'Order History',
          onTap: () {},
        ),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedTransactionHistory,
          label: 'Transactions',
          onTap: () => context.push(AppRoutes.wallet),
        ),
        SizedBox(height: w * 0.02),
        _SectionLabel('Support'),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedHelpCircle,
          label: 'Help & Support',
          onTap: () => context.push(AppRoutes.helpSupport),
        ),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedPolicy,
          label: 'Privacy Policy',
          onTap: () {},
        ),

        SizedBox(height: w * 0.02),
        _ProfileTile(
          icon: HugeIcons.strokeRoundedDoor01,
          label: 'Log Out',
          color: AppColors.error,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }


  void _confirmLogout(BuildContext context, WidgetRef ref) {
    CustomDialog.showConfirmation(
      context: context,
      title: "Logout?",
      subtitle:
          "You sure want to logout?\nYou will be returned to the login screen.",
      onConfirm: () async {
        if (!context.mounted) return;
        await context.read<AuthViewmodel>().logout();
        if (!context.mounted) return;
        context.read<AppState>().setUser(IUser());
        context.read<AppState>().setPayload(ISignup());
        context.go(AppRoutes.login);
      },
      confirmText: 'Log out',
      cancelText: 'Cancel',
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: w * 0.008),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.028,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.02),
      child: Text(
        label,
        style: TextStyle(
          fontSize: w * 0.032,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final c = color ?? AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.03),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: w * 0.034,
            horizontal: w * 0.01,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.022),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: color ?? AppColors.primary,
                  size: w * 0.044,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w500,
                    color: c,
                  ),
                ),
              ),
              if (color == null)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.textHint,
                  size: w * 0.038,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
