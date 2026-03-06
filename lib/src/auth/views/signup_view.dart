import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../constant/constant.dart';
import '../viewmodels/auth_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _passwordController.addListener(_checkPasswordStrength);
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

    // Check length
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.1;

    // Check for lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;

    // Check for uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;

    // Check for numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;

    // Check for special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    // Determine strength text and color
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
    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }
    if (_phoneController.text.length < 10) {
      _showError('Please enter a valid 10-digit phone number');
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
      iconPath: AssetImages.bagyesLogo,
      isLottie: false,
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

  void _submitSignup() {
    if (!_validateStep2()) return;

    final authViewModel = context.read<AuthViewModel>();
    final phone = _phoneController.text.trim();

    // Store signup data temporarily in the ViewModel for later use
    authViewModel.storeSignupData({
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': phone,
      'password': _passwordController.text,
      'referralCode': _referralController.text.trim(),
    });

    // Send OTP for phone verification
    authViewModel.sendOtp(phone).then((_) {
      final state = authViewModel.state;
      if (state.status == AuthStatus.initial && state.errorMessage == null) {
        // Navigate to OTP verification
        AppNavigator.toOtp(context);
      } else if (state.status == AuthStatus.error) {
        CustomDialog.showError(
          context: context,
          title: 'Error',
          subtitle: state.errorMessage ?? 'Failed to send OTP',
          iconPath: AssetImages.bagyesLogo,
          isLottie: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _referralFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authViewModel = context.watch<AuthViewModel>();
    final loading = authViewModel.state.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet
                ? constraints.maxWidth * 0.15
                : constraints.maxWidth * 0.06;

            return Column(
              children: [
                // Header with back button
                _buildHeader(size, horizontalPadding),

                // Progress indicator
                _buildProgressIndicator(size, horizontalPadding),

                // Form content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(size, horizontalPadding, loading),
                      _buildStep2(size, horizontalPadding, loading),
                    ],
                  ),
                ),

                // Bottom section with button
                _buildBottomSection(size, horizontalPadding, loading),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Size size, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: size.height * 0.02,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                AppNavigator.toOnboarding(context);
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            _currentStep == 0 ? 'Personal Details' : 'Security',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Size size, double horizontalPadding) {
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
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: _currentStep >= 1 ? Colors.red : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 2',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(Size size, double horizontalPadding, bool loading) {
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
                SizedBox(height: size.height * 0.03),
                const Text(
                  "Let's get you started",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new account to get started',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                _ModernTextField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  onSubmitted: (_) => _lastNameFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                _ModernTextField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                _ModernTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email Address',
                  hint: 'your.email@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !loading,
                  onSubmitted: (_) => _phoneFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                _ModernPhoneField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !loading,
                  onSubmitted: (_) => _referralFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                _ModernTextField(
                  controller: _referralController,
                  focusNode: _referralFocus,
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code',
                  prefixIcon: Icons.card_giftcard_outlined,
                  textInputAction: TextInputAction.done,
                  enabled: !loading,
                  onSubmitted: (_) => _nextStep(),
                ),
                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(Size size, double horizontalPadding, bool loading) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: size.height * 0.03),
            const Text(
              'Secure your account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a strong password to protect your account',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: size.height * 0.04),
            _ModernTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !loading,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPasswordStrengthIndicator(),
            ],
            const SizedBox(height: 16),
            _ModernTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              enabled: !loading,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              onSubmitted: (_) => _nextStep(),
            ),
            const SizedBox(height: 20),
            _buildPasswordRequirements(),
            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _passwordStrengthText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _passwordStrengthColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirement('At least 8 characters', password.length >= 8),
          _buildRequirement(
            'At least one number',
            password.contains(RegExp(r'[0-9]')),
          ),
          _buildRequirement(
            'At least one special character (!@#\$%^&*)',
            password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: met ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey[600],
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    Size size,
    double horizontalPadding,
    bool loading,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: size.height * 0.02,
      ),
      child: Column(
        children: [
          // Continue/Register button
          InkWell(
            onTap: loading ? null : _nextStep,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: loading
                    ? const SpinKitCircle(size: 24, color: Colors.white)
                    : Text(
                        _currentStep == 0 ? 'Continue' : 'Send OTP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Login link
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                children: [
                  TextSpan(
                    text: 'Log in',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        AppNavigator.toLogin(context);
                      },
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

// Modern TextField Component
class _ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;
  final Widget? suffixIcon;
  final Function(String)? onSubmitted;

  const _ModernTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefixIcon,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? Colors.red : Colors.grey[600],
                size: 22,
              ),
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onSubmitted: widget.onSubmitted,
          ),
        ),
      ],
    );
  }
}

// Modern Phone Field Component
class _ModernPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Function(String)? onSubmitted;

  const _ModernPhoneField({
    required this.controller,
    required this.focusNode,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: _isFocused ? Colors.red : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  '+233',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isFocused ? Colors.red : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: widget.enabled,
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
