import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../constant/constant.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/auth_state.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/router/router.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocusNode    = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double>  _fadeAnimation;
  late Animation<Offset>  _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewmodel>().addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final vm = context.read<AuthViewmodel>();

    if (vm.state is LoggedIn) {
      final role = context.read<CurrentUserProvider>().user?.role;
      if (role == 'vendor') {
        AppNavigator.toVendorHome(context);
      } else {
        AppNavigator.toHome(context);
      }
    } else if (vm.state is AuthError) {
      final error = vm.state as AuthError;
      CustomDialog.showError(
        context: context,
        title: error.title,
        subtitle: error.message,
        iconPath: AssetImages.bagyesLogo,
        isLottie: false,
      );
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    context.read<AuthViewmodel>().removeListener(_onAuthStateChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _proceed(BuildContext context) {
    final phone    = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.length < 9) {
      _showErrorDialog(
        context,
        'Invalid Phone Number',
        'Please enter a valid 9-digit phone number.',
      );
      return;
    }

    if (password.length < 6) {
      _showErrorDialog(
        context,
        'Invalid Password',
        'Password must be at least 6 characters.',
      );
      return;
    }

    context.read<AuthViewmodel>().login(
          phoneNumber: '+233$phone',
          password: password,
        );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    CustomDialog.showError(
      context: context,
      title: title,
      subtitle: message,
      iconPath: AssetImages.bagyesLogo,
      isLottie: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewmodel>(
      builder: (context, vm, _) {
        final loading = vm.state is AuthLoading;
        final size    = MediaQuery.of(context).size;
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

        return Scaffold(
          backgroundColor: scaffoldBgColor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final horizontalPadding = isTablet
                    ? constraints.maxWidth * 0.15
                    : constraints.maxWidth * 0.06;

                final sw = constraints.maxWidth;
                final sh = constraints.maxHeight;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.only(
                                top: keyboardVisible
                                    ? size.height * 0.02
                                    : size.height * 0.06,
                              ),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildLogoSection(size, isTablet),
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.05),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderSection(sw),
                                  SizedBox(height: size.height * 0.04),
                                  _buildPhoneInputSection(loading, sw),
                                  SizedBox(height: size.height * 0.025),
                                  _buildPasswordInputSection(loading, sw),
                                  SizedBox(height: size.height * 0.03),
                                  _buildLoginButton(context, loading, sw),
                                  const Spacer(),
                                  _buildSignUpLink(sw, sh),
                                ],
                              ),
                            ),
                            SizedBox(height: size.height * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(Size size, bool isTablet) {
    final logoSize = isTablet ? size.width * 0.25 : size.width * 0.35;
    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(logoSize * 0.15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: logoSize * 0.15,
                offset: Offset(0, logoSize * 0.08),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(logoSize * 0.15),
            child: Image.asset(AssetImages.bagyesLogo, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: (sw * 0.085).clamp(24, 36),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: sw * 0.02),
        Text(
          'Sign in to your account',
          style: TextStyle(
            fontSize: (sw * 0.043).clamp(13, 18),
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputSection(bool loading, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: (sw * 0.037).clamp(11, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: sw * 0.032),
        _ModernPhoneInput(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          enabled: !loading,
          screenWidth: sw,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
        ),
      ],
    );
  }

  Widget _buildPasswordInputSection(bool loading, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: (sw * 0.037).clamp(11, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: sw * 0.032),
        _ModernPasswordInput(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          enabled: !loading,
          obscure: _obscurePassword,
          screenWidth: sw,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          onSubmitted: (_) => _proceed(context),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, bool loading, double sw) {
    return InkWell(
      onTap: loading ? null : () => _proceed(context),
      borderRadius: BorderRadius.circular(sw * 0.04),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: (sw * 0.15).clamp(48, 64),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sw * 0.04),
          color: loading ? Colors.red.withValues(alpha: 0.7) : Colors.red,
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? SpinKitCircle(size: sw * 0.064, color: Colors.white)
              : Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (sw * 0.043).clamp(13, 18),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink(double sw, double sh) {
    final fontSize = (sw * 0.037).clamp(11.0, 16.0);
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: sh * 0.02),
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
            children: [
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => AppNavigator.toSignup(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone input ───────────────────────────────────────────────────────────────

class _ModernPhoneInput extends StatefulWidget {
  const _ModernPhoneInput({
    required this.controller,
    required this.focusNode,
    required this.screenWidth,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final double screenWidth;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ModernPhoneInput> createState() => _ModernPhoneInputState();
}

class _ModernPhoneInputState extends State<_ModernPhoneInput> {
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

  void _onFocusChange() => setState(() => _isFocused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    final sw     = widget.screenWidth;
    final radius = BorderRadius.circular(sw * 0.032);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _isFocused ? Colors.white : const Color(0xFFF7F7F7),
        border: Border.all(
          color: _isFocused ? Colors.red : Colors.grey[200]!,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.043, vertical: sw * 0.008),
        child: Row(
          children: [
            Text(
              '+233',
              style: TextStyle(
                fontSize: (sw * 0.043).clamp(13, 18),
                fontWeight: FontWeight.w600,
                color: _isFocused ? Colors.red : Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: sw * 0.032),
            Container(width: 1, height: (sw * 0.052).clamp(16, 23), color: Colors.grey[300]),
            SizedBox(width: sw * 0.032),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                maxLength: 9,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: (sw * 0.043).clamp(13, 18),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: '24 123 4567',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: sw * 0.035),
                ),
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Password input ────────────────────────────────────────────────────────────

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

  void _onFocusChange() => setState(() => _isFocused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    final sw     = widget.screenWidth;
    final radius = BorderRadius.circular(sw * 0.032);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _isFocused ? Colors.white : const Color(0xFFF7F7F7),
        border: Border.all(
          color: _isFocused ? Colors.red : Colors.grey[200]!,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.043, vertical: sw * 0.008),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              size: (sw * 0.05).clamp(16, 22),
              color: _isFocused ? Colors.red : Colors.grey[500]!,
            ),
            SizedBox(width: sw * 0.032),
            Container(width: 1, height: (sw * 0.052).clamp(16, 23), color: Colors.grey[300]),
            SizedBox(width: sw * 0.032),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                obscureText: widget.obscure,
                keyboardType: TextInputType.visiblePassword,
                style: TextStyle(
                  fontSize: (sw * 0.043).clamp(13, 18),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: sw * 0.035),
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
                size: (sw * 0.05).clamp(16, 22),
                color: Colors.grey[500]!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
