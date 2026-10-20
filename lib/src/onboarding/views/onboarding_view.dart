import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../constant/app_theme.dart';
import '../../../constant/app_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/brand_pattern_background.dart';
import '../../../core/widgets/gopady_logo.dart';
import '../../../core/widgets/skyline_watermark.dart';
import '../../auth/views/widgets/auth_back_button.dart';
import '../models/app_role.dart';
import '../viewmodels/onboarding_viewmodel.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Brand moment — brand-green surface (same as the splash), yellow call-to-action
// ═══════════════════════════════════════════════════════════════════════════

const Color _cardBorderIdle = Color(0x1AFFFFFF);
const Color _cardIdleFill = Color(0x1AFFFFFF);
const Color _cardSelectedFill = Color(0x2EFFFFFF);
const Color _glassBorder = Color(0x33FFFFFF);

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: AppMotion.intro,
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// True when a guest opened this from a "Create account" prompt — they
  /// get a back arrow instead of "Continue as guest" (they already are one).
  bool get _openedFromGuestMode => ModalRoute.of(context)?.canPop ?? false;

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
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            Positioned.fill(
              child: BrandReveal(
                animation: _introController,
                end: 0.45,
                child: const BrandPatternBackground(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BrandReveal(
                animation: _introController,
                begin: 0.05,
                end: 0.6,
                slideFrom: const Offset(0, 0.25),
                child: const SkylineWatermark(
                  color: AppColors.primaryDark,
                  maxHeightFactor: 0.3,
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  final horizontalPadding = isTablet
                      ? constraints.maxWidth * 0.15
                      : constraints.maxWidth * 0.06;

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.02),

                              // Hero Card — logo, brand badge, headline & subtext
                              BrandReveal(
                                animation: _introController,
                                begin: 0.15,
                                end: 0.65,
                                slideFrom: const Offset(0, 0.06),
                                blurFrom: size.width * 0.02,
                                child: _buildHeroContent(size),
                              ),

                              SizedBox(height: size.height * 0.03),

                              // "I am a" label
                              BrandReveal(
                                animation: _introController,
                                begin: 0.4,
                                end: 0.7,
                                child: _buildSectionLabel(size),
                              ),

                              SizedBox(height: size.height * 0.015),

                              // Role Cards
                              _buildRoleCards(size, viewModel),

                              SizedBox(height: size.height * 0.08),

                              // Continue Button
                              BrandReveal(
                                animation: _introController,
                                begin: 0.75,
                                end: 1,
                                slideFrom: const Offset(0, 0.3),
                                child: _buildContinueButton(size, viewModel),
                              ),

                              const Spacer(),
                              SizedBox(height: size.height * 0.02),
                              // Login Link
                              BrandReveal(
                                animation: _introController,
                                begin: 0.85,
                                end: 1,
                                child: Column(
                                  children: [
                                    _buildLoginLink(size),
                                    if (!_openedFromGuestMode)
                                      _buildGuestLink(size),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeroContent(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_openedFromGuestMode) ...[
              const AuthBackButton(onDark: true),
              SizedBox(width: size.width * 0.03),
            ],
            GestureDetector(
              onTap: () => context.go(AppRoutes.vendorHome),
              child: GoPadyLogo(
                width: (size.width * 0.5).clamp(GoPadyLogo.minLockupWidth, 280),
                variant: GoPadyLogoVariant.onDark,
              ),
            ),
          ],
        ),
        SizedBox(height: size.width * 0.05),
        Text(
          "Let's get\nyou set up.",
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: size.width * 0.085,
            fontWeight: FontWeight.w800,
            letterSpacing: size.width * -0.003,
            height: 1.05,
            color: AppColors.onDark,
          ),
        ),
        SizedBox(height: size.width * 0.02),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width * 0.7),
          child: Text(
            "Pick how you'll use GoPady. You can change this later in settings.",
            style: TextStyle(
              fontSize: size.width * 0.0375,
              height: 1.45,
              color: AppColors.onDarkMuted,
            ),
          ),
        ),
      ],
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
          color: AppColors.onDarkMuted,
        ),
      ),
    );
  }

  Widget _buildRoleCards(Size size, OnboardingViewModel viewModel) {
    final options = RoleOption.options;

    return Column(
      children: List.generate(
        options.length,
        (index) => BrandReveal(
          animation: _introController,
          begin: 0.45 + index * 0.12,
          end: 0.8 + index * 0.12,
          slideFrom: const Offset(0, 0.2),
          child: Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.015),
            child: _RoleCard(
              size: size,
              option: options[index],
              isSelected: viewModel.state.selectedRole == options[index].role,
              onTap: () => viewModel.selectRole(options[index].role),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(Size size, OnboardingViewModel viewModel) {
    final isEnabled =
        viewModel.state.selectedRole != null && !viewModel.state.isLoading;
    final radius = size.width * 0.03;

    return InkWell(
      onTap: isEnabled ? () => _handleRoleSelection(context, viewModel) : null,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.width * 0.045),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: isEnabled ? AppColors.accent : AppColors.primaryDark,
        ),
        child: Center(
          child: viewModel.state.isLoading
              ? SizedBox(
                  width: size.width * 0.06,
                  height: size.width * 0.06,
                  child: const CircularProgressIndicator(
                    color: AppColors.onAccent,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  _ctaLabel(viewModel),
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.onAccent
                        : AppColors.onDarkSubtle,
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
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Log in',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: AppColors.accent,
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

  /// Opt-in guest mode (Apple guideline 5.1.1(v)): browse without an
  /// account; sign-in is asked for only at account features (see AuthGate).
  Widget _buildGuestLink(Size size) {
    return TextButton.icon(
      onPressed: () => context.go(AppRoutes.home),
      iconAlignment: IconAlignment.end,
      icon: Icon(Icons.arrow_forward_rounded, size: size.width * 0.045),
      label: Text(
        'Continue as guest',
        style: TextStyle(
          fontSize: size.width * 0.037,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.onDark,
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.width * 0.025,
        ),
        shape: const StadiumBorder(side: BorderSide(color: _glassBorder)),
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
    const radius = AppRadius.sheet;
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
          color: widget.isSelected ? _cardSelectedFill : _cardIdleFill,
          border: Border.all(
            color: widget.isSelected ? AppColors.accent : _cardBorderIdle,
            width: 1.5,
          ),
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
                  color: AppColors.surface,
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
                        fontFamily: AppFonts.display,
                        fontSize: size.width * 0.0425,
                        fontWeight: FontWeight.w700,
                        letterSpacing: size.width * -0.001,
                        color: AppColors.onDark,
                      ),
                    ),
                    SizedBox(height: size.height * 0.004),
                    Text(
                      widget.option.description,
                      style: TextStyle(
                        fontSize: size.width * 0.0335,
                        color: AppColors.onDarkMuted,
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
                  color: widget.isSelected
                      ? AppColors.accent
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.accent
                        : AppColors.onDarkSubtle,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? Icon(
                        Icons.check,
                        size: indicatorSize * 0.65,
                        color: AppColors.onAccent,
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
