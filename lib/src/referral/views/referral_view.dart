import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/referral/widgets/referral_code_card.dart';

/// Refer & Earn screen.
///
/// Shows the customer's real referral code and how many friends have
/// signed up with it — both come straight off the user profile
/// (`referral_code` / `referral_count`), the only referral data the backend
/// currently tracks. There is intentionally no reward ledger, referral
/// history, or per-referral status list here: the backend doesn't expose
/// that yet, and this screen shouldn't invent numbers it can't back up.
class ReferralView extends StatelessWidget {
  const ReferralView({super.key});

  String _referralCode(BuildContext context) =>
      context.watch<CurrentUserProvider>().user?.profile?.referralCode ?? '';

  num _referralCount(BuildContext context) =>
      context.watch<CurrentUserProvider>().user?.profile?.referralCount ?? 0;

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied')));
  }

  void _shareCode(String code) {
    if (code.isEmpty) return;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join me on bagyesRUSH! Use my referral code $code when you sign up.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final code = _referralCode(context);
    final count = _referralCount(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        title: const Text(
          'Refer & Earn',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(w * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RewardHero(w: w, code: code, count: count),
              SizedBox(height: w * 0.045),
              if (code.isNotEmpty)
                ReferralCodeCard(
                  code: code,
                  onCopy: () => _copyCode(context, code),
                  onShare: () => _shareCode(code),
                )
              else
                Text(
                  'Your referral code isn\'t available yet. Pull to refresh your profile and try again.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (w * 0.035).clamp(12.0, 15.0),
                  ),
                ),
              SizedBox(height: w * 0.07),
              _HowItWorksSection(w: w),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardHero extends StatelessWidget {
  final double w;
  final String code;
  final num count;

  const _RewardHero({required this.w, required this.code, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedGift,
                color: Colors.white,
                size: w * 0.07,
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Text(
                  'Invite friends to bagyesRUSH',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: (w * 0.045).clamp(16.0, 20.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.02),
          Text(
            'Share your code with friends and family. When they sign up, your referral count grows.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: (w * 0.033).clamp(12.0, 15.0),
            ),
          ),
          SizedBox(height: w * 0.04),
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedUserGroup,
                color: Colors.white,
                size: w * 0.05,
              ),
              SizedBox(width: w * 0.02),
              Text(
                count > 0
                    ? '${count.toInt()} ${count == 1 ? 'friend' : 'friends'} referred so far'
                    : 'No referrals yet — share your code to get started',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: (w * 0.033).clamp(12.0, 15.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  final double w;

  const _HowItWorksSection({required this.w});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Share your code', 'Send your referral code to a friend via any app.'),
      (
        'They sign up',
        'Your friend enters your code when creating their account.',
      ),
      (
        'Your count grows',
        'Every friend who joins with your code adds to your referral total.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: (w * 0.042).clamp(15.0, 18.0),
          ),
        ),
        SizedBox(height: w * 0.035),
        for (var i = 0; i < steps.length; i++) ...[
          _HowItWorksStep(
            w: w,
            index: i + 1,
            title: steps[i].$1,
            description: steps[i].$2,
          ),
          if (i != steps.length - 1) SizedBox(height: w * 0.03),
        ],
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final double w;
  final int index;
  final String title;
  final String description;

  const _HowItWorksStep({
    required this.w,
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: w * 0.08,
          height: w * 0.08,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: (w * 0.035).clamp(12.0, 15.0),
            ),
          ),
        ),
        SizedBox(width: w * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: (w * 0.036).clamp(13.0, 16.0),
                ),
              ),
              SizedBox(height: w * 0.01),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: (w * 0.033).clamp(12.0, 14.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
