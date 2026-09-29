import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';

/// Collects the customer's 4-digit delivery PIN before a vendor can mark an
/// order delivered — delivery is normally the rider's to confirm. The PIN is
/// verified by the backend: [onSubmit] returns its error message (shown
/// inline, e.g. a wrong PIN) or null on success.
class DeliveryPinSheet extends StatefulWidget {
  const DeliveryPinSheet._({
    required this.customerName,
    required this.onSubmit,
  });

  final String customerName;
  final Future<String?> Function(String pin) onSubmit;

  static const int pinLength = 4;

  /// Resolves true once the order has been marked delivered.
  static Future<bool> show(
    BuildContext context, {
    required String customerName,
    required Future<String?> Function(String pin) onSubmit,
  }) async {
    final delivered = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryPinSheet._(
        customerName: customerName,
        onSubmit: onSubmit,
      ),
    );
    return delivered ?? false;
  }

  @override
  State<DeliveryPinSheet> createState() => _DeliveryPinSheetState();
}

class _DeliveryPinSheetState extends State<DeliveryPinSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  String? _error;

  bool get _isComplete => _controller.text.length == DeliveryPinSheet.pinLength;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String _) => setState(() => _error = null);

  Future<void> _submit() async {
    if (!_isComplete || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final error = await widget.onSubmit(_controller.text);
    if (!mounted) return;

    if (error == null) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      return;
    }

    HapticFeedback.heavyImpact();
    _controller.clear();
    setState(() {
      _isSubmitting = false;
      _error = error;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final name = widget.customerName.trim();
    final error = _error;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.03, w * 0.06, w * 0.05),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.12,
                height: w * 0.012,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(w),
                ),
              ),
              SizedBox(height: w * 0.05),
              Container(
                width: w * 0.16,
                height: w * 0.16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSquareLock02,
                  color: AppColors.primary,
                  size: w * 0.08,
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                'Confirm delivery',
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.02),
              Text(
                'Delivery is normally confirmed by the rider. To confirm it '
                'yourself, ask ${name.isEmpty ? 'the customer' : name} for '
                'their ${DeliveryPinSheet.pinLength}-digit delivery PIN.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.034,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: w * 0.06),
              _PinInput(
                controller: _controller,
                focusNode: _focusNode,
                hasError: error != null,
                enabled: !_isSubmitting,
                onChanged: _onChanged,
                onSubmitted: _submit,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(top: w * 0.03),
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: w * 0.06),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isComplete && !_isSubmitting ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: Size.fromHeight(w * 0.13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox.square(
                          dimension: w * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm Delivery',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four digit boxes driven by one invisible numeric field laid over them,
/// so taps anywhere on the boxes open the number pad.
class _PinInput extends StatelessWidget {
  const _PinInput({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pin = controller.text;
    final boxSize = w * 0.15;

    return SizedBox(
      height: boxSize,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < DeliveryPinSheet.pinLength; i++) ...[
                if (i > 0) SizedBox(width: w * 0.03),
                _PinBox(
                  digit: i < pin.length ? pin[i] : null,
                  isActive: enabled && i == pin.length,
                  hasError: hasError,
                  size: boxSize,
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                enabled: enabled,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(DeliveryPinSheet.pinLength),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({
    required this.digit,
    required this.isActive,
    required this.hasError,
    required this.size,
  });

  final String? digit;
  final bool isActive;
  final bool hasError;
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: digit == null
            ? AppColors.surfaceVariant
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: borderColor,
          width: isActive || hasError ? 1.8 : 1,
        ),
      ),
      child: Text(
        digit ?? '',
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
