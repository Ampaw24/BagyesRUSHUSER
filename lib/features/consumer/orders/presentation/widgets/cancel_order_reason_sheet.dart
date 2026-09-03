import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Bottom sheet collecting a required cancellation reason before a customer
/// cancels an order — a predefined list, plus "Other" which reveals a
/// free-text field. Returns the chosen reason text via [Navigator.pop], or
/// `null` if dismissed without confirming.
class CancelOrderReasonSheet extends StatefulWidget {
  const CancelOrderReasonSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelOrderReasonSheet(),
    );
  }

  @override
  State<CancelOrderReasonSheet> createState() => _CancelOrderReasonSheetState();
}

class _CancelOrderReasonSheetState extends State<CancelOrderReasonSheet> {
  static const _otherCode = 'other';
  static const _minOtherLength = 5;
  static const _maxOtherLength = 255;

  static const _reasons = <(String code, String label)>[
    ('changed_mind', 'Changed my mind'),
    ('ordered_by_mistake', 'Ordered by mistake'),
    ('taking_too_long', 'Order is taking too long'),
    ('wrong_address', 'Wrong delivery address'),
    ('found_better_price', 'Found a better price elsewhere'),
    ('payment_issue', 'Payment or payment method issue'),
    (_otherCode, 'Other'),
  ];

  String? _selectedCode;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  bool get _isOtherSelected => _selectedCode == _otherCode;

  String? get _otherErrorText {
    final len = _otherController.text.trim().length;
    if (len == 0 || len >= _minOtherLength) return null;
    return 'Please enter at least $_minOtherLength characters';
  }

  bool get _canConfirm {
    if (_selectedCode == null) return false;
    if (_isOtherSelected) {
      return _otherController.text.trim().length >= _minOtherLength;
    }
    return true;
  }

  void _selectReason(String code) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCode = code);
  }

  void _confirm() {
    final reason = _isOtherSelected
        ? _otherController.text.trim()
        : _reasons.firstWhere((r) => r.$1 == _selectedCode).$2;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: w * 0.1,
                  height: w * 0.01,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(w * 0.01),
                  ),
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                'Cancel Order',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.015),
              Text(
                'Tell us why you’re cancelling — this helps us improve.',
                style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
              ),
              SizedBox(height: w * 0.04),
              ..._reasons.map(
                (r) => _ReasonTile(
                  label: r.$2,
                  selected: _selectedCode == r.$1,
                  onTap: () => _selectReason(r.$1),
                ),
              ),
              if (_isOtherSelected) ...[
                SizedBox(height: w * 0.015),
                TextField(
                  controller: _otherController,
                  maxLength: _maxOtherLength,
                  maxLines: 3,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tell us more...',
                    errorText: _otherErrorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                  ),
                ),
              ],
              SizedBox(height: w * 0.02),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirm ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(vertical: w * 0.035),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                  ),
                  child: Text(
                    'Cancel Order',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.025),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.07) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.03),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.036,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: w * 0.05,
                color: selected ? AppColors.primary : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
