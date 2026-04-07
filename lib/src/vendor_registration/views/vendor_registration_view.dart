import 'package:bagyesrushappusernew/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../constant/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/custom_dialogs.dart';
import '../models/vendor_enums.dart';
import '../viewmodels/vendor_registration_viewmodel.dart';
import 'widgets/step_progress_bar.dart';
import 'steps/business_details_step.dart';
import 'steps/create_password_step.dart';
import 'steps/operational_details_step.dart';
import 'steps/verification_step.dart';

/// Main vendor registration wizard view.
///
/// Orchestration logic (auth state transitions, API calls) lives entirely in
/// [VendorRegistrationViewModel]. This view is responsible only for:
///   - Rendering the current step
///   - Triggering VM methods on user actions
///   - Showing the success dialog when registration is complete
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
      final vm = context.read<VendorRegistrationViewModel>();
      vm.loadBusinessTypes();
      vm.loadCuisineTypes();
      vm.addListener(_onVmStateChanged);
    });
  }

  /// Handles navigation/dialog — the only view-level concern left.
  void _onVmStateChanged() {
    if (!mounted) return;
    final vm = context.read<VendorRegistrationViewModel>();
    final state = vm.state;

    if (state.status == VendorRegistrationStatus.complete) {
      vm.resetStatus();
      CustomDialog.showSuccess(
        context: context,
        title: 'Registration Successful!',
        subtitle:
            'Your account is ready. Complete your document verification from your dashboard.',
        onConfirm: () => context.go(AppRoutes.vendorHome),
      );
    } else if (state.status == VendorRegistrationStatus.error &&
        state.errorMessage != null) {
      vm.clearError();
      CustomDialog.showError(
        context: context,
        title: 'Registration Failed',
        subtitle: state.errorMessage!,
      );
    }
  }

  void _setupAnimations() {
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
    context.read<VendorRegistrationViewModel>().removeListener(_onVmStateChanged);
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
    // Flush any pending text from a focused field before validation runs.
    // GestureDetector (the Continue button) does not steal focus, so without
    // this the focus listener on the active field never fires and the VM state
    // still holds the stale empty value.
    FocusManager.instance.primaryFocus?.unfocus();

    if (vm.state.currentStep == VendorRegistrationStep.createPassword) {
      vm.submitRegistration();
      return;
    }
    final success = vm.nextStep();
    if (success) {
      _animateStepTransition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Targeted selects — each widget subtree only rebuilds for its own data.
    final currentStep = context.select(
      (VendorRegistrationViewModel vm) => vm.state.currentStep,
    );
    final canGoBack = context.select(
      (VendorRegistrationViewModel vm) => vm.state.canGoBack,
    );
    final errorMessage = context.select(
      (VendorRegistrationViewModel vm) => vm.state.errorMessage,
    );
    final isSubmitting = context.select(
      (VendorRegistrationViewModel vm) =>
          vm.state.currentStep == VendorRegistrationStep.createPassword &&
          vm.state.status == VendorRegistrationStatus.loading,
    );

    // These selectors ensure the build method re-runs when async state changes.
    // Business types — loaded after initState.
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.availableBusinessTypes,
    );
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.isBusinessTypesLoading,
    );
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.businessTypesError,
    );
    // OTP flow — isOtpSent/isOtpVerified/status change after registration
    // submits and the server responds; without these the VerificationStep
    // never receives updated props and stays stuck on the pre-send state.
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.isOtpSent,
    );
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.isOtpVerified,
    );
    context.select(
      (VendorRegistrationViewModel vm) => vm.state.status,
    );

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
                          _buildTopBar(size, currentStep, canGoBack),
                          SizedBox(height: size.height * 0.02),
                          // StepProgressBar only needs step/completedSteps
                          _StepProgressBarSlice(),
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
                            if (errorMessage != null)
                              _buildErrorBanner(size, errorMessage),
                            _buildCurrentStep(currentStep),
                            SizedBox(height: size.height * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Fixed Bottom Buttons ──
                _buildBottomButtons(
                  size,
                  currentStep,
                  canGoBack,
                  isSubmitting,
                  horizontalPadding,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Size size,
    VendorRegistrationStep currentStep,
    bool canGoBack,
  ) {
    final vm = context.read<VendorRegistrationViewModel>();
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
            '${currentStep.index + 1}/${VendorRegistrationStep.totalSteps}',
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

  Widget _buildErrorBanner(Size size, String message) {
    final vm = context.read<VendorRegistrationViewModel>();
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
              message,
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

  Widget _buildCurrentStep(VendorRegistrationStep currentStep) {
    final vm = context.read<VendorRegistrationViewModel>();
    switch (currentStep) {
      case VendorRegistrationStep.businessDetails:
        return BusinessDetailsStep(
          data: vm.state.businessDetails,
          onChanged: vm.updateBusinessDetails,
          businessTypes: vm.state.availableBusinessTypes,
          isLoadingBusinessTypes: vm.state.isBusinessTypesLoading,
          businessTypesError: vm.state.businessTypesError,
          onRetryBusinessTypes: vm.loadBusinessTypes,
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
          availableCategories: vm.state.availableCategories,
          isLoadingCategories: vm.state.isCategoriesLoading,
          categoriesError: vm.state.categoriesError,
          onRetryCategories: vm.loadCuisineTypes,
        );
      case VendorRegistrationStep.verifySubmit:
        final state = vm.state;
        final isLoading = state.status == VendorRegistrationStatus.loading;
        return VerificationStep(
          phone: state.businessDetails.phone,
          isLoading: isLoading,
          isOtpSent: state.isOtpSent || state.isOtpVerified,
          isVerified: state.isOtpVerified,
          isResumeFlow: state.isResumeFlow,
          onSendOtp: vm.sendOtp,
          onVerifyOtp: vm.verifyOtp,
        );
    }
  }

  Widget _buildBottomButtons(
    Size size,
    VendorRegistrationStep currentStep,
    bool canGoBack,
    bool isSubmitting,
    double horizontalPadding,
  ) {
    if (currentStep == VendorRegistrationStep.verifySubmit) {
      return const SizedBox.shrink();
    }

    final vm = context.read<VendorRegistrationViewModel>();

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
          if (canGoBack)
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
          if (canGoBack) SizedBox(width: size.width * 0.03),

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

/// Isolated widget so the progress bar only rebuilds when step/completedSteps change.
class _StepProgressBarSlice extends StatelessWidget {
  const _StepProgressBarSlice();

  @override
  Widget build(BuildContext context) {
    final currentStep = context.select(
      (VendorRegistrationViewModel vm) => vm.state.currentStep,
    );
    final completedSteps = context.select(
      (VendorRegistrationViewModel vm) => vm.state.completedSteps,
    );
    return StepProgressBar(
      currentStep: currentStep,
      completedSteps: completedSteps,
    );
  }
}
