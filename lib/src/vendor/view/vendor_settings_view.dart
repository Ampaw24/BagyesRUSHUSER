import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../viewmodel/settings_viewmodel.dart';

class VendorSettingsView extends StatefulWidget {
  const VendorSettingsView({super.key});

  @override
  State<VendorSettingsView> createState() => _VendorSettingsViewState();
}

class _VendorSettingsViewState extends State<VendorSettingsView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SettingsViewModel>().loadProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w * 0.05;

    return Consumer<SettingsViewModel>(
      builder: (context, vm, _) {
        if (vm.state.status == SettingsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.state.status == SettingsStatus.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: w * 0.1, color: AppColors.error),
                SizedBox(height: w * 0.03),
                Text(
                  vm.state.errorMessage ?? 'Something went wrong',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.04),
                ElevatedButton(
                  onPressed: vm.loadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final profile = vm.state.profile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad, w * 0.03, horizontalPad, 0,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: w * 0.055,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: w * 0.04),

            // ── Content ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad, 0, horizontalPad, w * 0.25,
                ),
                children: [
                  // Profile card
                  Container(
                    padding: EdgeInsets.all(w * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.035),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: w * 0.07,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            profile != null && profile.businessName.isNotEmpty
                                ? profile.businessName[0].toUpperCase()
                                : 'V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.06,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.businessName ?? 'Your Business',
                                style: TextStyle(
                                  fontSize: w * 0.04,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: w * 0.005),
                              Text(
                                profile?.email ?? '',
                                style: TextStyle(
                                  fontSize: w * 0.032,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                          size: w * 0.06,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: w * 0.04),

                  // Settings sections
                  _SectionTitle(title: 'Store'),
                  SizedBox(height: w * 0.02),
                  _SettingsTile(
                    icon: Icons.store_rounded,
                    title: 'Store Information',
                    subtitle: profile?.address ?? 'Manage your store details',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.schedule_rounded,
                    title: 'Operating Hours',
                    subtitle: profile != null
                        ? '${profile.openingTime} - ${profile.closingTime}'
                        : 'Set your hours',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.delivery_dining_rounded,
                    title: 'Delivery Radius',
                    subtitle: profile != null
                        ? '${profile.deliveryRadiusKm} km'
                        : 'Set delivery area',
                    onTap: () {},
                  ),
                  SizedBox(height: w * 0.04),

                  _SectionTitle(title: 'Account'),
                  SizedBox(height: w * 0.02),
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    title: 'Personal Information',
                    subtitle: profile?.ownerName ?? 'Manage your account',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.payment_rounded,
                    title: 'Payout Settings',
                    subtitle: 'Bank & mobile money',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Order alerts & updates',
                    onTap: () {},
                  ),
                  SizedBox(height: w * 0.04),

                  _SectionTitle(title: 'Support'),
                  SizedBox(height: w * 0.02),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'FAQs and support',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    titleColor: AppColors.error,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Text(
      title,
      style: TextStyle(
        fontSize: w * 0.032,
        fontWeight: FontWeight.w600,
        color: AppColors.textHint,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.025),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
              child: Icon(icon, size: w * 0.05, color: AppColors.textSecondary),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: w * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}
