import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';

enum _Phase { verifying, paid, processing }

/// Shown the moment the customer is back from the payment gateway: a
/// "Confirming your payment…" state while [verification] runs, then either
/// a success tick that closes itself, or a "still processing" note. Can't
/// be dismissed mid-check, so nothing can be tapped while the charge is
/// being confirmed.
class PaymentConfirmationDialog extends StatefulWidget {
  const PaymentConfirmationDialog._({required this.result});

  /// The verification's outcome: `bool` (paid or not) or a
  /// [_VerificationError].
  final Future<Object> result;

  static const successHold = Duration(milliseconds: 1800);

  /// Returns [OrderPaymentOutcome.paid] or [OrderPaymentOutcome.processing].
  /// If [verification] throws, the dialog closes and the error is rethrown
  /// so the caller can surface it.
  static Future<OrderPaymentOutcome> show(
    BuildContext context, {
    required Future<bool> verification,
  }) async {
    // Handled from the start: verification can fail before the dialog's
    // first frame, and must not surface as an uncaught error meanwhile.
    final settled = verification.then<Object>(
      (isPaid) => isPaid,
      onError: (Object error, StackTrace stackTrace) =>
          _VerificationError(error, stackTrace),
    );
    final result = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: PaymentConfirmationDialog._(result: settled),
      ),
    );
    if (result is OrderPaymentOutcome) return result;
    if (result is _VerificationError) {
      Error.throwWithStackTrace(result.error, result.stackTrace);
    }
    return OrderPaymentOutcome.processing;
  }

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _VerificationError {
  const _VerificationError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog> {
  _Phase _phase = _Phase.verifying;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    widget.result.then((result) {
      if (result is _VerificationError) {
        _onFailed(result);
      } else {
        _onVerified(result == true);
      }
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  void _onVerified(bool isPaid) {
    if (!mounted) return;
    if (isPaid) HapticFeedback.mediumImpact();
    setState(() => _phase = isPaid ? _Phase.paid : _Phase.processing);
    if (isPaid) {
      _autoClose = Timer(
        PaymentConfirmationDialog.successHold,
        () => _close(OrderPaymentOutcome.paid),
      );
    }
  }

  void _onFailed(_VerificationError error) {
    if (mounted) Navigator.of(context).pop(error);
  }

  void _close(OrderPaymentOutcome outcome) {
    _autoClose?.cancel();
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: EdgeInsets.symmetric(horizontal: w * 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(w * 0.06),
      ),
      // Scrollable so a short landscape screen can never clip the content.
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.07, w * 0.06, w * 0.05),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_phase) {
              _Phase.verifying => const _VerifyingView(
                key: ValueKey('verifying'),
              ),
              _Phase.paid => _PaidView(
                key: const ValueKey('paid'),
                onContinue: () => _close(OrderPaymentOutcome.paid),
              ),
              _Phase.processing => _ProcessingView(
                key: const ValueKey('processing'),
                onOk: () => _close(OrderPaymentOutcome.processing),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _VerifyingView extends StatelessWidget {
  const _VerifyingView({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w * 0.14,
          height: w * 0.14,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: w * 0.06),
        _Title('Confirming your payment…', w: w),
        SizedBox(height: w * 0.02),
        _Body('This only takes a moment. Please don\'t close the app.', w: w),
      ],
    );
  }
}

class _PaidView extends StatelessWidget {
  const _PaidView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w * 0.3,
          height: w * 0.3,
          child: Lottie.asset(
            'assets/success_loader.json',
            repeat: false,
            errorBuilder: (_, _, _) => Icon(
              Icons.check_circle_rounded,
              size: w * 0.22,
              color: AppColors.success,
            ),
          ),
        ),
        SizedBox(height: w * 0.02),
        _Title('Payment successful', w: w),
        SizedBox(height: w * 0.02),
        _Body('Your payment is confirmed and your order is on its way.', w: w),
        SizedBox(height: w * 0.06),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, w * 0.12),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).shortestSide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.045),
          decoration: BoxDecoration(
            color: AppColors.paymentPending.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.hourglass_top_rounded,
            size: w * 0.12,
            color: AppColors.paymentPending,
          ),
        ),
        SizedBox(height: w * 0.05),
        _Title('Payment processing', w: w),
        SizedBox(height: w * 0.02),
        _Body(
          'Your provider is still confirming the charge. We\'ll update your '
          'order automatically — no need to pay again.',
          w: w,
        ),
        SizedBox(height: w * 0.06),
        ElevatedButton(
          onPressed: onOk,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, w * 0.12),
          ),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {required this.w});

  final String text;
  final double w;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: w * 0.05,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text, {required this.w});

  final String text;
  final double w;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: w * 0.035,
      height: 1.4,
      color: AppColors.textSecondary,
    ),
  );
}
