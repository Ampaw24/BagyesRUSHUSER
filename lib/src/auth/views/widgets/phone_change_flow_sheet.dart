import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import '../../repositories/auth_repository.dart';

enum PhoneChangeStep {
  confirmSend,
  verifyOtp,
  enterNewPhone,
}

class PhoneChangeFlowSheet extends StatefulWidget {
  final String oldPhone;
  final Future<void> Function(String newPhone) onPhoneUpdated;

  const PhoneChangeFlowSheet({
    super.key,
    required this.oldPhone,
    required this.onPhoneUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String oldPhone,
    required Future<void> Function(String newPhone) onPhoneUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhoneChangeFlowSheet(
        oldPhone: oldPhone,
        onPhoneUpdated: onPhoneUpdated,
      ),
    );
  }

  @override
  State<PhoneChangeFlowSheet> createState() => _PhoneChangeFlowSheetState();
}

class _PhoneChangeFlowSheetState extends State<PhoneChangeFlowSheet> {
  PhoneChangeStep _step = PhoneChangeStep.confirmSend;
  bool _loading = false;
  String? _errorMessage;

  // ── Step 2: OTP Verification ──
  static const int _kOtpLength = 6;
  static const int _kResendCooldown = 60;
  int _secondsRemaining = _kResendCooldown;
  Timer? _timer;

  final List<TextEditingController> _otpControllers =
      List.generate(_kOtpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(_kOtpLength, (_) => FocusNode());

  // ── Step 3: New Phone Input ──
  final TextEditingController _newPhoneController = TextEditingController();
  final FocusNode _newPhoneFocusNode = FocusNode();

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPhoneController.dispose();
    _newPhoneFocusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _kResendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final normalizedOld = PhoneUtils.formatToInternational(widget.oldPhone);
    final repo = GetIt.instance<AuthRepository>();
    final result = await repo.sendOtp(phone: normalizedOld);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => setState(() => _errorMessage = failure.message),
      (_) {
        setState(() {
          _step = PhoneChangeStep.verifyOtp;
          _errorMessage = null;
        });
        _startResendTimer();
        FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < _kOtpLength) {
      setState(() => _errorMessage = 'Please enter all $_kOtpLength digits');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final normalizedOld = PhoneUtils.formatToInternational(widget.oldPhone);
    final repo = GetIt.instance<AuthRepository>();
    final result = await repo.verifyOtp(phone: normalizedOld, otp: code);

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => setState(() => _errorMessage = failure.message),
      (_) {
        _timer?.cancel();
        setState(() {
          _step = PhoneChangeStep.enterNewPhone;
          _errorMessage = null;
        });
        FocusScope.of(context).requestFocus(_newPhoneFocusNode);
      },
    );
  }

