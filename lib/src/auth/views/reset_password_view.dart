import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key, required this.phone});

  final String phone;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  AuthViewmodel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<AuthViewmodel>();
      _vm!.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onAuthStateChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final vm = context.read<AuthViewmodel>();
    setState(() => _submitting = vm.state is AuthLoading);

    if (vm.state is PasswordResetSuccess) {
      vm.resetState();
      CustomDialog.showSuccess(
        context: context,
        title: 'Password Reset Successful',
        subtitle: 'Your password has been successfully updated. Please login with your new password.',
        confirmText: 'Go to Login',
        onConfirm: () {
          AppNavigator.toLogin(context);
        },
      );
    } else if (vm.state is AuthError) {
      final error = vm.state as AuthError;
      vm.resetState();
      CustomDialog.showError(
        context: context,
        title: error.title,
        subtitle: error.message,
      );
    }
  }

  void _submit() {
    if (_submitting) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 8) {
      CustomDialog.showError(
        context: context,
        title: 'Invalid Password',
        subtitle: 'Password must be at least 8 characters long.',
      );
      return;
    }

    if (password != confirmPassword) {
      CustomDialog.showError(
        context: context,
        title: 'Passwords Do Not Match',
        subtitle: 'Please check that confirm password matches the new password.',
      );
      return;
    }

    context.read<AuthViewmodel>().resetPassword(
          phone: widget.phone,
          password: password,
          confirmPassword: confirmPassword,
        );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.04),
                // ── Back Button ──
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      AppNavigator.toLogin(context);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(sw * 0.018),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(sw * 0.022),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: (sw * 0.045).clamp(16.0, 22.0),
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: sh * 0.03),
                // ── Title & Subtitle ──
                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (sw * 0.075).clamp(22.0, 34.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: sw * 0.015),
                Text(
                  'Create a new password for ${widget.phone}. Make sure it\'s secure.',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (sw * 0.038).clamp(12.0, 17.0),
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: sh * 0.05),
                // ── New Password Input ──
                Text(
                  'New Password',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (sw * 0.034).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: sw * 0.018),
                _ModernPasswordInput(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !_submitting,
                  obscure: _obscurePassword,
                  screenWidth: sw,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
                ),
                SizedBox(height: sh * 0.03),
                // ── Confirm Password Input ──
                Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (sw * 0.034).clamp(11.0, 15.0),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: sw * 0.018),
                _ModernPasswordInput(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  enabled: !_submitting,
                  obscure: _obscureConfirmPassword,
                  screenWidth: sw,
                  onToggleObscure: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  onSubmitted: (_) => _submit(),
                ),
                SizedBox(height: sh * 0.06),
                // ── Submit Button ──
                InkWell(
                  onTap: _submitting ? null : _submit,
                  borderRadius: BorderRadius.circular(sw * 0.032),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: (sh * 0.065).clamp(44.0, 58.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(sw * 0.032),
                      color: _submitting
                          ? Colors.red.withValues(alpha: 0.7)
                          : Colors.red,
                      boxShadow: _submitting
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Center(
                      child: _submitting
                          ? SpinKitCircle(size: sw * 0.055, color: Colors.white)
                          : Text(
                              'Reset Password',
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                color: Colors.white,
                                fontSize: (sw * 0.04).clamp(13.0, 17.0),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernPasswordInput extends StatefulWidget {
  const _ModernPasswordInput({
    required this.controller,
    required this.focusNode,
    required this.screenWidth,
    required this.obscure,
    required this.onToggleObscure,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool obscure;
  final double screenWidth;
  final VoidCallback onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ModernPasswordInput> createState() => _ModernPasswordInputState();
}

class _ModernPasswordInputState extends State<_ModernPasswordInput> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() =>
      setState(() => _isFocused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    final sw = widget.screenWidth;
    final radius = BorderRadius.circular(sw * 0.028);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: Colors.white,
        border: Border.all(
          color: _isFocused ? Colors.red : Colors.grey[200]!,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04,
          vertical: sw * 0.002,
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              size: (sw * 0.045).clamp(14.0, 20.0),
              color: _isFocused ? Colors.red : Colors.grey[500]!,
            ),
            SizedBox(width: sw * 0.028),
            Container(
              width: 1,
              height: (sw * 0.045).clamp(14.0, 20.0),
              color: Colors.grey[300],
            ),
            SizedBox(width: sw * 0.028),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                obscureText: widget.obscure,
                keyboardType: TextInputType.visiblePassword,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (sw * 0.038).clamp(12.0, 17.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontFamily: 'Mukta',
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                    fontSize: (sw * 0.038).clamp(12.0, 17.0),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: sw * 0.026),
                ),
                onSubmitted: widget.onSubmitted,
              ),
            ),
            GestureDetector(
              onTap: widget.onToggleObscure,
              child: HugeIcon(
                icon: widget.obscure
                    ? HugeIcons.strokeRoundedViewOff
                    : HugeIcons.strokeRoundedView,
                size: (sw * 0.045).clamp(14.0, 20.0),
                color: Colors.grey[500]!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
