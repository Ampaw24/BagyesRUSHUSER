import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/common/app/current_user_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import '../../vendor_registration/views/widgets/vendor_text_field.dart';
import '../viewmodel/vendor_kyc_viewmodel.dart';
import '../model/vendor_profile.dart';

class VendorKycView extends StatefulWidget {
  const VendorKycView({super.key});

  @override
  State<VendorKycView> createState() => _VendorKycViewState();
}

class _VendorKycViewState extends State<VendorKycView> with TickerProviderStateMixin {
  int _currentStep = 0;
  late final PageController _pageCtrl;
  late final AnimationController _progressCtrl;

  // Form keys and controllers for inline validations
  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  late final TextEditingController _tinCtrl;
  late final TextEditingController _idNumberCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tinCtrl = TextEditingController();
    _idNumberCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<VendorKycViewModel>();
      vm.reset();
      // Pre-fill TIN from profile if already exists
      final profile = context.read<CurrentUserProvider>().user?.profile as VendorProfile?;
      if (profile != null && profile.taxIdentificationNumber.isNotEmpty) {
        _tinCtrl.text = profile.taxIdentificationNumber;
        vm.setTinNumber(profile.taxIdentificationNumber);
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    _tinCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  void _nextStep(VendorKycViewModel vm) {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      vm.setTinNumber(_tinCtrl.text.trim());
    } else if (_currentStep == 1) {
      // Step 2 is document upload (optional files)
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _pickImage(BuildContext context, String docType) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    if (!context.mounted) return;
    final vm = context.read<VendorKycViewModel>();

    switch (docType) {
      case 'business_registration':
        vm.setBusinessCertPath(file.path);
      case 'food_safety_license':
        vm.setFoodSafetyLicensePath(file.path);
      case 'owner_id':
        vm.setOwnerIdPath(file.path);
      case 'selfie':
        vm.setSelfiePath(file.path);
    }
  }

  Future<void> _submit(VendorKycViewModel vm) async {
    if (!_step3FormKey.currentState!.validate()) return;
    vm.setIdNumber(_idNumberCtrl.text.trim());

    final success = await vm.submitKyc();
    if (success && mounted) {
      CustomDialog.showSuccess(
        context: context,
        title: 'KYC Submitted!',
        subtitle: 'Thank you for submitting your documents. Our team will review them within 24-48 hours.',
        onConfirm: () {
          context.go(AppRoutes.vendorHome);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final vm = context.watch<VendorKycViewModel>();
    final state = vm.state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'KYC Verification',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: w * 0.045,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mukta',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: w * 0.05),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Step Progress Indicator
                _buildStepper(w),
                const Divider(height: 1),

                // Error Banner
                if (state.errorMessage != null)
                  _buildErrorBanner(w, state.errorMessage!, vm),

                // Form PageView
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(w),
                      _buildStep2(w),
                      _buildStep3(w, vm),
                    ],
                  ),
                ),

                // Bottom Navigation Buttons
                _buildBottomButtons(w, vm),
              ],
            ),
          ),

          // Uploading/Submitting Overlay (Glassmorphism & animated spinkit)
          if (state.status == VendorKycStatus.uploading || state.status == VendorKycStatus.saving)
            _buildLoadingOverlay(w, h, state.uploadProgressMessage ?? 'Uploading files...'),
        ],
      ),
    );
  }

  Widget _buildStepper(double w) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: w * 0.04, horizontal: w * 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode(0, 'Store & TIN', w),
          _buildStepConnector(0, w),
          _buildStepNode(1, 'Documents', w),
          _buildStepConnector(1, w),
          _buildStepNode(2, 'Identity', w),
        ],
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, String label, double w) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: w * 0.08,
          height: w * 0.08,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : Colors.grey[200],
            border: Border.all(
              color: isDone
                  ? AppColors.success
                  : isActive
                      ? AppColors.primary
                      : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded, color: Colors.white, size: w * 0.045)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: w * 0.035,
                    ),
                  ),
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? AppColors.primary
                : isDone
                    ? AppColors.textPrimary
                    : AppColors.textHint,
            fontSize: w * 0.028,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Mukta',
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex, double w) {
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: w * 0.04, left: w * 0.02, right: w * 0.02),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 2,
          color: isDone ? AppColors.success : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(double w, String message, VendorKycViewModel vm) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.03),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: w * 0.05),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.error, fontSize: w * 0.032, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.error, size: w * 0.04),
            onPressed: vm.clearError,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(double w) {
    final user = context.watch<CurrentUserProvider>().user;
    final profile = user?.profile as VendorProfile?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComplianceCard(w),
            SizedBox(height: w * 0.05),

            // Store Info Summary (Read only)
            Text(
              'Verify Store Details',
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Mukta',
              ),
            ),
            SizedBox(height: w * 0.02),
            Container(
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(w * 0.03),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildStoreDetailRow('Business Name', profile?.businessName ?? 'N/A', w),
                  const Divider(height: 16),
                  _buildStoreDetailRow('Business Address', profile?.businessAddress ?? 'N/A', w),
                  const Divider(height: 16),
                  _buildStoreDetailRow('City', profile?.city ?? 'N/A', w),
                  const Divider(height: 16),
                  _buildStoreDetailRow('Email', user?.email ?? 'N/A', w),
                  const Divider(height: 16),
                  _buildStoreDetailRow('Phone Number', user?.phone ?? 'N/A', w),
                ],
              ),
            ),
            SizedBox(height: w * 0.06),

            // TIN Input
            VendorTextField(
              label: 'Tax Identification Number (TIN) *',
              hint: 'Enter your business TIN number',
              controller: _tinCtrl,
              keyboardType: TextInputType.text,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'TIN number is required';
                if (v.trim().length < 6) return 'Enter a valid TIN number';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDetailRow(String label, String value, double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: w * 0.034, fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: AppColors.textPrimary, fontSize: w * 0.034, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceCard(double w) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // Soft yellow warning
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange[800], size: w * 0.05),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'Compliance Policy: Standard food vending regulations in Ghana require all vendors to provide a valid TIN and verify business registration or hygiene documents. Please verify that your store details match your tax details.',
              style: TextStyle(
                color: Colors.brown[900],
                fontSize: w * 0.03,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(double w) {
    final vm = context.watch<VendorKycViewModel>();
    final state = vm.state;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Business Documents',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Mukta',
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Upload your official business permits to speed up verification. Scanned copies or high-quality photos are accepted.',
            style: TextStyle(
              fontSize: w * 0.032,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: w * 0.05),

          // Business Registration Certificate
          _buildUploadItem(
            title: 'Business Registration Certificate',
            subtitle: 'Company incorporation document (optional)',
            path: state.businessCertPath,
            onTap: () => _pickImage(context, 'business_registration'),
            onRemove: () => vm.setBusinessCertPath(null),
            w: w,
          ),
          SizedBox(height: w * 0.04),

          // Food Vending permit
          _buildUploadItem(
            title: 'Food Safety / Hygiene Permit',
            subtitle: 'Municipal hygiene or vending license (optional)',
            path: state.foodSafetyLicensePath,
            onTap: () => _pickImage(context, 'food_safety_license'),
            onRemove: () => vm.setFoodSafetyLicensePath(null),
            w: w,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(double w, VendorKycViewModel vm) {
    final state = vm.state;

    final idTypes = ['Ghana Card', 'Passport', 'Driver\'s License'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Mukta',
              ),
            ),
            SizedBox(height: w * 0.04),

            // ID Type horizontal selector
            Text(
              'Select ID Type *',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Row(
              children: idTypes.map((type) {
                final isSelected = state.idType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => vm.setIdType(type),
                    child: Container(
                      margin: EdgeInsets.only(right: type == idTypes.last ? 0 : w * 0.02),
                      padding: EdgeInsets.symmetric(vertical: w * 0.025),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(w * 0.025),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: w * 0.03,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: w * 0.05),

            // ID Number
            VendorTextField(
              label: 'ID Card Number *',
              hint: 'e.g. GHA-7182918-9',
              controller: _idNumberCtrl,
              keyboardType: TextInputType.text,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'ID card number is required';
                if (v.trim().length < 5) return 'Enter a valid ID number';
                return null;
              },
            ),
            SizedBox(height: w * 0.05),

            // Owner ID Card Photo upload
            _buildUploadItem(
              title: 'Owner / Manager ID Photo *',
              subtitle: 'Upload a clear photo of your ID Card',
              path: state.ownerIdPath,
              onTap: () => _pickImage(context, 'owner_id'),
              onRemove: () => vm.setOwnerIdPath(null),
              isRequired: true,
              w: w,
            ),
            SizedBox(height: w * 0.05),

            // Selfie upload with circle preview
            Text(
              'Vendor Manager Selfie *',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(context, 'selfie'),
                    child: Container(
                      width: w * 0.32,
                      height: w * 0.32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                        border: Border.all(
                          color: state.selfiePath != null ? AppColors.success : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: state.selfiePath != null
                            ? Image.file(
                                File(state.selfiePath!),
                                fit: BoxFit.cover,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, color: AppColors.textHint, size: w * 0.08),
                                  SizedBox(height: w * 0.01),
                                  Text(
                                    'Take Selfie',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: w * 0.026,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (state.selfiePath != null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => vm.setSelfiePath(null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadItem({
    required String title,
    required String subtitle,
    required String? path,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    bool isRequired = false,
    required double w,
  }) {
    final hasFile = path != null && path.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: hasFile ? AppColors.success : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.04, w * 0.04, w * 0.02),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: w * 0.035,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isRequired) ...[
                            const SizedBox(width: 4),
                            const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      SizedBox(height: w * 0.005),
                      Text(subtitle, style: TextStyle(fontSize: w * 0.028, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (hasFile)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    onPressed: onRemove,
                  )
              ],
            ),
          ),
          if (hasFile)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(w * 0.02),
                child: Container(
                  height: w * 0.35,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.file(
                    File(path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.all(w * 0.04),
                padding: EdgeInsets.symmetric(vertical: w * 0.05),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.025),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: w * 0.05),
                      SizedBox(width: w * 0.02),
                      Text(
                        'Upload Image',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: w * 0.032,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(double w, VendorKycViewModel vm) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: w * 0.035),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.03)),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: w * 0.036,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: w * 0.03),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 2) {
                  _nextStep(vm);
                } else {
                  _submit(vm);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: w * 0.035),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.03)),
              ),
              child: Text(
                _currentStep == 2 ? 'Submit Application' : 'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: w * 0.036,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(double w, double h, String progressMessage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: w * 0.8,
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.04),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitDoubleBounce(color: AppColors.primary, size: 50),
              SizedBox(height: w * 0.05),
              Text(
                'Submitting Verification',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: w * 0.02),
              Text(
                progressMessage,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: w * 0.032,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