  Future<void> _handleUpdatePhone() async {
    final newPhoneInput = _newPhoneController.text.trim();
    if (newPhoneInput.isEmpty) {
      setState(() => _errorMessage = 'Please enter your new phone number');
      return;
    }

    if (!PhoneUtils.isValidGhanaPhone(newPhoneInput)) {
      setState(
        () => _errorMessage =
            'Please enter a valid 9-digit Ghana phone number (e.g. 241234567)',
      );
      return;
    }

    final fullNewPhone = PhoneUtils.formatToInternational(newPhoneInput);
    final fullOldPhone = PhoneUtils.formatToInternational(widget.oldPhone);

    if (fullNewPhone == fullOldPhone) {
      setState(
        () => _errorMessage =
            'New phone number must be different from current phone number',
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.onPhoneUpdated(newPhoneInput);
      if (!mounted) return;
      Navigator.of(context).pop();
      CustomDialog.showSuccess(
        context: context,
        title: 'Phone Number Updated',
        subtitle: 'Your phone number has been updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.035,
        w * 0.05,
        bottomInset + w * 0.05,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            children: [
              Text(
                _stepTitle,
                style: TextStyle(
                  fontSize: (w * 0.045).clamp(16.0, 20.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: w * 0.045,
                    color: AppColors.textSecondary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Error Banner if any
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: w * 0.045,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: (w * 0.033).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Body Content by Step
          if (_step == PhoneChangeStep.confirmSend)
            _buildConfirmSendStep(w)
          else if (_step == PhoneChangeStep.verifyOtp)
            _buildVerifyOtpStep(w)
          else
            _buildEnterNewPhoneStep(w),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case PhoneChangeStep.confirmSend:
        return 'Verify Old Phone';
      case PhoneChangeStep.verifyOtp:
        return 'Enter Verification Code';
      case PhoneChangeStep.enterNewPhone:
        return 'New Phone Number';
    }
  }

  // ── Step 1 UI ──
  Widget _buildConfirmSendStep(double w) {
    final maskedPhone = PhoneUtils.maskPhoneNumber(widget.oldPhone);
    return Column(
      children: [
        Container(
          width: w * 0.16,
          height: w * 0.16,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedShieldKey,
              color: AppColors.primary,
              size: w * 0.08,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Security Verification',
          style: TextStyle(
            fontSize: (w * 0.04).clamp(14.0, 17.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To protect your account security, an OTP verification code will be sent to your registered phone number:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSmartPhone01,
                color: AppColors.primary,
                size: w * 0.045,
              ),
              const SizedBox(width: 8),
              Text(
                maskedPhone,
                style: TextStyle(
                  fontSize: (w * 0.042).clamp(15.0, 18.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: (w * 0.135).clamp(46.0, 56.0),
          child: ElevatedButton(
            onPressed: _loading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Send OTP Code',
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 2 UI ──
  Widget _buildVerifyOtpStep(double w) {
    final maskedPhone = PhoneUtils.maskPhoneNumber(widget.oldPhone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-digit verification code sent to $maskedPhone:',
          style: TextStyle(
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // 6 OTP Digit Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_kOtpLength, (i) {
            final boxW = (w * 0.86 - 40) / _kOtpLength;
            return SizedBox(
              width: boxW,
              height: boxW * 1.1,
              child: TextFormField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: (boxW * 0.45).clamp(16.0, 22.0),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < _kOtpLength - 1) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[i + 1]);
                  } else if (val.isEmpty && i > 0) {
                    FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
                  }
                  if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                    _handleVerifyOtp();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Resend Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(
                fontSize: (w * 0.033).clamp(11.0, 14.0),
                color: AppColors.textHint,
              ),
            ),
            if (_secondsRemaining > 0)
              Text(
                'Resend in ${_secondsRemaining}s',
                style: TextStyle(
                  fontSize: (w * 0.033).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            else
              GestureDetector(
                onTap: _loading ? null : _handleSendOtp,
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    fontSize: (w * 0.033).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: (w * 0.135).clamp(46.0, 56.0),
          child: ElevatedButton(
            onPressed: _loading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 3 UI ──
  Widget _buildEnterNewPhoneStep(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your old phone number has been verified. Enter your new Ghana phone number below:',
          style: TextStyle(
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // New Phone Input Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Text('🇬🇭 ', style: TextStyle(fontSize: 16)),
                    Text(
                      '+233',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: (w * 0.038).clamp(13.0, 16.0),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _newPhoneController,
                  focusNode: _newPhoneFocusNode,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _NoLeadingZeroFormatter(),
                  ],
                  style: TextStyle(
                    fontSize: (w * 0.042).clamp(15.0, 18.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 241234567',
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleUpdatePhone(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: (w * 0.135).clamp(46.0, 56.0),
          child: ElevatedButton(
            onPressed: _loading ? null : _handleUpdatePhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                        color: Colors.white,
                        size: w * 0.045,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Update Phone Number',
                        style: TextStyle(
                          fontSize: (w * 0.04).clamp(14.0, 17.0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) return oldValue;
    return newValue;
  }
}
