import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../constant/constant.dart';
import '../../../core/router/app_routes.dart';
import '../models/app_role.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  late AnimationController _illustrationController;
  late AnimationController _cardsController;
  late Animation<double> _illustrationFade;
  late Animation<Offset> _illustrationSlide;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Illustration animations
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _illustrationFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _illustrationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _illustrationSlide =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _illustrationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Card staggered animations
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardAnimations = List.generate(
      2,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(
            0.2 + (index * 0.2),
            0.6 + (index * 0.2),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    // Start animations
    _illustrationController.forward();
    _cardsController.forward();
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Future<void> _handleRoleSelection(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) async {
    final success = await viewModel.completeOnboarding();

    if (!context.mounted) return;

    if (success) {
      final destination = viewModel.getNavigationDestination();
      context.go(destination);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.state.errorMessage ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewModel = context.watch<OnboardingViewModel>();

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
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.04),

                        // Illustration Section
                        FadeTransition(
                          opacity: _illustrationFade,
                          child: SlideTransition(
                            position: _illustrationSlide,
                            child: _buildIllustration(size, isTablet),
                          ),
                        ),

                        SizedBox(height: size.height * 0.04),

                        // Header
                        _buildHeader(size),

                        SizedBox(height: size.height * 0.03),

                        // Role Cards
                        _buildRoleCards(size, viewModel),

                        SizedBox(height: size.height * 0.03),

                        // Continue Button
                        _buildContinueButton(size, viewModel),

                        const Spacer(),

                        // Login Link
                        _buildLoginLink(size),

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

  Widget _buildIllustration(Size size, bool isTablet) {
    final illustrationSize = isTablet ? size.width * 0.4 : size.width * 0.5;
    final radius = size.width * 0.06;

    return Container(
      width: illustrationSize,
      height: illustrationSize,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(AssetImages.bagyesLogo, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.go(AppRoutes.vendorHome);
          },
          child: Text(
            'Welcome ',
            style: TextStyle(
              fontSize: size.width * 0.07,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          'Please select how you would like to proceed',
          style: TextStyle(
            fontSize: size.width * 0.038,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleCards(Size size, OnboardingViewModel viewModel) {
    final options = RoleOption.options;

    return Column(
      children: List.generate(
        options.length,
        (index) => AnimatedBuilder(
          animation: _cardAnimations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _cardAnimations[index].value,
              child: Transform.translate(
                offset: Offset(
                  0,
                  size.height * 0.04 * (1 - _cardAnimations[index].value),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.02),
                  child: _RoleCard(
                    size: size,
                    option: options[index],
                    isSelected:
                        viewModel.state.selectedRole == options[index].role,
                    onTap: () {
                      viewModel.selectRole(options[index].role);
                      if (options[index].role == AppRole.user) {
                        _handleRoleSelection(context, viewModel);
                      }
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueButton(Size size, OnboardingViewModel viewModel) {
    final isEnabled =
        viewModel.state.selectedRole != null && !viewModel.state.isLoading;
    final radius = size.width * 0.04;

    return InkWell(
      onTap: isEnabled ? () => _handleRoleSelection(context, viewModel) : null,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: size.height * 0.07,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: isEnabled ? primaryColor : Colors.grey[300],
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: size.width * 0.03,
                    offset: Offset(0, size.height * 0.008),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: viewModel.state.isLoading
              ? SizedBox(
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Continue',
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey[500],
                    fontSize: size.width * 0.042,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: size.height * 0.02),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: Colors.grey[600],
            ),
            children: [
              TextSpan(
                text: 'Log in',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.go(AppRoutes.login);
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Role Card Component
// ═══════════════════════════════════════════════════════════════════════════

class _RoleCard extends StatefulWidget {
  final Size size;
  final RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.size,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = size.width * 0.05;
    final innerPadding = size.width * 0.05;
    final iconContainerSize = size.width * 0.14;
    final indicatorSize = size.width * 0.06;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _isPressed ? 0.98 : 1.0,
            _isPressed ? 0.98 : 1.0,
            _isPressed ? 0.98 : 1.0,
            1.0,
          ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: Colors.white,
          border: Border.all(
            color: widget.isSelected
                ? primaryColor.withValues(alpha: 0.5)
                : Colors.grey[300]!,
            width: widget.isSelected ? 2.0 : 1.5,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: size.width * 0.04,
                    offset: Offset(0, size.height * 0.01),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: size.width * 0.02,
                    offset: Offset(0, size.height * 0.003),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(innerPadding),
          child: Row(
            children: [
              // Icon
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius * 0.7),
                  color: Colors.grey[100],
                ),
                child: Padding(
                  padding: EdgeInsets.all(iconContainerSize * 0.2),
                  child: Image.asset(widget.option.iconAsset),
                ),
              ),

              SizedBox(width: size.width * 0.04),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.title,
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? primaryColor
                            : Colors.black87,
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      widget.option.description,
                      style: TextStyle(
                        fontSize: size.width * 0.033,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: size.width * 0.02),

              // Selection Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: indicatorSize,
                height: indicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected ? primaryColor : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Icon(
                        Icons.check,
                        size: indicatorSize * 0.65,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
