import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // Reset OTP state and start countdown
      ref.read(otpVerificationProvider.notifier).reset();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, anim, _) => OtpVerificationScreen(
            paymentMethodId: newState.pendingMethodId!,
            maskedContact: newState.phoneNumber,
            onSuccess: () {
              // Pop OTP screen + this screen, notify list
              ref
                  .read(paymentMethodsProvider.notifier)
                  .load(); // refresh list
              Navigator.of(context)
                ..pop() // pop OTP
                ..pop(); // pop this screen
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

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Add Mobile Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
            padding:
                EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 24),
            children: [
              // Provider selector
              MobileMoneyProviderSelector(
                selected: state.provider,
                onSelect: (p) {
                  ref.read(addMobileMoneyProvider.notifier).setProvider(p);
                },
              ),

              // Provider error
              if (_showErrors && state.provider == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Please select a provider',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 28),

              // Phone number
              _SectionLabel(label: 'Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-]')),
                ],
                onChanged: (v) =>
                    ref.read(addMobileMoneyProvider.notifier).setPhone(v),
                decoration: InputDecoration(
                  hintText: '+233 54 123 4567',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  errorText: _showErrors ? state.phoneError : null,
                ),
              ),

              const SizedBox(height: 20),

              // Account name
              _SectionLabel(label: 'Account Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) =>
                    ref.read(addMobileMoneyProvider.notifier).setAccountName(v),
                decoration: InputDecoration(
                  hintText: 'Full name on account',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  errorText: _showErrors ? state.accountNameError : null,
                ),
              ),

              const SizedBox(height: 12),

              // Info card
              _InfoCard(
                icon: Icons.info_outline_rounded,
                message:
                    'An OTP will be sent to verify this mobile money account before it can be used for payouts.',
              ),

              const SizedBox(height: 36),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _InfoCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
