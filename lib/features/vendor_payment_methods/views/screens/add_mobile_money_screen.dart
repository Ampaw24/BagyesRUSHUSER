import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';
import '../../providers/payment_providers.dart';
import '../../viewmodels/add_payment_method_viewmodel.dart';
import '../widgets/mobile_money_provider_selector.dart';
import 'otp_verification_screen.dart';

class AddMobileMoneyScreen extends ConsumerStatefulWidget {
  const AddMobileMoneyScreen({super.key});

  @override
  ConsumerState<AddMobileMoneyScreen> createState() =>
      _AddMobileMoneyScreenState();
}

class _AddMobileMoneyScreenState extends ConsumerState<AddMobileMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showErrors = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    final state = ref.read(addMobileMoneyProvider);
    if (!state.isValid) return;

    await ref.read(addMobileMoneyProvider.notifier).submit();

    final newState = ref.read(addMobileMoneyProvider);
    if (!mounted) return;

    if (newState.status == AddPaymentMethodStatus.success &&
        newState.pendingMethodId != null) {
      ref.read(otpVerificationProvider.notifier).reset();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, anim, _) => OtpVerificationScreen(
            paymentMethodId: newState.pendingMethodId!,
            maskedContact: newState.phoneNumber,
            onSuccess: () {
              ref.read(paymentMethodsProvider.notifier).load();
              Navigator.of(context)
                ..pop()
                ..pop();
            },
          ),
          transitionsBuilder: (_, anim, _, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 340),
        ),
      );
    } else if (newState.status == AddPaymentMethodStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState.errorMessage ?? 'Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMobileMoneyProvider);
    final isLoading = state.status == AddPaymentMethodStatus.loading;
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(
          'Add Mobile Money',
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
          onPressed: () {
            ref.read(addMobileMoneyProvider.notifier).reset();
            Navigator.of(context).pop();
          },
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
              // ── Provider selector ─────────────────────────────────────────
              MobileMoneyProviderSelector(
                selected: state.provider,
                onSelect: (p) =>
                    ref.read(addMobileMoneyProvider.notifier).setProvider(p),
              ),

              if (_showErrors && state.provider == null)
                Padding(
                  padding: EdgeInsets.only(top: h * 0.008),
                  child: Text(
                    'Please select a provider',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: w * 0.032,
                    ),
                  ),
                ),

              SizedBox(height: h * 0.035),

              // ── Phone number ──────────────────────────────────────────────
              _SectionLabel(label: 'Phone Number', w: w),
              SizedBox(height: h * 0.01),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-]')),
                ],
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: AppColors.textPrimary,
                ),
                onChanged: (v) =>
                    ref.read(addMobileMoneyProvider.notifier).setPhone(v),
                decoration: InputDecoration(
                  hintText: '+233 54 123 4567',
                  hintStyle: TextStyle(
                    fontSize: w * 0.038,
                    color: AppColors.textHint,
                  ),
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
                  errorText: _showErrors ? state.phoneError : null,
                  errorStyle: TextStyle(fontSize: w * 0.03),
                ),
              ),

              SizedBox(height: h * 0.025),

              // ── Account name ──────────────────────────────────────────────
              _SectionLabel(label: 'Account Name', w: w),
              SizedBox(height: h * 0.01),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: AppColors.textPrimary,
                ),
                onChanged: (v) =>
                    ref.read(addMobileMoneyProvider.notifier).setAccountName(v),
                decoration: InputDecoration(
                  hintText: 'Full name on account',
                  hintStyle: TextStyle(
                    fontSize: w * 0.038,
                    color: AppColors.textHint,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: h * 0.018,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(w * 0.03),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: AppColors.textSecondary,
                      size: w * 0.05,
                    ),
                  ),
                  errorText: _showErrors ? state.accountNameError : null,
                  errorStyle: TextStyle(fontSize: w * 0.03),
                ),
              ),

              SizedBox(height: h * 0.018),

              // ── Info card ─────────────────────────────────────────────────
              _InfoCard(w: w, h: h),

              SizedBox(height: h * 0.045),

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                    textStyle: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: w * 0.05,
                          height: w * 0.05,
                          child: CircularProgressIndicator(
                            strokeWidth: w * 0.005,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
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

// ── Section label ─────────────────────────────────────────────────────────────

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

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final double w;
  final double h;

  const _InfoCard({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: primary,
            size: w * 0.045,
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'An OTP will be sent to verify this mobile money account before it can be used for payouts.',
              style: TextStyle(
                fontSize: w * 0.033,
                color: primary,
                height: w * 0.004,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
