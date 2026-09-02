import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../viewmodels/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';

class KycVerificationView extends StatefulWidget {
  const KycVerificationView({super.key});

  @override
  State<KycVerificationView> createState() => _KycVerificationViewState();
}

class _KycVerificationViewState extends State<KycVerificationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  AuthViewmodel? _vm;
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<AuthViewmodel>();
      _vm!.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onAuthStateChanged);
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final vm = context.read<AuthViewmodel>();
    final state = vm.state;

    if (state is OTPSent) {
      vm.resetState();
      setState(() => _sending = false);
      context.push(AppRoutes.otp);
    } else if (state is AuthError) {
      vm.resetState();
      setState(() => _sending = false);
      CustomDialog.showError(
        context: context,
        title: state.title,
        subtitle: state.message,
      );
    } else if (state is RequestingOTP) {
      setState(() => _sending = true);
    }
  }

  void _onVerifyPressed() {
    if (_sending) return;
    final phone = context.read<CurrentUserProvider>().user?.phone ?? '';
    if (phone.isEmpty) {
      CustomDialog.showError(
        context: context,
        title: 'Phone Number Missing',
        subtitle:
            'We could not find your phone number. Please log out and sign in again.',
      );
      return;
    }
    context.read<AuthViewmodel>().sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final phone = context.select<CurrentUserProvider, String>(
      (p) => p.user?.phone ?? '',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
              child: Column(
                children: [
                  SizedBox(height: sh * 0.08),

                  // ── Illustration badge ──
                  _buildIllustration(sw),
                  SizedBox(height: sh * 0.04),

                  // ── Title ──
                  Text(
                    'Verify Your Phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (sw * 0.068).clamp(22, 32),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: sh * 0.012),

                  // ── Subtitle ──
                  Text(
                    'We\'ll send a verification code to your registered '
                    'phone number to confirm your identity.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (sw * 0.038).clamp(13, 17),
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: sh * 0.035),

                  // ── Phone number chip ──
                  if (phone.isNotEmpty) _buildPhoneChip(sw, phone),

                  const Spacer(),

                  // ── Verify button ──
                  _buildVerifyButton(sw, sh),
                  SizedBox(height: sh * 0.018),

                  // ── Logout link ──
                  _buildLogoutLink(sw),
                  SizedBox(height: sh * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(double sw) {
    final badgeSize = sw * 0.32;
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: badgeSize * 0.65,
          height: badgeSize * 0.65,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSmartPhone01,
              size: badgeSize * 0.35,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneChip(double sw, String phone) {
    final masked = phone.length > 4
        ? '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}'
        : phone;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.05,
        vertical: sw * 0.025,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCall,
            size: (sw * 0.045).clamp(16, 22),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: sw * 0.025),
          Text(
            masked,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (sw * 0.04).clamp(14, 18),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(double sw, double sh) {
    return InkWell(
      onTap: _sending ? null : _onVerifyPressed,
      borderRadius: BorderRadius.circular(sw * 0.035),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: (sh * 0.068).clamp(48, 60),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sw * 0.035),
          color: _sending
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.primary,
          boxShadow: _sending
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: _sending
              ? SpinKitCircle(size: sw * 0.055, color: Colors.white)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSent,
                      size: (sw * 0.05).clamp(18, 22),
                      color: Colors.white,
                    ),
                    SizedBox(width: sw * 0.025),
                    Text(
                      'Send Verification Code',
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        color: Colors.white,
                        fontSize: (sw * 0.042).clamp(14, 18),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLogoutLink(double sw) {
    return TextButton(
      onPressed: () async {
        await context.read<AuthViewmodel>().logout();
        if (mounted) context.go(AppRoutes.login);
      },
      child: Text(
        'Log out',
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: (sw * 0.036).clamp(12, 16),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
