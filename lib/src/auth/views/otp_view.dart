import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../constant/app_theme.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/router/router.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../viewmodels/auth_state.dart';
import '../viewmodels/auth_viewmodel.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 1 — String constants
// ══════════════════════════════════════════════════════════════════════════════

/// All UI copy for the OTP screen in one place.
abstract final class _Strings {
  static const title           = 'Verify your\nphone number';
  static const subtitle        = 'Enter the 5-digit code sent to your mobile number';
  static const verifyButton    = 'Verify & Continue';
  static const resendPrompt    = "Didn't receive a code?";
  static const resendLabel     = 'Resend';
  static const resendCountdown = 'Resend in ';
  static const errorIncomplete = 'Please enter all 5 digits';
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 2 — Config constants (behaviour, not pixels)
// ══════════════════════════════════════════════════════════════════════════════

const int _kOtpLength      = 5;
const int _kResendCooldown = 60; // seconds
const int _kMaxOtpAttempts = 5;  // client-side lockout after N consecutive failures

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 3 — Responsive dimensions
// ══════════════════════════════════════════════════════════════════════════════

/// All pixel dimensions derived from the device screen size at build time.
///
/// No raw pixel literals in widget code — dimensions here scale proportionally
/// across phones.
final class _Dims {
  _Dims.of(BuildContext context) : _s = MediaQuery.sizeOf(context);

  final Size _s;

  double get screenW => _s.width;
  double get screenH => _s.height;

  // ── Page layout ──
  double get horizontalPad  => screenW * 0.062;
  double get topGap         => screenH * 0.026;
  double get headerToFields => screenH * 0.056;
  double get fieldsToError  => screenH * 0.018;
  double get errorToButton  => screenH * 0.038;
  double get buttonToResend => screenH * 0.030;
  double get bottomPad      => screenH * 0.028;

  // ── OTP fields ──
  double get fieldSpacing => screenW * 0.026;
  double get fieldWidth   => (screenW - horizontalPad * 2 - fieldSpacing * (_kOtpLength - 1)) / _kOtpLength;
  double get fieldHeight  => fieldWidth * 1.16;
  double get fieldRadius  => fieldWidth * 0.23;
  double get borderNormal => screenW * 0.003;
  double get borderActive => screenW * 0.0048;

  // ── Button ──
  double get buttonHeight => screenH * 0.074;
  double get buttonRadius => screenW * 0.040;

  // ── Error banner ──
  double get errorIconSize    => screenW * 0.042;
  double get errorIconSpacing => screenW * 0.016;

  // ── Text ──
  double get titleFontSize    => screenW * 0.078;
  double get subtitleFontSize => screenW * 0.038;
  double get digitFontSize    => fieldWidth * 0.44;
  double get buttonFontSize   => screenW * 0.044;
  double get captionFontSize  => screenW * 0.036;
  double get errorFontSize    => screenW * 0.034;

  // ── Shake amplitude ──
  double get shakeAmplitude => screenW * 0.026;
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 4 — Text styles
// ══════════════════════════════════════════════════════════════════════════════

/// Factory methods for all text styles used on this screen.
///
/// Keeping styles here avoids scattering `TextStyle(...)` literals throughout
/// widget code and makes theming changes single-point.
abstract final class _Styles {
  static TextStyle title(_Dims d) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.titleFontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.22,
      );

  static TextStyle subtitle(_Dims d) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.subtitleFontSize,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle digit(_Dims d, {required bool onDark}) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.digitFontSize,
        fontWeight: FontWeight.w700,
        color: onDark ? Colors.white : AppColors.textPrimary,
      );

