import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/router/router.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void proceed(BuildContext context) {
    final phone = _phoneController.text;
    if (phone.length < 10) {
      _showErrorDialog(
        context,
        'Invalid Phone Number',
        'Please enter a valid 10-digit phone number',
      );
      return;
    }

    context.read<AuthViewModel>().sendOtp(phone).then((_) {
      final state = context.read<AuthViewModel>().state;
      if (state.status == AuthStatus.initial && state.errorMessage == null) {
        AppNavigator.toOtp(context);
      } else if (state.status == AuthStatus.error) {
        _showErrorDialog(
          context,
          'Error',
          state.errorMessage ?? 'Something went wrong',
        );
      }
    });
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

  void _navigateToSignUp() {
    AppNavigator.toSignup(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authViewModel = context.watch<AuthViewModel>();
    final loading = authViewModel.state.status == AuthStatus.loading;
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

            return SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo Section - Top Aligned with Modern Positioning
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
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

                        // Content Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(),
                              SizedBox(height: size.height * 0.04),
                              _buildPhoneInputSection(loading),
                              SizedBox(height: size.height * 0.03),
                              _buildContinueButton(size, loading),
                              Spacer(),
                              _buildSignUpLink(),
                            ],
                          ),
                        ),

                        // Bottom Spacing
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
  }

  Widget _buildLogoSection(Size size, bool isTablet) {
    final logoSize = isTablet ? size.width * 0.25 : size.width * 0.35;

    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(AssetImages.bagyesLogo, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your mobile number to continue',
          style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        ),
      ],
    );
  }

  Widget _buildPhoneInputSection(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        _ModernPhoneInput(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          enabled: !loading,
          onSubmitted: (_) => proceed(context),
        ),
      ],
    );
  }

  Widget _buildContinueButton(Size size, bool loading) {
    return InkWell(
      onTap: loading ? null : () => proceed(context),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: loading ? Colors.red.withValues(alpha: 0.7) : Colors.red,
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? SpinKitCircle(size: 24, color: Colors.white)
              : Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            children: [
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()..onTap = _navigateToSignUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern Phone Input Component
class _ModernPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Function(String)? onSubmitted;

  const _ModernPhoneInput({
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.onSubmitted,
  });

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

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
        border: Border.all(
          color: _isFocused ? Colors.red : Colors.grey[300]!,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            // Country Code Prefix
            Text(
              '+233',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),

            SizedBox(width: 12),

            // Divider
            Container(width: 1, height: 24, color: Colors.grey[300]),

            SizedBox(width: 12),

            // Phone Number Input
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: '24 123 4567',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
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
