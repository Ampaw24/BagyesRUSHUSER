import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../models/visa_card_model.dart';
import '../../providers/payment_providers.dart';
import '../../utils/card_utils.dart';
import '../../viewmodels/add_payment_method_viewmodel.dart';
import '../widgets/credit_card_preview.dart';
import 'otp_verification_screen.dart';

class AddVisaCardScreen extends ConsumerStatefulWidget {
  const AddVisaCardScreen({super.key});

  @override
  ConsumerState<AddVisaCardScreen> createState() => _AddVisaCardScreenState();
}

class _AddVisaCardScreenState extends ConsumerState<AddVisaCardScreen> {
  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _cardNumberFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();

  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _cvvFocus.addListener(() {
      ref.read(addVisaCardProvider.notifier).setFlipped(_cvvFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardNumberFocus.dispose();
    _nameFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _showErrors = true);
    final state = ref.read(addVisaCardProvider);
    if (!state.isValid) return;

    await ref.read(addVisaCardProvider.notifier).submit();

    final newState = ref.read(addVisaCardProvider);
    if (!mounted) return;

    if (newState.status == AddPaymentMethodStatus.success &&
        newState.pendingMethodId != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, anim, _) => OtpVerificationScreen(
            paymentMethodId: newState.pendingMethodId!,
            maskedContact: 'your registered contact',
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
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 340),
        ),
      );
    } else if (newState.status == AddPaymentMethodStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.errorMessage ?? 'Something went wrong'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addVisaCardProvider);
    final isLoading = state.status == AddPaymentMethodStatus.loading;
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Add Card'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            ref.read(addVisaCardProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: 40),
          children: [
            // ── Live card preview ─────────────────────────────────────────
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: CreditCardPreview(
                cardNumber: state.cardNumber,
                cardholderName: state.cardholderName,
                expiry: state.expiry,
                cvv: state.cvv,
                brand: state.detectedBrand,
                isFlipped: state.isFlipped,
              ),
            ),

            // ── Form ──────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card number
                  _FieldLabel('Card Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cardNumberCtrl,
                    focusNode: _cardNumberFocus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CardNumberFormatter(),
                    ],
                    maxLength: 19, // 16 digits + 3 spaces
                    onChanged: (v) {
                      final raw = v.replaceAll(RegExp(r'\D'), '');
                      ref.read(addVisaCardProvider.notifier).setCardNumber(raw);
                    },
                    decoration: InputDecoration(
                      hintText: '0000 0000 0000 0000',
                      counterText: '',
                      prefixIcon: const Icon(
                        Icons.credit_card_rounded,
                        size: 20,
                      ),
                      suffixIcon: state.cardNumber.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _BrandBadge(brand: state.detectedBrand),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      errorText:
                          _showErrors ? state.cardNumberError : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cardholder name
                  _FieldLabel('Cardholder Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s]')),
                    ],
                    onChanged: (v) => ref
                        .read(addVisaCardProvider.notifier)
                        .setCardholderName(v.toUpperCase()),
                    decoration: InputDecoration(
                      hintText: 'NAME AS ON CARD',
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          size: 20),
                      errorText:
                          _showErrors ? state.cardholderError : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expiry + CVV side by side
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Expiry Date'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _expiryCtrl,
                              focusNode: _expiryFocus,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _ExpiryFormatter(),
                              ],
                              maxLength: 5,
                              onChanged: (v) => ref
                                  .read(addVisaCardProvider.notifier)
                                  .setExpiry(v),
                              decoration: InputDecoration(
                                hintText: 'MM/YY',
                                counterText: '',
                                prefixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18),
                                errorText:
                                    _showErrors ? state.expiryError : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('CVV'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cvvCtrl,
                              focusNode: _cvvFocus,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => ref
                                  .read(addVisaCardProvider.notifier)
                                  .setCvv(v),
                              decoration: InputDecoration(
                                hintText: '•••',
                                counterText: '',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    size: 18),
                                errorText:
                                    _showErrors ? state.cvvError : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Security note
                  _SecurityNote(),

                  const SizedBox(height: 32),

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
          ],
        ),
      ),
    );
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = CardUtils.formatCardNumber(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final formatted = CardUtils.formatExpiry(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

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

class _BrandBadge extends StatelessWidget {
  final CardBrand brand;
  const _BrandBadge({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        brand.displayName,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your card details are encrypted and never stored on our servers.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
