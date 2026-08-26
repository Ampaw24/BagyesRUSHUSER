import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../constant/app_theme.dart';
import '../../../../src/payment/model/payout_provider_model.dart';
import '../../../../src/payment/viewmodel/payment_viewmodel.dart';
import '../../../../src/payment/viewmodel/payout_providers_viewmodel.dart';
import '../../../../src/payment/views/widgets/payout_provider_dropdown.dart';

/// Validates a Ghanaian phone in local (0XXXXXXXXX) or E.164 (+233XXXXXXXXX).
bool _isValidGhanaPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
  if (RegExp(r'^0[0-9]{9}$').hasMatch(digits)) return true;
  if (RegExp(r'^233[0-9]{9}$').hasMatch(digits)) return true;
  return false;
}

/// Screen for adding a new mobile money payout method.
class AddMobileMoneyScreen extends StatefulWidget {
  const AddMobileMoneyScreen({super.key});

  @override
  State<AddMobileMoneyScreen> createState() => _AddMobileMoneyScreenState();
}

class _AddMobileMoneyScreenState extends State<AddMobileMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  PayoutProviderModel? _provider;
  bool _isSubmitting = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PayoutProvidersViewModel>().load(),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  String? get _phoneError {
    if (_phoneCtrl.text.isEmpty) return null;
    if (!_isValidGhanaPhone(_phoneCtrl.text)) {
      return 'Enter a valid Ghanaian phone number';
    }
    return null;
  }

  bool get _isValid =>
      _provider != null &&
      _isValidGhanaPhone(_phoneCtrl.text) &&
      _phoneError == null;

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    if (!_isValid) return;

    setState(() => _isSubmitting = true);
    final method = await context.read<PaymentViewModel>().addPaymentMethod(
          payoutProviderId: _provider!.id,
          phoneNumber: _phoneCtrl.text.trim(),
          label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (method != null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add payment method')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final providersVm = context.watch<PayoutProvidersViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(
          'Add Payment Method',
          style: TextStyle(
            fontSize: w * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
            size: w * 0.055,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.06,
              vertical: h * 0.025,
            ),
            children: [
              PayoutProviderDropdown(
                label: 'Mobile Money Provider',
                placeholder: 'Select provider',
                providers: providersVm.mobileMoneyProviders,
                selected: _provider,
                isLoading: providersVm.isLoading,
                error: providersVm.error,
                onRetry: () => providersVm.load(force: true),
                onSelected: (p) => setState(() => _provider = p),
              ),
              if (_showErrors && _provider == null)
                Padding(
                  padding: EdgeInsets.only(top: h * 0.008),
                  child: Text(
                    'Please select a provider',
                    style: TextStyle(color: AppColors.error, fontSize: w * 0.032),
                  ),
                ),

              SizedBox(height: h * 0.035),

              _SectionLabel(label: 'Phone Number', w: w),
              SizedBox(height: h * 0.01),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-]')),
                ],
                style: TextStyle(fontSize: w * 0.04, color: AppColors.textPrimary),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '+233 54 123 4567',
                  hintStyle: TextStyle(fontSize: w * 0.038, color: AppColors.textHint),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: h * 0.018,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(w * 0.03),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCall,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
                  errorText: _showErrors ? _phoneError : null,
                  errorStyle: TextStyle(fontSize: w * 0.03),
                ),
              ),

              SizedBox(height: h * 0.025),

              _SectionLabel(label: 'Label (optional)', w: w),
              SizedBox(height: h * 0.01),
              TextFormField(
                controller: _labelCtrl,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                style: TextStyle(fontSize: w * 0.04, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. My personal MoMo',
                  hintStyle: TextStyle(fontSize: w * 0.038, color: AppColors.textHint),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: h * 0.018,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(w * 0.03),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTag01,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
                  counterText: '',
                ),
              ),

              SizedBox(height: h * 0.045),

              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                    textStyle: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: w * 0.05,
                          height: w * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Payment Method'),
                ),
              ),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final double w;

  const _SectionLabel({required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: w * 0.035,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: w * 0.001,
      ),
    );
  }
}
