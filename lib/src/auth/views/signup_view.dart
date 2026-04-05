import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter, TextEditingValue;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/auth_state.dart';
import '../../../core/router/router.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers - Step 1
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  // Form controllers - Step 2
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _referralFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  /// Saved reference so dispose() doesn't call context.read on an unmounted widget.
  AuthViewmodel? _vm;

  late final TapGestureRecognizer _loginTapRecognizer;

  @override
  void initState() {
    super.initState();
    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () => AppNavigator.toLogin(context);
    _setupAnimations();
    _passwordController.addListener(_checkPasswordStrength);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<AuthViewmodel>();
      _vm!.addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    final vm = context.read<AuthViewmodel>();
    final state = vm.state;
    _submitting = false;

    if (state is Registered) {
      vm.resetState();
      final phone = context.read<CurrentUserProvider>().user?.phone ?? '';
      AppNavigator.toOtp(context);
      vm.sendOtp(phone);
    } else if (state is AuthError) {
      vm.resetState();
      CustomDialog.showError(
        context: context,
        title: state.title,
        subtitle: state.message,
      );
    }
  }

  void _onConfirmPasswordChanged() => setState(() {});

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

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    double strength = 0.0;
    String text = '';
    Color color = Colors.grey;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    if (strength <= 0.3) {
      text = 'Weak';
      color = Colors.red;
    } else if (strength <= 0.6) {
      text = 'Fair';
      color = Colors.orange;
    } else if (strength <= 0.8) {
      text = 'Good';
      color = Colors.blue;
    } else {
      text = 'Strong';
      color = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isValidEmail(String email) => _emailRegExp.hasMatch(email);

  bool _validateStep1() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showError('Please enter your last name');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }
    if (_phoneController.text.length != 9) {
      _showError('Please enter a valid 9-digit phone number');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showError('Please enter a password');
      return false;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return false;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('Password must contain at least one uppercase letter');
      return false;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError('Password must contain at least one lowercase letter');
      return false;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('Password must contain at least one number');
      return false;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showError('Password must contain at least one special character');
      return false;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    CustomDialog.showError(
      context: context,
      title: 'Validation Error',
      subtitle: message,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_validateStep1()) {
        setState(() => _currentStep = 1);
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitSignup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep = 0);
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _submitting = false;

  void _submitSignup() {
    if (_submitting) return;
    if (!_validateStep2()) return;

    _submitting = true;
    final vm = context.read<AuthViewmodel>();
    final phone = "+233${_phoneController.text.trim()}";

    vm.signup(
      email: _emailController.text.trim(),
      phone: phone,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: 'customer',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      address: _addressController.text.trim(),
      referralCode: _referralController.text.trim().isEmpty
          ? null
          : _referralController.text.trim(),
    );
  }

  @override
  void dispose() {
    _vm?.removeListener(_onAuthStateChanged);
    _loginTapRecognizer.dispose();
    _pageController.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    _passwordController.removeListener(_checkPasswordStrength);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _referralFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthViewmodel, bool>(
      (vm) => vm.state is AuthLoading,
    );

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final sw = constraints.maxWidth;
            final sh = constraints.maxHeight;
            final horizontalPadding = isTablet ? sw * 0.15 : sw * 0.06;

            return Column(
              children: [
                _buildHeader(sw, sh, horizontalPadding),
                _buildProgressIndicator(sw, sh, horizontalPadding),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(sw, sh, horizontalPadding, loading),
                      _buildStep2(sw, sh, horizontalPadding, loading),
                    ],
                  ),
                ),
                _buildBottomSection(sw, sh, horizontalPadding, loading),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(double sw, double sh, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: sh * 0.02,
      ),
      child: Row(
        children: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.black87,
              size: (sw * 0.06).clamp(20, 28),
            ),
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                AppNavigator.toOnboarding(context);
              }
            },
          ),
          SizedBox(width: sw * 0.02),
          Text(
            _currentStep == 0 ? 'Personal Details' : 'Security',
            style: TextStyle(
              fontSize: (sw * 0.051).clamp(16, 24),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    double sw,
    double sh,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: sh * 0.005,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(sw * 0.005),
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(width: sw * 0.02),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: sh * 0.005,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(sw * 0.005),
                    color: _currentStep >= 1 ? Colors.red : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.01),
          Text(
            'Step ${_currentStep + 1} of 2',
            style: TextStyle(
              fontSize: (sw * 0.030).clamp(10, 14),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(
    double sw,
    double sh,
    double horizontalPadding,
    bool loading,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.03),
                Text(
                  "Let's get you started",
                  style: TextStyle(
                    fontSize: (sw * 0.072).clamp(22, 34),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: sh * 0.01),
                Text(
                  'Create a new account to get started',
                  style: TextStyle(
                    fontSize: (sw * 0.038).clamp(13, 17),
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: sh * 0.04),
                _ModernTextField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  prefixIcon: HugeIcons.strokeRoundedUser,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _lastNameFocus.requestFocus(),
                ),
                SizedBox(height: sh * 0.018),
                _ModernTextField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  prefixIcon: HugeIcons.strokeRoundedUser,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),
                SizedBox(height: sh * 0.018),
                _ModernTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email Address',
                  hint: 'your.email@example.com',
                  prefixIcon: HugeIcons.strokeRoundedMail01,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                ),
                SizedBox(height: sh * 0.018),
                _ModernPhoneField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _addressFocus.requestFocus(),
                ),
                SizedBox(height: sh * 0.018),
                _ModernTextField(
                  controller: _addressController,
                  focusNode: _addressFocus,
                  label: 'Address (Optional)',
                  hint: 'Enter your address',
                  prefixIcon: HugeIcons.strokeRoundedLocation01,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _referralFocus.requestFocus(),
                ),
                SizedBox(height: sh * 0.018),
                _ModernTextField(
                  controller: _referralController,
                  focusNode: _referralFocus,
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code',
                  prefixIcon: HugeIcons.strokeRoundedGift,
                  textInputAction: TextInputAction.done,
                  enabled: !loading,
                  screenWidth: sw,
                  screenHeight: sh,
                  onSubmitted: (_) => _nextStep(),
                ),
                SizedBox(height: sh * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(
    double sw,
    double sh,
    double horizontalPadding,
    bool loading,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sh * 0.03),
            Text(
              'Secure your account',
              style: TextStyle(
                fontSize: (sw * 0.072).clamp(22, 34),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: sh * 0.01),
            Text(
              'Create a strong password to protect your account',
              style: TextStyle(
                fontSize: (sw * 0.038).clamp(13, 17),
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: sh * 0.04),
            _ModernTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: HugeIcons.strokeRoundedLock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !loading,
              screenWidth: sw,
              screenHeight: sh,
              suffixIcon: IconButton(
                icon: HugeIcon(
                  icon: _obscurePassword
                      ? HugeIcons.strokeRoundedViewOff
                      : HugeIcons.strokeRoundedView,
                  color: Colors.grey[600]!,
                  size: (sw * 0.038).clamp(14, 18),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              SizedBox(height: sh * 0.015),
              _buildPasswordStrengthIndicator(sw, sh),
            ],
            SizedBox(height: sh * 0.018),
            _ModernTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: HugeIcons.strokeRoundedLock,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !loading,
              screenWidth: sw,
              screenHeight: sh,
              suffixIcon: IconButton(
                icon: HugeIcon(
                  icon: _obscureConfirmPassword
                      ? HugeIcons.strokeRoundedViewOff
                      : HugeIcons.strokeRoundedView,
                  color: Colors.grey[600]!,
                  size: (sw * 0.038).clamp(14, 18),
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              onSubmitted: (_) => _nextStep(),
            ),
            if (_confirmPasswordController.text.isNotEmpty) ...[
              SizedBox(height: sh * 0.012),
              _buildPasswordMatchIndicator(sw),
            ],
            SizedBox(height: sh * 0.025),
            _buildPasswordRequirements(sw, sh),
            SizedBox(height: sh * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(double sw, double sh) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(sw * 0.01),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
              minHeight: sh * 0.007,
            ),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Text(
          _passwordStrengthText,
          style: TextStyle(
            fontSize: (sw * 0.033).clamp(11, 15),
            fontWeight: FontWeight.w600,
            color: _passwordStrengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordMatchIndicator(double sw) {
    final match = _passwordController.text == _confirmPasswordController.text;
    return Row(
      children: [
        HugeIcon(
          icon: match
              ? HugeIcons.strokeRoundedCheckmarkCircle01
              : HugeIcons.strokeRoundedAlert01,
          size: (sw * 0.038).clamp(14.0, 18.0),
          color: match ? Colors.green : Colors.red,
        ),
        SizedBox(width: sw * 0.02),
        Text(
          match ? 'Passwords match' : 'Passwords do not match',
          style: TextStyle(
            fontSize: (sw * 0.033).clamp(11.0, 14.0),
            fontWeight: FontWeight.w500,
            color: match ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(double sw, double sh) {
    final password = _passwordController.text;
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: (sw * 0.033).clamp(11, 15),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: sh * 0.01),
          _buildRequirement(
            'At least 8 characters',
            password.length >= 8,
            sw,
            sh,
          ),
          _buildRequirement(
            'At least one uppercase letter',
            password.contains(RegExp(r'[A-Z]')),
            sw,
            sh,
          ),
          _buildRequirement(
            'At least one lowercase letter',
            password.contains(RegExp(r'[a-z]')),
            sw,
            sh,
          ),
          _buildRequirement(
            'At least one number',
            password.contains(RegExp(r'[0-9]')),
            sw,
            sh,
          ),
          _buildRequirement(
            'At least one special character (!@#\$%^&*)',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
            sw,
            sh,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met, double sw, double sh) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sh * 0.005),
      child: Row(
        children: [
          HugeIcon(
            icon: met
                ? HugeIcons.strokeRoundedCheckmarkCircle01
                : HugeIcons.strokeRoundedCircle,
            size: (sw * 0.041).clamp(14, 18),
            color: met ? Colors.green : Colors.grey[400]!,
          ),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: (sw * 0.030).clamp(10, 14),
                color: met ? Colors.green : Colors.grey[600],
                fontWeight: met ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    double sw,
    double sh,
    double horizontalPadding,
    bool loading,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: sh * 0.02,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: loading ? null : _nextStep,
            borderRadius: BorderRadius.circular(sw * 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: (sw * 0.14).clamp(48, 60),
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
                    ? SpinKitCircle(size: sw * 0.06, color: Colors.white)
                    : Text(
                        _currentStep == 0 ? 'Continue' : 'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (sw * 0.041).clamp(14, 18),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: sh * 0.018),
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  fontSize: (sw * 0.036).clamp(12, 16),
                  color: Colors.grey[600],
                ),
                children: [
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      fontSize: (sw * 0.036).clamp(12, 16),
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: _loginTapRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Modern TextField Component
// ═══════════════════════════════════════════════════════════════════════════

class _ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final List<List<dynamic>> prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;
  final Widget? suffixIcon;
  final Function(String)? onSubmitted;
  final double screenWidth;
  final double screenHeight;

  const _ModernTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.screenWidth,
    required this.screenHeight,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  State<_ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<_ModernTextField> {
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
    final sw = widget.screenWidth;
    final radius = BorderRadius.circular(sw * 0.028);
    final iconSize = (sw * 0.038).clamp(14.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: (sw * 0.034).clamp(11.0, 15.0),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: sw * 0.018),
        Container(
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
                  icon: widget.prefixIcon,
                  color: _isFocused ? Colors.red : Colors.grey[500]!,
                  size: iconSize,
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
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    style: TextStyle(
                      fontSize: (sw * 0.038).clamp(12.0, 17.0),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
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
                      contentPadding: EdgeInsets.symmetric(
                        vertical: sw * 0.026,
                      ),
                      suffixIcon: widget.suffixIcon,
                    ),
                    onSubmitted: widget.onSubmitted,
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

// ═══════════════════════════════════════════════════════════════════════════
// No Leading Zero Formatter
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
// Modern Phone Field Component
// ══════════════════════════════════════════════════���════════════════════════

class _ModernPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Function(String)? onSubmitted;
  final double screenWidth;
  final double screenHeight;

  const _ModernPhoneField({
    required this.controller,
    required this.focusNode,
    required this.screenWidth,
    required this.screenHeight,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  State<_ModernPhoneField> createState() => _ModernPhoneFieldState();
}

class _ModernPhoneFieldState extends State<_ModernPhoneField> {
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
    final sw = widget.screenWidth;
    final sh = widget.screenHeight;
    final radius = BorderRadius.circular(sw * 0.032);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: (sw * 0.036).clamp(12, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: sh * 0.008),
        Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white,
            border: Border.all(
              color: _isFocused ? Colors.red : Colors.grey[200]!,
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: sw * 0.04),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCall,
                  color: _isFocused ? Colors.red : Colors.grey[500]!,
                  size: (sw * 0.038).clamp(14, 18),
                ),
              ),
              SizedBox(width: sw * 0.025),
              Text(
                '+233',
                style: TextStyle(
                  fontSize: (sw * 0.038).clamp(13, 17),
                  fontWeight: FontWeight.w600,
                  color: _isFocused ? Colors.red : Colors.black87,
                ),
              ),
              SizedBox(width: sw * 0.025),
              Container(width: 1, height: sw * 0.055, color: Colors.grey[300]),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  maxLength: 9,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _NoLeadingZeroFormatter(),
                  ],
                  style: TextStyle(
                    fontSize: (sw * 0.038).clamp(13, 17),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '24 123 4567',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                      fontSize: (sw * 0.038).clamp(13, 17),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: sw * 0.03,
                      vertical: sh * 0.018,
                    ),
                  ),
                  onSubmitted: widget.onSubmitted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
