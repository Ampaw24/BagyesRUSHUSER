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
import '../viewmodel/vendor_kyc_viewmodel.dart';
import '../model/vendor_profile.dart';

class VendorKycView extends StatefulWidget {
  /// Which step to open on — e.g. jumping straight to the documents step
  /// (1) when the vendor taps "Verify identity documents" from the setup
  /// checklist, skipping the store-details step they may have already done.
  final int initialStep;

  const VendorKycView({super.key, this.initialStep = 0});

  @override
  State<VendorKycView> createState() => _VendorKycViewState();
}

class _VendorKycViewState extends State<VendorKycView> with TickerProviderStateMixin {
  late int _currentStep;
  late final PageController _pageCtrl;
  late final AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, 1);
    _pageCtrl = PageController(initialPage: _currentStep);
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorKycViewModel>().reset();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextStep(VendorKycViewModel vm) async {
    // Submits opening/closing time, operating days, and estimated prep
    // time via the operations-KYC endpoint before advancing — the loading
    // overlay covers this via VendorKycStatus.saving.
    final success = await vm.submitOperationalDetails();
    if (!success || !mounted) return;

    if (_currentStep < 1) {
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

  /// Picks an image, shows a preview confirmation dialog, and — only if the
  /// vendor confirms — immediately uploads it via [upload] (the backend only
  /// accepts one document per request). Used on the documents/identity steps
  /// so each document is submitted as soon as it's confirmed, rather than
  /// being staged locally and bundled into the final submit.
  Future<void> _pickConfirmAndUpload(
    BuildContext context, {
    required String label,
    required ValueChanged<String?> setLocalPath,
    required Future<bool> Function(String filePath) upload,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    if (!context.mounted) return;

    setLocalPath(file.path);

    await CustomDialog.showConfirmation(
      context: context,
      title: 'Use this photo?',
      subtitle: 'Make sure the $label is clear and all text is readable before submitting — it will be sent for verification right away.',
      confirmText: 'Yes, Submit',
      cancelText: 'Retake',
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(file.path),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      onConfirm: () => upload(file.path),
      onCancel: () => setLocalPath(null),
    );
  }

  Future<void> _submit(VendorKycViewModel vm) async {
    final profile = context.read<CurrentUserProvider>().user?.profile as VendorProfile?;
    final documents = profile?.documents;
    final missing = <String>[
      if (!(documents?.businessRegistrationCertificate.uploaded ?? false))
        'Business Registration Certificate',
      if (!(documents?.foodSafetyLicense.uploaded ?? false))
        'Food Safety / Hygiene Permit',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload: ${missing.join(', ')}')),
      );
      return;
    }

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
          _buildStepNode(0, 'Store Details', w),
          _buildStepConnector(0, w),
          _buildStepNode(1, 'Documents', w),
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

  Future<void> _pickTime(String currentTime, ValueChanged<String> onPicked) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPicked('$h:$m');
    }
  }

  Widget _buildStep1(double w) {
    final user = context.watch<CurrentUserProvider>().user;
    final profile = user?.profile as VendorProfile?;
    final vm = context.watch<VendorKycViewModel>();
    final kycState = vm.state;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
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

            // Operating Hours
            Text(
              'Operating Hours',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Opens',
                    time: kycState.openingTime,
                    onTap: () => _pickTime(kycState.openingTime, vm.setOpeningTime),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: _TimePickerTile(
                    label: 'Closes',
                    time: kycState.closingTime,
                    onTap: () => _pickTime(kycState.closingTime, vm.setClosingTime),
                  ),
                ),
              ],
            ),
            SizedBox(height: w * 0.05),

            // Estimated Prep Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Prep Time',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${kycState.estimatedPrepTimeMinutes} min',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: kycState.estimatedPrepTimeMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                onChanged: (val) => vm.setEstimatedPrepTimeMinutes(val.round()),
              ),
            ),
            SizedBox(height: w * 0.03),

            // Operating Days
            Text(
              'Operating Days',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Wrap(
              spacing: w * 0.02,
              runSpacing: w * 0.02,
              children: kAllOperatingDays.map((day) {
                final isSelected = kycState.operatingDays.contains(day);
                return GestureDetector(
                  onTap: () => vm.toggleOperatingDay(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.018),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(w * 0.02),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      day.substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontSize: w * 0.03,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
    final profile =
        context.watch<CurrentUserProvider>().user?.profile as VendorProfile?;
    final businessCertUploaded =
        profile?.documents.businessRegistrationCertificate.uploaded ?? false;
    final foodSafetyUploaded = profile?.documents.foodSafetyLicense.uploaded ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.all(w * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Documents',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Mukta',
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Upload your business permits to speed up verification. Scanned copies or high-quality photos are accepted. Both documents below are required.',
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
            subtitle: 'Company incorporation document',
            path: state.businessCertPath,
            isRequired: true,
            isUploaded: businessCertUploaded,
            onTap: () => _pickConfirmAndUpload(
              context,
              label: 'Business Registration Certificate',
              setLocalPath: vm.setBusinessCertPath,
              upload: (path) => vm.uploadDocument(
                type: 'business_registration_certificate',
                filePath: path,
                label: 'Business Registration Certificate',
              ),
            ),
            onRemove: () => vm.setBusinessCertPath(null),
            w: w,
          ),
          SizedBox(height: w * 0.04),

          // Food Vending permit
          _buildUploadItem(
            title: 'Food Safety / Hygiene Permit',
            subtitle: 'Municipal hygiene or vending license',
            path: state.foodSafetyLicensePath,
            isRequired: true,
            isUploaded: foodSafetyUploaded,
            onTap: () => _pickConfirmAndUpload(
              context,
              label: 'Food Safety / Hygiene Permit',
              setLocalPath: vm.setFoodSafetyLicensePath,
              upload: (path) => vm.uploadDocument(
                type: 'food_safety_license',
                filePath: path,
                label: 'Food Safety / Hygiene Permit',
              ),
            ),
            onRemove: () => vm.setFoodSafetyLicensePath(null),
            w: w,
          ),
        ],
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
    bool isUploaded = false,
    required double w,
  }) {
    final hasFile = path != null && path.isNotEmpty;
    final borderColor = isUploaded
        ? AppColors.success
        : (hasFile ? AppColors.error : AppColors.border);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: borderColor),
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
                          if (isRequired && !isUploaded) ...[
                            const SizedBox(width: 4),
                            const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ],
                          if (isUploaded) ...[
                            SizedBox(width: w * 0.015),
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: w * 0.042),
                          ],
                        ],
                      ),
                      SizedBox(height: w * 0.005),
                      Text(
                        isUploaded
                            ? 'Submitted for verification'
                            : (hasFile ? 'Upload failed — tap the photo to try again' : subtitle),
                        style: TextStyle(
                          fontSize: w * 0.028,
                          color: hasFile && !isUploaded
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFile && !isUploaded)
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
              child: GestureDetector(
                onTap: onTap,
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
                if (_currentStep < 1) {
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
                _currentStep == 1 ? 'Submit Application' : 'Continue',
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.03),
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: AppColors.primary, size: w * 0.05),
            SizedBox(width: w * 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: w * 0.028, color: AppColors.textSecondary),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
