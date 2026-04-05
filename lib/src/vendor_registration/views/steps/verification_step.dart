import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  Constants
// ══════════════════════════════════════════════════════════════════════════════

const int _kOtpLength      = 5;
const int _kResendCooldown = 60;
const int _kMaxAttempts    = 5;

// ══════════════════════════════════════════════════════════════════════════════
//  Responsive dims
// ══════════════════════════════════════════════════════════════════════════════

final class _Dims {
  _Dims.of(BuildContext context) : _s = MediaQuery.sizeOf(context);
  final Size _s;

  double get w => _s.width;
  double get h => _s.height;

  // OTP fields — span 86% of width with even spacing between
  double get fieldSpacing => w * 0.026;
  double get fieldWidth   => (w * 0.86 - fieldSpacing * (_kOtpLength - 1)) / _kOtpLength;
  double get fieldHeight  => fieldWidth * 1.18;
  double get fieldRadius  => fieldWidth * 0.23;
  double get borderNormal => w * 0.003;
  double get borderActive => w * 0.0048;

  double get buttonHeight => h * 0.068;
  double get buttonRadius => w * 0.040;

  double get digitFontSize   => fieldWidth * 0.44;
  double get buttonFontSize  => w * 0.042;
  double get captionFontSize => w * 0.035;
  double get errorFontSize   => w * 0.033;
  double get shakeAmplitude  => w * 0.026;
  double get iconSize        => w * 0.016;
}

// ══════════════════════════════════════════════════════════════════════════════
//  Field appearance resolver
// ══════════════════════════════════════════════════════════════════════════════

typedef _FieldLook = ({Color border, Color fill, List<BoxShadow> shadows});

_FieldLook _resolveFieldLook({
  required bool isFocused,
  required bool isFilled,
  required bool hasError,
  required bool isSuccess,
  required double glowIntensity,
}) {
  if (isSuccess) {
    return (
      border: AppColors.success,
      fill: AppColors.success.withValues(alpha: 0.12),
      shadows: [
        BoxShadow(color: AppColors.success.withValues(alpha: 0.18), blurRadius: 10),
      ],
    );
  }
  if (hasError) {
    return (
      border: AppColors.error,
      fill: const Color(0xFFFFF0F0),
      shadows: [
        BoxShadow(color: AppColors.error.withValues(alpha: 0.18), blurRadius: 8),
      ],
    );
  }
  if (isFilled) {
    return (border: AppColors.primary, fill: Colors.white, shadows: const []);
  }
  if (isFocused) {
    return (
      border: AppColors.primary,
      fill: Colors.white,
      shadows: [
        BoxShadow(
          color: AppColors.primary
              .withValues(alpha: 0.12 + glowIntensity * 0.20),
          blurRadius: 6 + glowIntensity * 8,
          spreadRadius: glowIntensity * 1.5,
        ),
      ],
    );
  }
  return (border: AppColors.border, fill: const Color(0xFFF7F9FC), shadows: const []);
}

// ══════════════════════════════════════════════════════════════════════════════
//  OTP input controller
// ══════════════════════════════════════════════════════════════════════════════

class _OtpInputController {
  _OtpInputController({required this.onChanged}) {
    _controllers = List.generate(_kOtpLength, (_) => TextEditingController());
    _focusNodes  = List.generate(_kOtpLength, (_) => FocusNode());
  }

  final VoidCallback onChanged;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode>             _focusNodes;

  TextEditingController controllerAt(int i) => _controllers[i];
  FocusNode             focusNodeAt(int i)  => _focusNodes[i];

  String get otp      => _controllers.map((c) => c.text).join();
  bool   get isFilled => otp.length == _kOtpLength;

  void advance(int from) {
    if (from < _kOtpLength - 1) {
      _focusNodes[from + 1].requestFocus();
    } else {
      _focusNodes[from].unfocus();
    }
    onChanged();
  }

  void backtrack(int from) {
    if (from > 0) {
      _controllers[from - 1].clear();
      _focusNodes[from - 1].requestFocus();
      onChanged();
    }
  }

  void distribute(String digits) {
    for (int i = 0; i < _kOtpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final next = math.min(digits.length, _kOtpLength - 1);
    _focusNodes[next].requestFocus();
    onChanged();
  }

  void clearAll() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    onChanged();
  }

