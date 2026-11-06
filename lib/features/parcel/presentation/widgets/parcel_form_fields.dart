import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:gopady/constant/app_tokens.dart';

/// Shared label + text field used by the parcel wizard's detail forms
/// (delivery stops, sender contact) so they stay visually identical.
class ParcelFieldLabel extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? hint;
  final bool required;
  final double w;

  /// Optional action aligned to the right edge (e.g. a contacts button).
  final Widget? trailing;

  const ParcelFieldLabel({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.w,
    this.required = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: AppColors.textHint, size: w * 0.036),
        SizedBox(width: w * 0.018),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (required) ...[
          SizedBox(width: w * 0.008),
          Text(
            '*',
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
        ],
        if (hint != null) ...[
          SizedBox(width: w * 0.015),
          Text(
            hint!,
            style: TextStyle(fontSize: w * 0.028, color: AppColors.textHint),
          ),
        ],
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class ParcelTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final String? errorText;
  final double w;

  const ParcelTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.w,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.maxLength,
    this.errorText,
  });

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(w * 0.03),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: w * 0.036,
        color: AppColors.textPrimary,
        fontFamily: AppFonts.body,
      ),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        counterText: '',
        hintStyle: TextStyle(
          fontSize: w * 0.034,
          color: AppColors.textHint,
          fontFamily: AppFonts.body,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.034,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),
    );
  }
}
