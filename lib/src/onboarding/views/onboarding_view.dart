import 'package:bagyesrushappusernew/constant/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../constant/constant.dart';
import '../../../constant/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../models/app_role.dart';
import '../viewmodels/onboarding_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Design tokens — "Role select, modernised" rebrand
// ═══════════════════════════════════════════════════════════════════════════

const Color _heroBg = AppColors.surfaceVariant;
const Color _cardSelectedBg = Color(0xFFFFF5F5);
const Color _tileUnselectedBg = AppColors.surfaceVariant;
const Color _ctaDisabledBg = Color(0xFFECECF1);

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Hero card animations
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _heroSlide =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _heroController,
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
    _heroController.forward();
    _cardsController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
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
      context.push(destination);
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

  String _ctaLabel(OnboardingViewModel viewModel) {
    final selected = viewModel.state.selectedRole;
    if (selected == null) return 'Select an option';
    return RoleOption.options
        .firstWhere((option) => option.role == selected)
        .ctaText;
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
                        SizedBox(height: size.height * 0.02),

                        // Hero Card — logo, brand badge, headline & subtext
                        FadeTransition(
                          opacity: _heroFade,
                          child: SlideTransition(
                            position: _heroSlide,
                            child: _buildHeroCard(size),
                          ),
                        ),

                        SizedBox(height: size.height * 0.03),

                        // "I am a" label
                        _buildSectionLabel(size),

                        SizedBox(height: size.height * 0.015),

                        // Role Cards
                        _buildRoleCards(size, viewModel),

                        SizedBox(height: size.height * 0.02),

                        // Continue Button
                        _buildContinueButton(size, viewModel),

                        const Spacer(),
                        SizedBox(height: size.height * 0.02),
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

  Widget _buildHeroCard(Size size) {
    final radius = size.width * 0.075;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        size.width * 0.065,
        size.width * 0.065,
        size.width * 0.065,
        size.width * 0.075,
      ),
      decoration: BoxDecoration(
        color: _heroBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative accent glows
          Positioned(
            right: -size.width * 0.15,
            top: -size.width * 0.18,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: -size.width * 0.12,
            bottom: -size.width * 0.2,
            child: Container(
              width: size.width * 0.4,
              height: size.width * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.vendorHome),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size.width * 0.03),
                      child: Image.asset(
                        AssetImages.bagyesLogo,
                        width: size.width * 0.19,
                        height: size.width * 0.19,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.028,
                      vertical: size.width * 0.018,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'RUSH',
                      style: TextStyle(
                        fontSize: size.width * 0.025,
                        fontWeight: FontWeight.w700,
                        letterSpacing: size.width * 0.0035,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.width * 0.045),
              Text(
                "Let's get\nyou set up.",
                style: TextStyle(
                  fontSize: size.width * 0.085,
                  fontWeight: FontWeight.w800,
                  letterSpacing: size.width * -0.0025,
                  height: 1.05,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: size.width * 0.02),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.62),
                child: Text(
                  "Pick how you'll use Bagyes. You can change this later in settings.",
                  style: TextStyle(
                    fontSize: size.width * 0.0375,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(Size size) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'I AM A',
        style: TextStyle(
          fontSize: size.width * 0.028,
          fontWeight: FontWeight.w700,
          letterSpacing: size.width * 0.0045,
          color: AppColors.textSecondary,
        ),
      ),
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
                  padding: EdgeInsets.only(bottom: size.height * 0.015),
                  child: _RoleCard(
                    size: size,
                    option: options[index],
                    isSelected:
                        viewModel.state.selectedRole == options[index].role,
                    onTap: () {
                      viewModel.selectRole(options[index].role);
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
    final radius = size.width * 0.045;

    return InkWell(
      onTap: isEnabled ? () => _handleRoleSelection(context, viewModel) : null,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.width * 0.045),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: isEnabled ? primaryColor : _ctaDisabledBg,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.08),
                    blurRadius: size.width * 0.02,
                    offset: Offset(0, size.height * 0.004),
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
                  _ctaLabel(viewModel),
                  style: TextStyle(
                    color: isEnabled ? Colors.white : AppColors.textSecondary,
                    fontSize: size.width * 0.041,
                    fontWeight: FontWeight.w700,
                    letterSpacing: size.width * -0.001,
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
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Log in',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push(AppRoutes.login);
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
    final radius = size.width * 0.055;
    final innerPadding = size.width * 0.04;
    final iconContainerSize = size.width * 0.13;
    final indicatorSize = size.width * 0.055;

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
          color: widget.isSelected ? _cardSelectedBg : Colors.white,
          border: Border.all(
            color: widget.isSelected ? primaryColor : AppColors.border,
            width: 1.5,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.05),
                    blurRadius: size.width * 0.025,
                    offset: Offset(0, size.height * 0.005),
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius * 0.65),
                  color: widget.isSelected
                      ? primaryColor.withValues(alpha: 0.12)
                      : _tileUnselectedBg,
                ),
                child: Padding(
                  padding: EdgeInsets.all(iconContainerSize * 0.14),
                  child: Image.asset(widget.option.iconAsset),
                ),
              ),

              SizedBox(width: size.width * 0.035),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.title,
                      style: TextStyle(
                        fontSize: size.width * 0.0425,
                        fontWeight: FontWeight.w700,
                        letterSpacing: size.width * -0.001,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: size.height * 0.004),
                    Text(
                      widget.option.description,
                      style: TextStyle(
                        fontSize: size.width * 0.0335,
                        color: AppColors.textSecondary,
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
                    color: widget.isSelected
                        ? primaryColor
                        : AppColors.border,
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