  void focusFirst() => _focusNodes[0].requestFocus();

  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Resend countdown timer
// ══════════════════════════════════════════════════════════════════════════════

class _ResendTimer {
  _ResendTimer({required this.onTick, required this.onComplete});

  final void Function(int remaining) onTick;
  final VoidCallback onComplete;

  Timer? _timer;
  int    _remaining = 0;

  int  get remaining => _remaining;
  bool get canResend => _remaining == 0;

  void start() {
    _remaining = _kResendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        _remaining = 0;
        onComplete();
      } else {
        _remaining--;
        onTick(_remaining);
      }
    });
  }

  void cancel() => _timer?.cancel();
}

// ══════════════════════════════════════════════════════════════════════════════
//  Digit formatter — strips non-digits, intercepts paste
// ══════════════════════════════════════════════════════════════════════════════

class _OtpDigitFormatter extends TextInputFormatter {
  _OtpDigitFormatter({required this.onPaste});
  final ValueChanged<String> onPaste;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) {
      onPaste(digits);
      return old; // revert — controller distributes across fields
    }
    if (digits.isEmpty) return const TextEditingValue();
    return TextEditingValue(
      text: digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Single digit field widget
// ══════════════════════════════════════════════════════════════════════════════

class _OtpFieldWidget extends StatefulWidget {
  const _OtpFieldWidget({
    required this.controller,
    required this.focusNode,
    required this.dims,
    required this.hasError,
    required this.isSuccess,
    required this.successScale,
    required this.enabled,
    required this.onChanged,
    required this.onBackspace,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final _Dims                 dims;
  final bool                  hasError;
  final bool                  isSuccess;
  final Animation<double>     successScale;
  final bool                  enabled;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onBackspace;
  final ValueChanged<String>  onPaste;

  @override
  State<_OtpFieldWidget> createState() => _OtpFieldWidgetState();
}

class _OtpFieldWidgetState extends State<_OtpFieldWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double>   _glowAnim;
  late final _OtpDigitFormatter  _formatter;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _formatter = _OtpDigitFormatter(onPaste: widget.onPaste);
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dims;
    return ScaleTransition(
      scale: widget.isSuccess
          ? widget.successScale
          : const AlwaysStoppedAnimation(1.0),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, child) {
          final hasTex = widget.controller.text.isNotEmpty;
          final look = _resolveFieldLook(
            isFocused:     _isFocused,
            isFilled:      hasTex,
            hasError:      widget.hasError,
            isSuccess:     widget.isSuccess,
            glowIntensity: _glowAnim.value,
          );
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            clipBehavior: Clip.antiAlias,
            width:  d.fieldWidth,
            height: d.fieldHeight,
            decoration: BoxDecoration(
              color: look.fill,
              borderRadius: BorderRadius.circular(d.fieldRadius),
              border: Border.all(
                color: look.border,
                width: (_isFocused || widget.hasError || hasTex)
                    ? d.borderActive
                    : d.borderNormal,
              ),
              boxShadow: look.shadows,
            ),
            child: child,
          );
        },
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                widget.controller.text.isEmpty) {
              widget.onBackspace();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller:        widget.controller,
            focusNode:         widget.focusNode,
            enabled:           widget.enabled,
            keyboardType:      TextInputType.number,
            textInputAction:   TextInputAction.next,
            textAlign:         TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            inputFormatters:   [_formatter],
            style: TextStyle(
              fontSize:   d.digitFontSize,
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              filled:         false,
              border:         InputBorder.none,
              enabledBorder:  InputBorder.none,
              focusedBorder:  InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText:    '',
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  VerificationStep — main widget
// ══════════════════════════════════════════════════════════════════════════════

class VerificationStep extends StatefulWidget {
  const VerificationStep({
    super.key,
    required this.phone,
    required this.isLoading,
    required this.isOtpSent,
    required this.isVerified,
    this.isResumeFlow = false,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final String phone;
  final bool isLoading;
  final bool isOtpSent;
  final bool isVerified;
  final bool isResumeFlow;
  final VoidCallback onSendOtp;
  final ValueChanged<String> onVerifyOtp;

  @override
  State<VerificationStep> createState() => _VerificationStepState();
}

class _VerificationStepState extends State<VerificationStep>
    with TickerProviderStateMixin {
  late final _OtpInputController _input;
  late final _ResendTimer        _resendTimer;

  late final AnimationController _entryCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _checkCtrl;

  late final Animation<double> _shakeAnim;
  late final Animation<double> _successScaleAnim;
  late final Animation<double> _checkScale;

  bool    _hasError       = false;
  bool    _isSuccess      = false;
  String? _errorMessage;
  int     _failedAttempts = 0;

  @override
  void initState() {
    super.initState();

    _input = _OtpInputController(onChanged: () => setState(() {}));

    _resendTimer = _ResendTimer(
      onTick:     (_) => setState(() {}),
      onComplete:  () => setState(() {}),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.easeInOut));

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );

    // If OTP was already sent before this widget mounted (resume flow),
    // start the timer immediately and focus the first field.
    if (widget.isOtpSent) {
      _resendTimer.start();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _input.focusFirst());
    }
  }

  @override
  void didUpdateWidget(covariant VerificationStep old) {
    super.didUpdateWidget(old);

    if (widget.isOtpSent && !old.isOtpSent) {
      // OTP just became sent — kick off countdown and focus fields.
      _resendTimer.start();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _input.focusFirst());
    }

    if (widget.isVerified && !old.isVerified) {
      _handleVerified();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _resendTimer.cancel();
    _entryCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_input.isFilled) {
      _handleError('Please enter all $_kOtpLength digits');
      return;
    }
    final otp = _input.otp;
    _input.clearAll();
    widget.onVerifyOtp(otp);
  }

  void _handleError(String message) {
    _failedAttempts++;
    _input.clearAll();
    setState(() {
      _hasError     = true;
      _errorMessage = _failedAttempts >= _kMaxAttempts
          ? 'Too many failed attempts. Request a new code.'
          : message;
    });
    _shakeCtrl.forward(from: 0);
    if (_failedAttempts >= _kMaxAttempts) {
      _failedAttempts = 0;
      _resendTimer.start();
    }
  }

  void _clearError() {
    if (_hasError) {
      setState(() {
        _hasError     = false;
        _errorMessage = null;
      });
    }
  }

  void _handleVerified() {
    setState(() => _isSuccess = true);
    _checkCtrl.forward();
    _successCtrl.forward(from: 0);
  }

  void _onFieldChanged(int i, String v) {
    _clearError();
    if (v.isNotEmpty) _input.advance(i);
  }

  void _onPaste(String digits) {
    _clearError();
    _input.distribute(digits);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d       = _Dims.of(context);
    final otpSent = widget.isOtpSent || widget.isVerified;

    return Column(
      children: [
        SizedBox(height: d.h * 0.02),

        if (widget.isResumeFlow) ...[
          _buildResumeBanner(d),
          SizedBox(height: d.h * 0.02),
        ],

        _buildIcon(d),
        SizedBox(height: d.h * 0.025),
        _buildHeader(d, otpSent),
        SizedBox(height: d.h * 0.04),

        // OTP fields are always visible. They are disabled while the OTP is
        // being dispatched (isLoading && !otpSent) so the user sees where
        // to type without waiting for the network round-trip.
        if (!widget.isVerified) ...[
          // Spinner shown above the fields while OTP is being sent
          if (widget.isLoading && !otpSent) ...[
            const SpinKitCircle(size: 24, color: AppColors.primary),
            SizedBox(height: d.h * 0.025),
          ],
          _buildOtpRow(d),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _hasError && _errorMessage != null
                ? _buildErrorBanner(d)
                : const SizedBox.shrink(),
          ),
          SizedBox(height: d.h * 0.03),
          _buildVerifyButton(d),
          SizedBox(height: d.h * 0.022),
          _buildResendRow(d),
        ],

        SizedBox(height: d.h * 0.02),
      ],
    );
  }

  // ── Resume banner ────────────────────────────────────────────────────────────

  Widget _buildResumeBanner(_Dims d) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(d.w * 0.035),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(d.w * 0.025),
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.amber.shade700, size: d.w * 0.045),
          SizedBox(width: d.w * 0.025),
          Expanded(
            child: Text(
              'It looks like you already started registration. '
              'We\'ve sent a new verification code to your phone — '
              'enter it below to complete your account.',
              style: TextStyle(
                fontSize: d.w * 0.03,
                color:    Colors.amber.shade900,
                height:   1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon ─────────────────────────────────────────────────────────────────────

  Widget _buildIcon(_Dims d) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width:  d.w * 0.2,
      height: d.w * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isVerified
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
      ),
      child: widget.isVerified
          ? ScaleTransition(
              scale: _checkScale,
              child: HugeIcon(
                icon:  HugeIcons.strokeRoundedCheckmarkCircle01,
                color: AppColors.success,
                size:  d.w * 0.1,
              ),
            )
          : HugeIcon(
              icon:  HugeIcons.strokeRoundedSmartPhone01,
              color: AppColors.primary,
              size:  d.w * 0.08,
            ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader(_Dims d, bool otpSent) {
    final title = widget.isVerified
        ? 'Phone Verified!'
        : otpSent
            ? 'Enter the code'
            : 'Verify your phone number';

    final subtitle = widget.isVerified
        ? 'Your phone number has been verified successfully.'
        : otpSent
            ? 'We sent a $_kOtpLength-digit code to +233 ${widget.phone}'
            : 'We\'ll send a verification code to +233 ${widget.phone}';

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize:   d.w * 0.05,
              fontWeight: FontWeight.bold,
              color:      AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: d.h * 0.008),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: d.w * 0.034,
              color:    AppColors.textSecondary,
              height:   1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── OTP fields row ────────────────────────────────────────────────────────────

  Widget _buildOtpRow(_Dims d) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = _hasError
            ? math.sin(_shakeAnim.value * math.pi * 7) * d.shakeAmplitude
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kOtpLength, (i) {
          final delay = i * 0.07;
          return Padding(
            padding: EdgeInsets.only(
              right: i < _kOtpLength - 1 ? d.fieldSpacing : 0,
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _entryCtrl,
                  curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.6),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entryCtrl,
                  curve: Interval(delay, delay + 0.5, curve: Curves.easeOutCubic),
                )),
                child: _OtpFieldWidget(
                  controller:  _input.controllerAt(i),
                  focusNode:   _input.focusNodeAt(i),
                  dims:        d,
                  hasError:    _hasError,
                  isSuccess:   _isSuccess,
                  successScale: _successScaleAnim,
                  enabled:     !widget.isLoading,
                  onChanged:   (v) => _onFieldChanged(i, v),
                  onBackspace: () => _input.backtrack(i),
                  onPaste:     _onPaste,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────────

  Widget _buildErrorBanner(_Dims d) {
    return Padding(
      padding: EdgeInsets.only(top: d.h * 0.018),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: d.w * 0.042),
          SizedBox(width: d.iconSize),
          Flexible(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontSize: d.errorFontSize, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Verify button ─────────────────────────────────────────────────────────────

  Widget _buildVerifyButton(_Dims d) {
    final loading = widget.isLoading;
    return SizedBox(
      width:  double.infinity,
      height: d.buttonHeight,
      child: ElevatedButton(
        onPressed: loading || _isSuccess ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.50),
          elevation:               0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.buttonRadius),
          ),
        ),
        child: loading
            ? const SpinKitCircle(size: 22, color: Colors.white)
            : Text(
                'Verify & Continue',
                style: TextStyle(
                  fontSize:   d.buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color:      Colors.white,
                ),
              ),
      ),
    );
  }

  // ── Resend row ────────────────────────────────────────────────────────────────

  Widget _buildResendRow(_Dims d) {
    final canResend = _resendTimer.canResend && !widget.isLoading;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code?",
          style: TextStyle(
            fontSize: d.captionFontSize,
            color:    AppColors.textSecondary,
          ),
        ),
        SizedBox(width: d.w * 0.016),
        if (!_resendTimer.canResend)
          Text(
            'Resend in ${_resendTimer.remaining}s',
            style: TextStyle(
              fontSize:   d.captionFontSize,
              fontWeight: FontWeight.w600,
              color:      AppColors.textHint,
            ),
          )
        else
          GestureDetector(
            onTap: canResend ? widget.onSendOtp : null,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize:   d.captionFontSize,
                fontWeight: FontWeight.w600,
                color: canResend ? AppColors.primary : AppColors.textHint,
              ),
              child: const Text('Resend'),
            ),
          ),
      ],
    );
  }
}
