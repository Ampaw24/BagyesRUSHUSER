import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/business_details_data.dart';
import '../widgets/vendor_text_field.dart';

/// Step 2 - Password creation, isolated from business details
class CreatePasswordStep extends StatefulWidget {
  final BusinessDetailsData data;
  final ValueChanged<BusinessDetailsData> onChanged;

  const CreatePasswordStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<CreatePasswordStep> createState() => _CreatePasswordStepState();
}

class _CreatePasswordStepState extends State<CreatePasswordStep> {
  late TextEditingController _passwordCtrl;
  late TextEditingController _confirmPasswordCtrl;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl = TextEditingController(text: widget.data.password);
    _confirmPasswordCtrl = TextEditingController(text: widget.data.confirmPassword);
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.data.copyWith(
        password: _passwordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.03),
            color: AppColors.primary.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            'Create a strong password to secure your vendor account. Use at least 8 characters with a mix of letters, numbers, and symbols.',
            style: TextStyle(
              fontSize: size.width * 0.032,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.03),

        // Password
        VendorTextField(
          label: 'Password',
          hint: 'Min. 8 characters',
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          onChanged: (_) => _emit(),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textSecondary,
              size: size.width * 0.05,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.022),

        // Confirm Password
        VendorTextField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          controller: _confirmPasswordCtrl,
          obscureText: !_showConfirmPassword,
          onChanged: (_) => _emit(),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            child: Icon(
              _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: AppColors.textSecondary,
              size: size.width * 0.05,
            ),
          ),
        ),

        // Live match indicator
        if (_confirmPasswordCtrl.text.isNotEmpty) ...[
          SizedBox(height: size.height * 0.012),
          Row(
            children: [
              Icon(
                _passwordCtrl.text == _confirmPasswordCtrl.text
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: size.width * 0.04,
                color: _passwordCtrl.text == _confirmPasswordCtrl.text
                    ? AppColors.success
                    : AppColors.error,
              ),
              SizedBox(width: size.width * 0.02),
              Text(
                _passwordCtrl.text == _confirmPasswordCtrl.text
                    ? 'Passwords match'
                    : 'Passwords do not match',
                style: TextStyle(
                  fontSize: size.width * 0.03,
                  color: _passwordCtrl.text == _confirmPasswordCtrl.text
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
