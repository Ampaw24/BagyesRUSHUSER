import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import '../viewmodels/vendor_wallet_state.dart';
import '../viewmodels/vendor_wallet_viewmodel.dart';
import 'vendor_withdrawal_success_view.dart';

/// Single-step withdrawal — `POST /vendor/me/withdrawals` only takes an
/// amount; the payout destination is configured separately via
/// `VendorPayoutView` (`PUT /vendor/me/payout`), so there's no
/// method-selection step here.
class VendorWithdrawView extends StatefulWidget {
  const VendorWithdrawView({super.key});

  @override
  State<VendorWithdrawView> createState() => _VendorWithdrawViewState();
}

class _VendorWithdrawViewState extends State<VendorWithdrawView> {
  static const double _minAmount = 1;
  static const double _maxAmount = 1000000;

  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _showError = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final vm = context.read<VendorWalletViewmodel>();
    if (vm.wallet == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.fetchWallet());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text) ?? 0;

  String? _amountError(double balance) {
    if (!_showError) return null;
    if (_amount <= 0) return 'Enter an amount';
    if (_amount < _minAmount) return 'Minimum withdrawal is ${_minAmount.toStringAsFixed(2)}';
    if (_amount > _maxAmount) return 'Maximum withdrawal is ${_maxAmount.toStringAsFixed(0)}';
    if (_amount > balance) return 'Amount exceeds available balance';
    return null;
  }

  bool _isValid(double balance) => _amount > 0 && _amountError(balance) == null;

  Future<void> _submit(VendorWalletViewmodel vm, double balance) async {
    setState(() => _showError = true);
    if (!_isValid(balance)) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final success = await vm.requestWithdrawal(amount: _amount);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success && vm.state is VendorWithdrawalRequested) {
      final withdrawal = (vm.state as VendorWithdrawalRequested).withdrawal;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VendorWithdrawalSuccessView(withdrawal: withdrawal),
        ),
      );
    } else {
      setState(() {
        _submitError = vm.state is VendorWalletError
            ? (vm.state as VendorWalletError).message
            : 'Withdrawal failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final vm = context.watch<VendorWalletViewmodel>();
    final balance = vm.wallet?.balance ?? 0;
    final currency = vm.wallet?.currency ?? 'GHS';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Withdraw')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$currency ${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: w * 0.07),
            TextField(
              controller: _amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.09,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: w * 0.09,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textHint,
                ),
                prefix: Padding(
                  padding: EdgeInsets.only(right: w * 0.01),
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontSize: w * 0.05,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                errorText: _amountError(balance),
                errorMaxLines: 2,
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: w * 0.04),
            _QuickAmountRow(
              balance: balance,
              onSelect: (v) {
                _amountCtrl.text = v.toStringAsFixed(2);
                setState(() {});
              },
            ),
            SizedBox(height: w * 0.08),
            GestureDetector(
              onTap: () => context.push(AppRoutes.vendorPayout),
              child: Container(
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.035),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: w * 0.05,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: Text(
                        'Paid out to your saved payout method',
                        style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
                      ),
                    ),
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_submitError != null) ...[
              SizedBox(height: w * 0.04),
              Text(
                _submitError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: w * 0.032, color: AppColors.error),
              ),
            ],
            SizedBox(height: w * 0.08),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(vm, balance),
                child: _isSubmitting
                    ? SizedBox(
                        width: w * 0.05,
                        height: w * 0.05,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountRow extends StatelessWidget {
  const _QuickAmountRow({required this.balance, required this.onSelect});

  final double balance;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    final presets = [25.0, 50.0, 100.0, 250.0].where((v) => v <= balance).toList();
    final showMax = balance > 0 && !presets.contains(balance);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final v in presets) _Chip(label: v.toStringAsFixed(0), onTap: () => onSelect(v)),
        if (showMax) _Chip(label: 'Max', onTap: () => onSelect(balance)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.018),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.05),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
