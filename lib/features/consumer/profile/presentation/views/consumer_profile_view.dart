import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';

class ConsumerProfileView extends StatelessWidget {
  const ConsumerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.06),
        children: [
          // ── Avatar + name ──
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: w * 0.13,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        'JD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.09,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: w * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w * 0.035),
                Text(
                  'Ampaw Justice',
                  style: TextStyle(
                    fontSize: w * 0.05,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.008),
                Text(
                  'john@bagyesrush.com',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.02),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.info,
                      size: 16,
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
            ),
          ),
          SizedBox(height: w * 0.06),

          // ── Stats row ──
          Row(
            children: [
              _StatBox(label: 'Orders', value: '14'),
              SizedBox(width: w * 0.03),
              _StatBox(label: 'Reviews', value: '6'),
              SizedBox(width: w * 0.03),
              _StatBox(label: 'Wallet', value: 'GHS 45'),
            ],
          ),
          SizedBox(height: w * 0.05),

          // ── Account section ──
          _SectionLabel('Account'),
          _ProfileTile(
            icon: Icons.person_rounded,
            label: 'Personal Information',
            onTap: () => context.push(AppRoutes.editProfile),
          ),
          _ProfileTile(
            icon: Icons.location_on_rounded,
            label: 'Saved Addresses',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.credit_card_rounded,
            label: 'Payment Methods',
            onTap: () {},
          ),

          SizedBox(height: w * 0.02),
          _SectionLabel('Orders & Wallet'),
          _ProfileTile(
            icon: Icons.receipt_long_rounded,
            label: 'Order History',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Wallet & Rewards',
            onTap: () => context.push(AppRoutes.wallet),
          ),
          _ProfileTile(
            icon: Icons.card_giftcard_rounded,
            label: 'Promo Codes',
            onTap: () {},
          ),

          SizedBox(height: w * 0.02),
          _SectionLabel('Support'),
          _ProfileTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _ProfileTile(
            icon: Icons.group_add_rounded,
            label: 'Invite Friends',
            onTap: () => context.push(AppRoutes.inviteFriend),
          ),

          SizedBox(height: w * 0.02),
          _ProfileTile(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            color: AppColors.error,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.05),
        ),
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log out'),
          ),
        ],
      ),
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
  final IconData icon;
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
                child: Icon(
                  icon,
                  color: color ?? AppColors.primary,
                  size: w * 0.048,
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
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: w * 0.05,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