  static TextStyle button(_Dims d) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.buttonFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle resendPrompt(_Dims d) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.captionFontSize,
        color: AppColors.textSecondary,
      );

  static TextStyle resendAction(_Dims d, {required bool enabled}) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.captionFontSize,
        fontWeight: FontWeight.w600,
        color: enabled ? AppColors.primary : AppColors.textHint,
      );

  static TextStyle errorText(_Dims d) => TextStyle(
        fontFamily: 'Mukta',
        fontSize: d.errorFontSize,
        color: AppColors.error,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 5 — Field appearance resolver
// ══════════════════════════════════════════════════════════════════════════════

/// Resolved visual properties for a single OTP field.
typedef _FieldLook = ({
  Color border,
  Color fill,
  List<BoxShadow> shadows,
});

/// Derives border colour, fill colour, and shadows from the current field state.
_FieldLook resolveFieldLook({
  required bool isFocused,
  required bool isFilled,
  required bool hasError,
  required bool isSuccess,
  required double glowIntensity, // 0.0 – 1.0, driven by animation
}) {
  if (isSuccess) {
    return (
      border:  AppColors.success,
      fill:    AppColors.success.withValues(alpha: 0.12),
      shadows: [
        BoxShadow(
          color:       AppColors.success.withValues(alpha: 0.18),
          blurRadius:  10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  if (hasError) {
    return (
      border:  AppColors.error,
      fill:    const Color(0xFFFFF0F0), // very light red tint — stays light
      shadows: [
        BoxShadow(
          color:      AppColors.error.withValues(alpha: 0.18),
          blurRadius: 8,
        ),
      ],
    );
  }

  if (isFilled) {
    return (
      border:  AppColors.primary,
      fill:    Colors.white,
      shadows: const [],
    );
  }

  if (isFocused) {
    return (
      border:  AppColors.primary,
      fill:    Colors.white,
      shadows: [
        BoxShadow(
          color:        AppColors.primary.withValues(alpha: 0.12 + glowIntensity * 0.20),
          blurRadius:   6 + glowIntensity * 8,
          spreadRadius: glowIntensity * 1.5,
        ),
      ],
    );
  }

  // Inactive — clean white, no shadow
  return (
    border:  AppColors.border,
    fill:    const Color(0xFFF7F9FC),
    shadows: const [],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 6 — OTP input controller (plain Dart, not Flutter)
// ══════════════════════════════════════════════════════════════════════════════

/// Owns the five [TextEditingController]s and [FocusNode]s and encapsulates
/// all cross-field cursor navigation logic.
///
/// Call [dispose] from the owning widget's `dispose()`.
class _OtpInputController {
  _OtpInputController({required this.onChanged}) {
    _controllers = List.generate(_kOtpLength, (_) => TextEditingController());
    _focusNodes  = List.generate(_kOtpLength, (_) => FocusNode());
  }

  /// Invoked after any structural change so the owning widget can call
  /// `setState`.
  final VoidCallback onChanged;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode>             _focusNodes;

  // ── Public accessors ──────────────────────────────────────────────────────

  TextEditingController controllerAt(int i) => _controllers[i];
  FocusNode             focusNodeAt(int i)  => _focusNodes[i];

  /// The current OTP string (may be incomplete).
  String get otp     => _controllers.map((c) => c.text).join();
  bool   get isFilled => otp.length == _kOtpLength;

  // ── Cursor navigation ─────────────────────────────────────────────────────

  /// Moves focus forward after a digit is entered at [fromIndex].
  /// Unfocuses the last field (caller is responsible for auto-submit).
  void advance(int fromIndex) {
    if (fromIndex < _kOtpLength - 1) {
      _focusNodes[fromIndex + 1].requestFocus();
    } else {
      _focusNodes[fromIndex].unfocus();
    }
    onChanged();
  }

  /// Clears the previous field and moves focus back when backspace is pressed
  /// on an already-empty field at [fromIndex].
  void backtrack(int fromIndex) {
    if (fromIndex > 0) {
      _controllers[fromIndex - 1].clear();
      _focusNodes[fromIndex - 1].requestFocus();
      onChanged();
    }
  }

  /// Distributes [digits] across all fields starting from index 0 and moves
  /// focus to the next unfilled slot (or the last field if all filled).
  void distribute(String digits) {
    for (int i = 0; i < _kOtpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final nextIdx = math.min(digits.length, _kOtpLength - 1);
    _focusNodes[nextIdx].requestFocus();
    onChanged();
  }

  /// Clears all fields and moves focus to the first field.
  void clearAll() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
    onChanged();
  }

  /// Requests focus on the first field.
  void focusFirst() => _focusNodes[0].requestFocus();

  /// Must be called from the owning widget's `dispose()`.
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes)  { f.dispose(); }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 7 — Resend timer
// ══════════════════════════════════════════════════════════════════════════════

/// Manages the OTP resend cooldown countdown.
///
/// Calls [onTick] with the remaining seconds on every tick and [onComplete]
/// when the countdown reaches zero. Call [cancel] from the owning widget's
/// `dispose()`.
class _ResendTimer {
  _ResendTimer({
    required this.durationSeconds,
    required this.onTick,
    required this.onComplete,
  });

  final int           durationSeconds;
  final void Function(int remaining) onTick;
  final VoidCallback  onComplete;

  Timer? _timer;
  int    _remaining = 0;

  int  get remaining => _remaining;
  bool get canResend => _remaining == 0;

  /// Restarts the countdown from [durationSeconds].
  void start() {
    _remaining = durationSeconds;
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
//  SECTION 8 — OtpFieldWidget (reusable single digit field)
// ══════════════════════════════════════════════════════════════════════════════

/// A single floating OTP digit field with animated glow border, light-theme
/// fill states, and discrete callbacks for input events.
///
/// Visual state priority (high → low): success → error → filled → focused →
/// inactive.
class _OtpFieldWidget extends StatefulWidget {
  const _OtpFieldWidget({
    required this.controller,
    required this.focusNode,
    required this.dims,
    required this.obscure,
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

  /// Responsive dimensions for this screen size.
  final _Dims                 dims;

  final bool                  obscure;
  final bool                  hasError;
  final bool                  isSuccess;

  /// Drives the bounce-scale animation on OTP verified.
  final Animation<double>     successScale;

  final bool                  enabled;

  /// Single digit entered / cleared.
  final ValueChanged<String>  onChanged;

  /// Backspace pressed on an empty field.
  final VoidCallback          onBackspace;

  /// Pasted string of ≥ 2 digits.
  final ValueChanged<String>  onPaste;

  @override
  State<_OtpFieldWidget> createState() => _OtpFieldWidgetState();
}

class _OtpFieldWidgetState extends State<_OtpFieldWidget>
    with SingleTickerProviderStateMixin {
  // Pulsing glow while focused
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

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _formatter = _OtpDigitFormatter(onPaste: (v) => widget.onPaste(v));

    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
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
        builder: (context, child) {
          final hasTex = widget.controller.text.isNotEmpty;
          final look = resolveFieldLook(
            isFocused:     _isFocused,
            isFilled:      hasTex,
            hasError:      widget.hasError,
            isSuccess:     widget.isSuccess,
            glowIntensity: _glowAnim.value,
          );

          return AnimatedContainer(
            duration:     const Duration(milliseconds: 180),
            clipBehavior: Clip.antiAlias,
            width:  d.fieldWidth,
            height: d.fieldHeight,
            decoration: BoxDecoration(
              color:        look.fill,
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
            controller:      widget.controller,
            focusNode:       widget.focusNode,
            enabled:         widget.enabled,
            keyboardType:    TextInputType.number,
            textInputAction: TextInputAction.next,
            textAlign:         TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            obscureText:     widget.obscure,
            inputFormatters: [_formatter],
            style:           _Styles.digit(d, onDark: false),
            decoration: const InputDecoration(
              filled:         false,       // override theme's filled:true so TextField draws no background
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
//  SECTION 9 — OtpDigitFormatter
// ══════════════════════════════════════════════════════════════════════════════

/// Strips non-digits, limits field to one character, and intercepts paste
/// (≥ 2 digits) by forwarding to [onPaste] and reverting the field value.
class _OtpDigitFormatter extends TextInputFormatter {
  _OtpDigitFormatter({required this.onPaste});

  final ValueChanged<String> onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 1) {
      onPaste(digits);
      return oldValue; // revert — parent distributes across fields
    }

    if (digits.isEmpty) return const TextEditingValue();

    return TextEditingValue(
      text:      digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SECTION 10 — OTPView (main screen)
// ══════════════════════════════════════════════════════════════════════════════

/// OTP verification screen.
///
/// Delegates all business logic to [AuthViewmodel] and owns only UI-layer
/// state: field navigation, animations, countdown timer, and error / success
/// feedback.
///
/// Set [obscureDigits] to `true` to mask digits with a bullet.
class OTPView extends StatefulWidget {
  const OTPView({
    super.key,
    this.obscureDigits = false,
    this.showSuccessOnVerify = false,
    this.isForgotPassword = false,
  });

  /// Whether each entered digit should be rendered as `•`.
  final bool obscureDigits;

  /// When `true`, shows a success dialog after verification before navigating
  /// home. Used when coming from the phone verification / KYC flow.
  final bool showSuccessOnVerify;

  /// When `true`, redirects to ResetPasswordView on successful verification.
  final bool isForgotPassword;

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> with TickerProviderStateMixin {
  // ── Domain objects (sections 6 & 7) ──────────────────────────────────────
  late final _OtpInputController _input;
  late final _ResendTimer        _resendTimer;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _successCtrl;

  late final Animation<double> _shakeAnim;
  late final Animation<double> _successScaleAnim;

  // ── View-local UI state ───────────────────────────────────────────────────
  bool    _hasError        = false;
  bool    _isSuccess       = false;
  String? _errorMessage;
  int     _failedAttempts  = 0;

  /// Saved reference so dispose() doesn't call context.read on an unmounted widget.
  AuthViewmodel? _vm;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initInputController();
    _initResendTimer();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<AuthViewmodel>();
      _vm!.addListener(_onAuthStateChanged);
      _input.focusFirst();
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onAuthStateChanged);
    _input.dispose();
    _resendTimer.cancel();
    _entryCtrl.dispose();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Initialisation helpers ────────────────────────────────────────────────

  void _initInputController() {
    _input = _OtpInputController(onChanged: () => setState(() {}));
  }

  void _initResendTimer() {
    _resendTimer = _ResendTimer(
      durationSeconds: _kResendCooldown,
      onTick:     (_) => setState(() {}),
      onComplete:  () => setState(() {}),
    );
    _resendTimer.start();
  }

  void _initAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
  }

  // ── Auth state listener ───────────────────────────────────────────────────

  void _onAuthStateChanged() {
    if (!mounted) return;
    final vm    = context.read<AuthViewmodel>();
    final state = vm.state;

    if (state is OTPVerified) {
      vm.resetState();
      _handleVerified();
    } else if (state is OTPSent) {
      vm.resetState();
      _failedAttempts = 0; // new OTP issued — reset attempt counter
      _resendTimer.start();
      setState(() {});
    } else if (state is AuthError) {
      final err = state;
      vm.resetState();
      _handleError(err.message);
    }
  }

  // ── Input event handlers ──────────────────────────────────────────────────

  void _onFieldChanged(int index, String value) {
    _clearErrorIfNeeded();
    if (value.isNotEmpty) {
      _input.advance(index);
      if (index == _kOtpLength - 1 && _input.isFilled) {
        _submitOtp();
      }
    }
  }

  void _onBackspace(int index) => _input.backtrack(index);

  void _onPaste(String digits) {
    _clearErrorIfNeeded();
    _input.distribute(digits);
    if (digits.length >= _kOtpLength) _submitOtp();
  }

  // ── OTP submission ────────────────────────────────────────────────────────

  /// Returns the phone number for OTP calls.
  /// Prefers the signed-in user's phone; falls back to the phone stored in
  /// the viewmodel when the user arrived from the "phone not verified" login
  /// flow (where CurrentUserProvider has no user yet).
  String get _phone {
    final fromProvider = context.read<CurrentUserProvider>().user?.phone ?? '';
    if (fromProvider.isNotEmpty) return fromProvider;
    return context.read<AuthViewmodel>().pendingPhone ?? '';
  }

  void _submitOtp() {
    if (!_input.isFilled) {
      _handleError(_Strings.errorIncomplete);
      return;
    }

    final phone = _phone;
    final otp   = _input.otp; // capture before clear

    // Security: wipe fields immediately — OTP must not linger in widget state.
    _input.clearAll();

    context.read<AuthViewmodel>().verifyOtp(phone: phone, otp: otp);
  }

  void _resendOtp() {
    if (!_resendTimer.canResend) return;
    context.read<AuthViewmodel>().sendOtp(_phone);
  }

  // ── State transitions ─────────────────────────────────────────────────────

  void _handleError(String message) {
    _failedAttempts++;
    _input.clearAll();

    final locked = _failedAttempts >= _kMaxOtpAttempts;
    setState(() {
      _hasError     = true;
      _errorMessage = locked
          ? 'Too many failed attempts. Please request a new code.'
          : message;
    });
    _shakeCtrl.forward(from: 0);

    // Force a resend cycle after max attempts to invalidate the current OTP.
    if (locked) {
      _failedAttempts = 0;
      _resendTimer.start();
    }
  }

  void _clearErrorIfNeeded() {
    if (_hasError) {
      setState(() {
        _hasError     = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleVerified() async {
    setState(() => _isSuccess = true);
    await _successCtrl.forward(from: 0);
    if (!mounted) return;

    if (widget.isForgotPassword) {
      AppNavigator.toResetPassword(context, _phone);
      return;
    }

    // Show success dialog when coming from the verification / KYC flow
    if (widget.showSuccessOnVerify) {
      await CustomDialog.showSuccess(
        context: context,
        title: 'Verification Successful',
        subtitle: 'Your phone number has been verified. Welcome to bagyesRUSH!',
        confirmText: 'Get Started',
        onConfirm: () {
          if (mounted) AppNavigator.toHome(context);
        },
      );
      return;
    }

    // Default: KYC check — route unverified users to verification screen
    final user = context.read<CurrentUserProvider>().user;
    if (user != null && !user.phoneVerified) {
      context.go(AppRoutes.kycVerification);
    } else {
      AppNavigator.toHome(context);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = _Dims.of(context);
    // Use select so only the loading boolean triggers a rebuild — not every
    // intermediate AuthState transition (OTPSent, AuthError, etc.).
    final isLoading = context.select<AuthViewmodel, bool>(
      (vm) => vm.state is AuthLoading,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: d.horizontalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: d.topGap),
              _buildHeader(d),
              SizedBox(height: d.headerToFields),
              _buildOtpRow(d, isLoading),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _hasError && _errorMessage != null
                    ? _buildErrorBanner(d)
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: d.errorToButton),
              _buildVerifyButton(d, isLoading),
              SizedBox(height: d.buttonToResend),
              _buildResendRow(d, isLoading),
              SizedBox(height: d.bottomPad),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(_Dims d) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.25),
          end:   Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_Strings.title,    style: _Styles.title(d)),
            SizedBox(height: d.fieldsToError * 0.38),
            Text(_Strings.subtitle, style: _Styles.subtitle(d)),
          ],
        ),
      ),
    );
  }

  // ── OTP fields row ────────────────────────────────────────────────────────

  Widget _buildOtpRow(_Dims d, bool isLoading) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = _hasError
            ? math.sin(_shakeAnim.value * math.pi * 7) * d.shakeAmplitude
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kOtpLength, (i) {
          final staggerDelay = i * 0.07;
          return Padding(
            padding: EdgeInsets.only(
              right: i < _kOtpLength - 1 ? d.fieldSpacing : 0,
            ),
            child: _buildStaggeredField(i, d, staggerDelay, isLoading),
          );
        }),
      ),
    );
  }

  Widget _buildStaggeredField(int i, _Dims d, double delay, bool isLoading) {
    return FadeTransition(
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
          controller:   _input.controllerAt(i),
          focusNode:    _input.focusNodeAt(i),
          dims:         d,
          obscure:      widget.obscureDigits,
          hasError:     _hasError,
          isSuccess:    _isSuccess,
          successScale: _successScaleAnim,
          enabled:      !isLoading,
          onChanged:    (v) => _onFieldChanged(i, v),
          onBackspace:  () => _onBackspace(i),
          onPaste:      _onPaste,
        ),
      ),
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner(_Dims d) {
    return Padding(
      padding: EdgeInsets.only(top: d.fieldsToError),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
               color: AppColors.error, size: d.errorIconSize),
          SizedBox(width: d.errorIconSpacing),
          Text(_errorMessage!, style: _Styles.errorText(d)),
        ],
      ),
    );
  }

  // ── Verify button ─────────────────────────────────────────────────────────

  Widget _buildVerifyButton(_Dims d, bool isLoading) {
    return SizedBox(
      width:  double.infinity,
      height: d.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading || _isSuccess ? null : _submitOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor:         AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.50),
          elevation:               0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.buttonRadius),
          ),
        ),
        child: isLoading
            ? const SpinKitCircle(size: 22, color: Colors.white)
            : Text(_Strings.verifyButton, style: _Styles.button(d)),
      ),
    );
  }

  // ── Resend row ────────────────────────────────────────────────────────────

  Widget _buildResendRow(_Dims d, bool isLoading) {
    final canResend = _resendTimer.canResend && !isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_Strings.resendPrompt, style: _Styles.resendPrompt(d)),
        SizedBox(width: d.errorIconSpacing),
        if (!_resendTimer.canResend)
          Text(
            '${_Strings.resendCountdown}${_resendTimer.remaining}s',
            style: _Styles.resendAction(d, enabled: false),
          )
        else
          GestureDetector(
            onTap: canResend ? _resendOtp : null,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style:    _Styles.resendAction(d, enabled: canResend),
              child:    const Text(_Strings.resendLabel),
            ),
          ),
      ],
    );
  }
}
