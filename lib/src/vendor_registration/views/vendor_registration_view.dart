import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../constant/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../../../constant/image_constants.dart';
import '../models/vendor_enums.dart';
import '../viewmodels/vendor_registration_viewmodel.dart';
import 'widgets/step_progress_bar.dart';
import 'steps/business_details_step.dart';
import 'steps/create_password_step.dart';
import 'steps/operational_details_step.dart';
import 'steps/verification_step.dart';

/// Main vendor registration wizard view.
///
/// Orchestrates navigation between steps with animated transitions.
class VendorRegistrationView extends StatefulWidget {
  const VendorRegistrationView({super.key});

  @override
  State<VendorRegistrationView> createState() =>
      _VendorRegistrationViewState();
}

class _VendorRegistrationViewState extends State<VendorRegistrationView>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorRegistrationViewModel>().loadCuisineTypes();
      context.read<AuthViewmodel>().addListener(_onAuthStateChanged);
    });
  }

  void _onAuthStateChanged() {
    final authVm = context.read<AuthViewmodel>();
    final state = authVm.state;

    if (state is VendorRegistered) {
      // Registration succeeded — move to OTP verification step
      final vm = context.read<VendorRegistrationViewModel>();
      vm.goToStep(VendorRegistrationStep.verifySubmit);
      _animateStepTransition();
      authVm.resetState();
    } else if (state is OTPVerified) {
      // Phone verified — registration complete
      authVm.resetState();
      if (!mounted) return;
      CustomDialog.showSuccess(
        context: context,
        title: 'Registration Successful!',
        subtitle:
            'Your account is ready. Log in and complete your document verification from your dashboard.',
        onConfirm: () => context.go(AppRoutes.login),
      );
    } else if (state is AuthError) {
      final vm = context.read<VendorRegistrationViewModel>();
      vm.setError(state.message);
      authVm.resetState();
    }
  }

  void _setupAnimations() {
    // Header entrance animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Content entrance animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  void _animateStepTransition() {
    _contentController.reset();
    _contentController.forward();
  }

  @override
  void dispose() {
    context.read<AuthViewmodel>().removeListener(_onAuthStateChanged);
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleBack(VendorRegistrationViewModel vm) {
    if (vm.state.canGoBack) {
      vm.previousStep();
      _animateStepTransition();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  void _handleNext(VendorRegistrationViewModel vm) {
    if (vm.state.currentStep == VendorRegistrationStep.createPassword) {
      _handleVendorRegister(vm);
      return;
    }
    // verifySubmit has no Continue button — OTP flow is self-contained
    final success = vm.nextStep();
    if (success) {
      _animateStepTransition();
    }
  }

  Future<void> _handleVendorRegister(VendorRegistrationViewModel vm) async {
    // Validate operational details first
    if (!vm.validateAndMarkComplete()) return;

    final b = vm.state.businessDetails;
    final o = vm.state.operationalDetails;
    final p = vm.state.payoutDetails;

    await context.read<AuthViewmodel>().vendorRegister(
      email: b.email,
      phone: b.phone,
      password: b.password,
      confirmPassword: b.confirmPassword,
      businessName: b.businessName,
      businessType: b.businessType?.name ?? '',
      contactPersonName: b.contactPersonName,
      businessAddress: b.businessAddress,
      city: b.city,
      description: b.description ?? '',
      taxIdentificationNumber: b.taxIdentificationNumber ?? '',
      cuisineTypes: o.cuisineTypes,
      deliveryRadiusKm: o.deliveryRadiusKm,
      openingTime: o.openingTime,
      closingTime: o.closingTime,
      operatingDays: o.operatingDays.map((d) => d.toLowerCase()).toList(),
      estimatedPrepTimeMinutes: o.estimatedPrepTimeMinutes,
      bankName: p.bankName,
      accountNumber: p.accountNumber,
      accountName: p.accountName,
      branchCode: p.branchCode ?? '',
    );
    // Result is handled in _onAuthStateChanged
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vm = context.watch<VendorRegistrationViewModel>();

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet
                ? constraints.maxWidth * 0.12
                : constraints.maxWidth * 0.05;

            return Column(
              children: [
                // ── Fixed Header ──
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: size.height * 0.015),
                          _buildTopBar(size, vm),
                          SizedBox(height: size.height * 0.02),
                          StepProgressBar(
                            currentStep: vm.state.currentStep,
                            completedSteps: vm.state.completedSteps,
                          ),
                          SizedBox(height: size.height * 0.015),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Scrollable Content ──
                Expanded(
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.01),
                            // Error message
                            if (vm.state.errorMessage != null)
                              _buildErrorBanner(size, vm),
                            _buildCurrentStep(vm),
                            SizedBox(height: size.height * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Fixed Bottom Buttons ──
                _buildBottomButtons(size, vm, horizontalPadding),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(Size size, VendorRegistrationViewModel vm) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _handleBack(vm),
          child: Container(
            width: size.width * 0.1,
            height: size.width * 0.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.border),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: size.width * 0.05,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        Expanded(
          child: Text(
            'Vendor Registration',
            style: TextStyle(
              fontSize: size.width * 0.048,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Step counter
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.03,
            vertical: size.height * 0.006,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.04),
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          child: Text(
            '${vm.state.currentStep.index + 1}/${VendorRegistrationStep.totalSteps}',
            style: TextStyle(
              fontSize: size.width * 0.032,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(Size size, VendorRegistrationViewModel vm) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      padding: EdgeInsets.all(size.width * 0.035),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.width * 0.025),
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert01,
            color: AppColors.error,
            size: size.width * 0.05,
          ),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Text(
              vm.state.errorMessage!,
              style: TextStyle(
                fontSize: size.width * 0.032,
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: vm.clearError,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppColors.error,
              size: size.width * 0.045,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(VendorRegistrationViewModel vm) {
    switch (vm.state.currentStep) {
      case VendorRegistrationStep.businessDetails:
        return BusinessDetailsStep(
          data: vm.state.businessDetails,
          onChanged: vm.updateBusinessDetails,
        );
      case VendorRegistrationStep.createPassword:
        return CreatePasswordStep(
          data: vm.state.businessDetails,
          onChanged: vm.updateBusinessDetails,
        );
      case VendorRegistrationStep.operationalDetails:
        return OperationalDetailsStep(
          data: vm.state.operationalDetails,
          onChanged: vm.updateOperationalDetails,
          availableCategories: vm.availableCategories,
          isLoadingCategories: vm.categoriesLoading,
          categoriesError: vm.categoriesError,
        );
      case VendorRegistrationStep.verifySubmit:
        final authVm = context.read<AuthViewmodel>();
        final authState = authVm.state;
        return VerificationStep(
          phone: vm.state.businessDetails.phone,
          isLoading: authState is AuthLoading,
          isOtpSent: authState is OTPSent || vm.state.isOtpVerified,
          isVerified: vm.state.isOtpVerified,
          onSendOtp: () => authVm.sendOtp(vm.state.businessDetails.phone),
          onVerifyOtp: (otp) => authVm.verifyOtp(
            phone: vm.state.businessDetails.phone,
            otp: otp,
          ),
        );
    }
  }

  Widget _buildBottomButtons(
    Size size,
    VendorRegistrationViewModel vm,
    double horizontalPadding,
  ) {
    // OTP step is self-contained — no bottom button needed
    if (vm.state.currentStep == VendorRegistrationStep.verifySubmit) {
      return const SizedBox.shrink();
    }

    final authState = context.watch<AuthViewmodel>().state;
    final isSubmitting = vm.state.currentStep == VendorRegistrationStep.createPassword
        && authState is AuthLoading;

    return Container(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: size.height * 0.015,
        bottom: size.height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: size.width * 0.03,
            offset: Offset(0, -size.height * 0.003),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (vm.state.canGoBack)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _handleBack(vm),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.019),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size.width * 0.035),
                    border: Border.all(color: AppColors.border),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: size.width * 0.038,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (vm.state.canGoBack) SizedBox(width: size.width * 0.03),

          // Next / Submit button
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: isSubmitting ? null : () => _handleNext(vm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: size.height * 0.019),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.width * 0.035),
                  color: isSubmitting
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: size.width * 0.025,
                      offset: Offset(0, size.height * 0.005),
                    ),
                  ],
                ),
                child: Center(
                  child: isSubmitting
                      ? SizedBox(
                          width: size.width * 0.05,
                          height: size.width * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
