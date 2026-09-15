import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/widgets/app_toast.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_channel.dart';
import 'package:bagyesrushappusernew/src/payment/models/payment_wallet.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodels/payment_state.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodels/payment_viewmodel.dart';

/// Bottom sheet collecting the mobile-money destination for a wallet
/// withdrawal — `POST /payments/wallet/withdraw` takes the destination
/// inline per-request rather than a preset payout method, so this is a
/// self-contained form (amount, network, phone, account name).
///
/// Owns a screen-scoped [PaymentViewmodel] instance of its own (fetched via
/// `sl()`, not the shared app-root one) so an in-flight withdraw never
/// flickers the transaction screen's wallet card, which reads the shared
/// instance. Returns `true` via [Navigator.pop] on a confirmed withdrawal so
/// the caller knows to refresh the balance.
class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({super.key, required this.wallet});

  final PaymentWallet wallet;

  static Future<bool?> show(BuildContext context, {required PaymentWallet wallet}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(wallet: wallet),
    );
  }

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  late final PaymentViewmodel _vm;
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNameController = TextEditingController();
  MobileMoneyProvider? _provider;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _vm = sl<PaymentViewmodel>();
    _vm.addListener(_onVmChanged);

    final user = sl<CurrentUserProvider>().user;
    _phoneController.text = user?.phone ?? '';
    final profile = user?.profile;
    if (profile is CustomerProfile) {
      _accountNameController.text = '${profile.firstName} ${profile.lastName}'.trim();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    final state = _vm.state;
    if (state is PaymentWithdrawSuccess) {
      AppToast.show(
        context,
        isSuccess: true,
        title: 'Withdrawal requested',
        subtitle: 'Your funds are on the way to your mobile money wallet.',
      );
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {});
  }

  String? get _validationError {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    if (amount > widget.wallet.balance) return 'Amount exceeds your available balance';
    if (_provider == null) return 'Select a mobile money network';
    if (_phoneController.text.trim().isEmpty) return 'Enter a phone number';
    if (_accountNameController.text.trim().isEmpty) return 'Enter the account name';
    return null;
  }

  void _applyPercentage(double fraction) {
    final amount = widget.wallet.balance * fraction;
    _amountController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  void _submit() {
    final error = _validationError;
    setState(() => _submitted = true);
    if (error != null) return;

    _vm.withdrawFromWallet(
      amount: double.parse(_amountController.text.trim()),
      mobileMoneyProvider: _provider!,
      phone: _phoneController.text.trim(),
      accountName: _accountNameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isLoading = _vm.state is PaymentLoading;
    final error = _vm.state is PaymentError ? (_vm.state as PaymentError).message : null;
    final showValidation = _submitted ? _validationError : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: w * 0.1,
                  height: w * 0.01,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(w * 0.01),
                  ),
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                'Withdraw to mobile money',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.01),
              Text(
                'Available balance: ${widget.wallet.formattedBalance}',
                style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
              ),
              SizedBox(height: w * 0.05),

              _FieldLabel('Amount', w: w),
              SizedBox(height: w * 0.02),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: '${widget.wallet.currency} ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
                ),
              ),
              SizedBox(height: w * 0.025),
              Row(
                children: [
                  for (final pct in [0.25, 0.5, 1.0])
                    Padding(
                      padding: EdgeInsets.only(right: w * 0.02),
                      child: _PercentChip(
                        label: pct == 1.0 ? 'Max' : '${(pct * 100).round()}%',
                        onTap: widget.wallet.balance > 0 ? () => _applyPercentage(pct) : null,
                        w: w,
                      ),
                    ),
                ],
              ),
              SizedBox(height: w * 0.05),

              _FieldLabel('Mobile money network', w: w),
              SizedBox(height: w * 0.02),
              Wrap(
                spacing: w * 0.025,
                runSpacing: w * 0.025,
                children: MobileMoneyProvider.values.map((provider) {
                  final selected = _provider == provider;
                  return GestureDetector(
                    onTap: () => setState(() => _provider = provider),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(w * 0.06),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _providerLabel(provider),
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: w * 0.05),

              _FieldLabel('Mobile money number', w: w),
              SizedBox(height: w * 0.02),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'e.g. 024XXXXXXX',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
                ),
              ),
              SizedBox(height: w * 0.05),

              _FieldLabel('Account name', w: w),
              SizedBox(height: w * 0.02),
              TextField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Name on the mobile money account',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
                ),
              ),

              if (showValidation != null || error != null) ...[
                SizedBox(height: w * 0.03),
                Text(
                  error ?? showValidation!,
                  style: TextStyle(fontSize: w * 0.032, color: AppColors.error),
                ),
              ],

              SizedBox(height: w * 0.06),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: w * 0.035),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: w * 0.05,
                          height: w * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Withdraw',
                          style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _providerLabel(MobileMoneyProvider provider) => switch (provider) {
        MobileMoneyProvider.mtn => 'MTN MoMo',
        MobileMoneyProvider.vodafone => 'Vodafone Cash',
        MobileMoneyProvider.airtelTigo => 'AirtelTigo Money',
      };
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.w});
  final String label;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: w * 0.033,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PercentChip extends StatelessWidget {
  const _PercentChip({required this.label, required this.onTap, required this.w});
  final String label;
  final VoidCallback? onTap;
  final double w;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.016),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.03,
            fontWeight: FontWeight.w600,
            color: onTap != null ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
