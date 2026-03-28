import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';

/// Reusable animated text field for the vendor registration flow
class VendorTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final String? errorText;
  final FocusNode? focusNode;

  const VendorTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.errorText,
    this.focusNode,
  });

  @override
  State<VendorTextField> createState() => _VendorTextFieldState();
}

class _VendorTextFieldState extends State<VendorTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    _focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final radius = BorderRadius.circular(size.width * 0.032);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.008),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          style: TextStyle(
            fontSize: size.width * 0.038,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontWeight: FontWeight.w400,
              fontSize: size.width * 0.036,
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.018,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : Colors.grey[200]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: Colors.grey[100]!, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          SizedBox(height: size.height * 0.005),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: size.width * 0.03,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
