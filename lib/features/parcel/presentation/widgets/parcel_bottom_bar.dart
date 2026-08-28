import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../viewmodels/send_parcel_viewmodel.dart';

class ParcelBottomBar extends StatelessWidget {
  final ParcelStep currentStep;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isLoading;

  const ParcelBottomBar({
    super.key,
    required this.currentStep,
    required this.canProceed,
    required this.onBack,
    required this.onContinue,
    this.isLoading = false,
  });

  bool get _isFirstStep => currentStep == ParcelStep.packageType;
  bool get _isFinalStep => currentStep == ParcelStep.summary;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.035,
        w * 0.05,
        w * 0.035 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!_isFirstStep) ...[
            _BackButton(w: w, onTap: onBack),
            SizedBox(width: w * 0.03),
          ],
          Expanded(
            child: _ContinueButton(
              label: _isFinalStep ? 'Confirm & Pay' : 'Continue',
              icon: _isFinalStep
                  ? HugeIcons.strokeRoundedCreditCard
                  : HugeIcons.strokeRoundedArrowRight01,
              canProceed: canProceed && !isLoading,
              isLoading: isLoading,
              onTap: onContinue,
              w: w,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final double w;
  final VoidCallback onTap;

  const _BackButton({required this.w, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.038),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border),
        ),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: AppColors.textPrimary,
          size: w * 0.055,
        ),
      ),
    );
  }
}

// ── Continue button ───────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final String label;
  final List<List<dynamic>> icon;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback onTap;
  final double w;

  const _ContinueButton({
    required this.label,
    required this.icon,
    required this.canProceed,
    required this.onTap,
    required this.w,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = canProceed && !isLoading;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: w * 0.042),
        decoration: BoxDecoration(
          color: (canProceed || isLoading) ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(w * 0.03),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: w * 0.05,
                  height: w * 0.05,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w700,
                      color: canProceed ? Colors.white : AppColors.textHint,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  HugeIcon(
                    icon: icon,
                    color: canProceed ? Colors.white : AppColors.textHint,
                    size: w * 0.045,
                  ),
                ],
              ),
      ),
    );
  }
}
