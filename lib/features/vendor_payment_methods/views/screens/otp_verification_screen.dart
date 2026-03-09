import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../providers/payment_providers.dart';
import '../../viewmodels/otp_verification_viewmodel.dart';
import '../widgets/otp_input_widget.dart';

/// OTP verification screen shown after adding any payment method.
/// Caller must pass [paymentMethodId] and an [onSuccess] callback.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String paymentMethodId;
  final String maskedContact;   // e.g. "+233 *** *** 567" or "v***@mail.com"
  final VoidCallback onSuccess;

  const OtpVerificationScreen({
    super.key,
    required this.paymentMethodId,
    required this.maskedContact,
    required this.onSuccess,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );
    // Kick off countdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpVerificationProvider.notifier).startCountdown();
    });
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final success = await ref
        .read(otpVerificationProvider.notifier)
        .verify(widget.paymentMethodId);

    if (!mounted) return;
    if (success) {
      setState(() => _showSuccess = true);
      _successCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(otpVerificationProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Verify Payment Method'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(otpVerificationProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showSuccess
              ? _SuccessView(scale: _successScale)
              : _FormView(
                  state: state,
                  maskedContact: widget.maskedContact,
                  primary: primary,
                  w: w,
                  onVerify: _verify,
                  onResend: () => ref
                      .read(otpVerificationProvider.notifier)
                      .resend(widget.paymentMethodId),
                  onDigitChanged: (rec) => ref
                      .read(otpVerificationProvider.notifier)
                      .setDigit(rec.$1, rec.$2),
                  onBackspace: (i) => ref
                      .read(otpVerificationProvider.notifier)
                      .clearDigit(i),
                  onPaste: (v) => ref
                      .read(otpVerificationProvider.notifier)
                      .setOtpFromPaste(v),
                ),
        ),
      ),
    );
  }
}

// ── Form view ────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  final OtpVerificationState state;
  final String maskedContact;
  final Color primary;
  final double w;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final ValueChanged<(int, String)> onDigitChanged;
  final ValueChanged<int> onBackspace;
  final ValueChanged<String> onPaste;

  const _FormView({
    required this.state,
    required this.maskedContact,
    required this.primary,
    required this.w,
    required this.onVerify,
    required this.onResend,
    required this.onDigitChanged,
    required this.onBackspace,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = state.status == OtpVerificationStatus.error;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.07, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline_rounded, color: primary, size: 32),
          ),
          const SizedBox(height: 24),

          Text(
            'Enter Verification Code',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'We sent a 6-digit code to\n$maskedContact',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // OTP cells
          OtpInputWidget(
            digits: state.digits,
            hasError: hasError,
            onDigitChanged: onDigitChanged,
            onBackspace: onBackspace,
            onPaste: onPaste,
          ),

          // Error message
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: hasError && state.errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 40),

          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  state.isComplete && !state.isLoading ? onVerify : null,
              child: state.status == OtpVerificationStatus.verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Verify'),
            ),
          ),
          const SizedBox(height: 24),

          // Countdown / resend
          _CountdownResend(
            countdown: state.countdown,
            canResend: state.canResend,
            isResending: state.status == OtpVerificationStatus.resending,
            onResend: onResend,
          ),
        ],
      ),
    );
  }
}

// ── Countdown + resend ────────────────────────────────────────────────────────

class _CountdownResend extends StatelessWidget {
  final int countdown;
  final bool canResend;
  final bool isResending;
  final VoidCallback onResend;

  const _CountdownResend({
    required this.countdown,
    required this.canResend,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (isResending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
          ),
          const SizedBox(width: 8),
          const Text(
            'Resending code…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      );
    }

    if (!canResend) {
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          children: [
            const TextSpan(text: 'Resend code in '),
            TextSpan(
              text: '${countdown}s',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      );
    }

    return TextButton(
      onPressed: onResend,
      child: const Text('Resend Code'),
    );
  }
}

// ── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final Animation<double> scale;

  const _SuccessView({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Verified!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your payment method is now active.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
