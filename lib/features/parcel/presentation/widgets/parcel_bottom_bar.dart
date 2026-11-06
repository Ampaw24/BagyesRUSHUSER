import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';
import 'package:gopady/src/parcel/viewmodel/send_parcel_viewmodel.dart';

class ParcelBottomBar extends StatelessWidget {
  final ParcelStep currentStep;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final bool isLoading;

  /// Hidden once the parcel is booked, so it can't be edited and booked twice.
  final bool showBack;

  /// Final-step button text — e.g. "Pay GHS 18.05", or "Confirm booking"
  /// when the wallet covers everything and there's nothing to pay.
  final String confirmLabel;

  /// True when booking charges nothing to mobile money (wallet covers it).
  final bool confirmIsFree;

  const ParcelBottomBar({
    super.key,
    required this.currentStep,
    required this.canProceed,
    required this.onBack,
    required this.onContinue,
    this.isLoading = false,
    this.showBack = true,
    this.confirmLabel = 'Confirm & Pay',
    this.confirmIsFree = false,
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
        w * 0.03,
        w * 0.05,
        w * 0.03 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.06),
            blurRadius: w * 0.05,
            offset: Offset(0, -w * 0.01),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isFirstStep && showBack) ...[
            _BackButton(w: w, onTap: onBack),
            SizedBox(width: w * 0.03),
          ],
          Expanded(
            child: _ContinueButton(
              label: _isFinalStep ? confirmLabel : 'Continue',
              icon: !_isFinalStep
                  ? HugeIcons.strokeRoundedArrowRight02
                  : confirmIsFree
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : HugeIcons.strokeRoundedCreditCard,
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

class _BackButton extends StatelessWidget {
  final double w;
  final VoidCallback onTap;

  const _BackButton({required this.w, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = w * 0.135;
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: AppColors.surfaceVariant,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft02,
                color: AppColors.textPrimary,
                size: w * 0.055,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final enabledLook = canProceed || isLoading;
    final fg = enabledLook ? AppColors.onPrimary : AppColors.textHint;

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outExpo,
      height: w * 0.135,
      decoration: ShapeDecoration(
        color: enabledLook ? AppColors.primary : AppColors.surfaceVariant,
        shape: const StadiumBorder(),
        shadows: enabledLook ? AppShadows.elevated : const [],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: active ? onTap : null,
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: w * 0.05,
                    height: w * 0.05,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.onPrimary,
                    ),
                  ),
                )
              // Label changes ("Pay GHS 30.40" → "Pay GHS 18.05" →
              // "Confirm") roll in from below instead of snapping.
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(label),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      HugeIcon(icon: icon, color: fg, size: w * 0.045),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
