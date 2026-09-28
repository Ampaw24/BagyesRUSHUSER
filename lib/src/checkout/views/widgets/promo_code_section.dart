import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';

/// Checkout promo-code entry: collapsed "Have a promo code?" row → input
/// with Apply → applied chip with savings + Remove. The discount shown is
/// always the backend's (from the cart), never computed here.
class PromoCodeSection extends StatefulWidget {
  const PromoCodeSection({
    super.key,
    required this.appliedCode,
    required this.description,
    required this.discount,
    required this.currency,
    required this.isApplying,
    required this.error,
    required this.onApply,
    required this.onRemove,
    required this.onEdited,
  });

  final String? appliedCode;
  final String? description;
  final double? discount;
  final String currency;
  final bool isApplying;
  final String? error;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;

  /// Fired on typing so a stale validation error can be cleared.
  final VoidCallback onEdited;

  @override
  State<PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends State<PromoCodeSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant PromoCodeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justApplied =
        oldWidget.appliedCode == null && widget.appliedCode != null;
    if (justApplied) {
      HapticFeedback.lightImpact();
      _controller.clear();
      _expanded = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty || widget.isApplying) return;
    _focusNode.unfocus();
    widget.onApply(code);
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (widget.appliedCode != null) {
      child = _AppliedPromoChip(
        key: const ValueKey('applied'),
        code: widget.appliedCode!,
        description: widget.description,
        discount: widget.discount,
        currency: widget.currency,
        isRemoving: widget.isApplying,
        onRemove: widget.onRemove,
      );
    } else if (_expanded || widget.error != null) {
      child = _PromoInput(
        key: const ValueKey('input'),
        controller: _controller,
        focusNode: _focusNode,
        isApplying: widget.isApplying,
        error: widget.error,
        onSubmit: _submit,
        onChanged: (_) {
          if (widget.error != null) widget.onEdited();
        },
      );
    } else {
      child = _CollapsedPromoRow(key: const ValueKey('collapsed'), onTap: _expand);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}

class _CollapsedPromoRow extends StatelessWidget {
  const _CollapsedPromoRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(w * 0.03),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined,
                color: AppColors.primary, size: w * 0.05),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(
                'Have a promo code?',
                style: TextStyle(
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              'Add',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoInput extends StatelessWidget {
  const _PromoInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isApplying,
    required this.error,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isApplying;
  final String? error;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isApplying,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LengthLimitingTextInputFormatter(32),
                  _UpperCaseFormatter(),
                ],
                onChanged: onChanged,
                onSubmitted: (_) => onSubmit(),
                style: TextStyle(
                  fontSize: w * 0.036,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  prefixIcon: Icon(
                    Icons.local_offer_outlined,
                    color: hasError ? AppColors.error : AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: hasError
                        ? const BorderSide(color: AppColors.error)
                        : BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.025),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => SizedBox(
                height: w * 0.13,
                child: ElevatedButton(
                  onPressed: isApplying || value.text.trim().isEmpty
                      ? null
                      : onSubmit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                  ),
                  child: isApplying
                      ? SizedBox(
                          width: w * 0.045,
                          height: w * 0.045,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          SizedBox(height: w * 0.015),
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: w * 0.04),
              SizedBox(width: w * 0.015),
              Expanded(
                child: Text(
                  error!,
                  style: TextStyle(fontSize: w * 0.03, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AppliedPromoChip extends StatelessWidget {
  const _AppliedPromoChip({
    super.key,
    required this.code,
    required this.description,
    required this.discount,
    required this.currency,
    required this.isRemoving,
    required this.onRemove,
  });

  final String code;
  final String? description;
  final double? discount;
  final String currency;
  final bool isRemoving;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final savings = discount != null && discount! > 0
        ? 'You save ${formatMoney(discount, currency: currency)}'
        : null;
    final subtitle = [
      ?savings,
      if (description != null && description!.isNotEmpty) description!,
    ].join(' · ');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: w * 0.055),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code applied',
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (isRemoving)
            SizedBox(
              width: w * 0.045,
              height: w * 0.045,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onRemove,
              child: Text(
                'Remove',
                style: TextStyle(
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
