import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';
import '../../models/vendor_enums.dart';

/// Step 5 - OTP verification for vendor phone/email
class VerificationStep extends StatefulWidget {
  final String phone;
  final String email;
  final VendorRegistrationStatus status;
  final bool isVerified;
  final VoidCallback onSendOtp;
  final ValueChanged<String> onVerifyOtp;

  const VerificationStep({
    super.key,
    required this.phone,
    required this.email,
    required this.status,
    required this.isVerified,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  @override
  State<VerificationStep> createState() => _VerificationStepState();
}

class _VerificationStepState extends State<VerificationStep>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _checkAnimController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VerificationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVerified && !oldWidget.isVerified) {
      _checkAnimController.forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _checkAnimController.dispose();
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpValue.length == 6) {
      widget.onVerifyOtp(_otpValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = widget.status == VendorRegistrationStatus.loading;
    final otpSent = widget.status == VendorRegistrationStatus.otpSent ||
        widget.isVerified;

    return Column(
      children: [
        SizedBox(height: size.height * 0.02),

        // Phone icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size.width * 0.2,
          height: size.width * 0.2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isVerified
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
          ),
          child: widget.isVerified
              ? ScaleTransition(
                  scale: _checkScale,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: size.width * 0.1,
                  ),
                )
              : Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.primary,
                  size: size.width * 0.08,
                ),
        ),

        SizedBox(height: size.height * 0.025),

        Text(
          widget.isVerified
              ? 'Phone Verified!'
              : otpSent
                  ? 'Enter the code'
                  : 'Verify your phone number',
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          widget.isVerified
              ? 'Your phone number has been verified successfully.'
              : otpSent
                  ? 'We sent a 6-digit code to +233 ${widget.phone}'
                  : 'We\'ll send a verification code to +233 ${widget.phone}',
          style: TextStyle(
            fontSize: size.width * 0.034,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: size.height * 0.04),

        if (!widget.isVerified && !otpSent) ...[
          // Send OTP button
          _buildSendButton(size, isLoading),
        ],

        if (otpSent && !widget.isVerified) ...[
          // OTP input fields
          _buildOtpFields(size),
          SizedBox(height: size.height * 0.03),
          // Resend link
          GestureDetector(
            onTap: isLoading ? null : widget.onSendOtp,
            child: Text(
              'Didn\'t receive a code? Resend',
              style: TextStyle(
                fontSize: size.width * 0.034,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        if (isLoading && !widget.isVerified) ...[
          SizedBox(height: size.height * 0.03),
          SizedBox(
            width: size.width * 0.06,
            height: size.width * 0.06,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSendButton(Size size, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : widget.onSendOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.width * 0.035),
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: size.width * 0.03,
              offset: Offset(0, size.height * 0.006),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Send Verification Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields(Size size) {
    final fieldSize = size.width * 0.12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: fieldSize,
          height: fieldSize * 1.2,
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.01),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.03),
              color: AppColors.surfaceVariant,
              border: Border.all(
                color: _focusNodes[i].hasFocus
                    ? AppColors.primary
                    : _controllers[i].text.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                width: _focusNodes[i].hasFocus ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (val) => _onDigitChanged(i, val),
            ),
          ),
        );
      }),
    );
  }
}
