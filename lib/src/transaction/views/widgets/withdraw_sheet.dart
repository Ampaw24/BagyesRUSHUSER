import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/widgets/inline_message.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_wallet_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/withdraw_eligibility.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_viewmodel.dart';

/// The most the backend accepts in one withdrawal (`max:1000000`).
const maxWithdrawalAmount = 1000000.0;

/// The least it accepts (`min:1`) — the wallet's own minimum can be higher.
const _backendMinimumAmount = 1.0;

/// Bottom sheet for requesting a wallet withdrawal — `POST
/// /customer/withdrawals` takes only the amount; the server sends it to the
/// payout details on the customer's account (set via the add-payout flow).
///
/// Pops `true` once the request is accepted so the caller can refresh the
/// balance and the withdrawals list.
class WithdrawSheet extends StatefulWidget {
  const WithdrawSheet({super.key, required this.wallet, this.onAddPayoutMethod});

  final CustomerWalletModel wallet;

  /// Offered when the account has no payout details: the sheet closes and
  /// this opens the add flow. Leave null to show the notice without a button.
  final VoidCallback? onAddPayoutMethod;

  static Future<bool?> show(
    BuildContext context, {
    required CustomerWalletModel wallet,
    VoidCallback? onAddPayoutMethod,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawSheet(
        wallet: wallet,
        onAddPayoutMethod: onAddPayoutMethod,
      ),
    );
  }

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final _amountController = TextEditingController();
  bool _submitted = false;
  String? _serverError;

  CustomerWalletModel get _wallet => widget.wallet;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Stops a request the API would refuse outright (`amount` numeric,
  /// min:1, max:1000000). Everything else — the wallet's own minimum, how
  /// much is withdrawable — is left to the server, which words its own
  /// refusal; see [_amountHint] for the heads-up shown meanwhile.
  String? get _amountError {
    final text = _amountController.text.trim();
    if (text.isEmpty) return _submitted ? 'Enter an amount' : null;
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    if (amount < _backendMinimumAmount) {
      return 'Minimum withdrawal is ${formatMoney(_backendMinimumAmount, currency: _wallet.currency)}';
    }
    if (amount > maxWithdrawalAmount) {
      return 'Maximum withdrawal is ${formatMoney(maxWithdrawalAmount, currency: _wallet.currency)}';
    }
    return null;
  }

  /// A non-blocking heads-up when the amount is outside what the wallet says
  /// is withdrawable — the request can still be sent and the server decides.
  String? get _amountHint {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || _amountError != null) return null;
    if (amount > _wallet.withdrawable) {
      return 'That\'s more than your withdrawable balance '
          '(${_wallet.formattedWithdrawable}) — it may be declined.';
    }
    if (amount < _wallet.minimumWithdrawal) {
      return 'Below the minimum of '
          '${formatMoney(_wallet.minimumWithdrawal, currency: _wallet.currency)} — it may be declined.';
    }
    return null;
  }

  void _applyFraction(double fraction) {
    _amountController.text = (_wallet.withdrawable * fraction).toStringAsFixed(2);
    setState(() => _serverError = null);
  }

  void _addPayoutMethod() {
    Navigator.of(context).pop();
    widget.onAddPayoutMethod?.call();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_amountController.text.trim().isEmpty || _amountError != null) return;

    final vm = context.read<CustomerWithdrawalsViewModel>();
    final error = await vm.request(double.parse(_amountController.text.trim()));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _serverError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = context.watch<CustomerWithdrawalsViewModel>().state;
    final amountError = _amountError;
    final amountHint = _amountHint;
    final notice = _wallet.withdrawBlock;
    final canSubmit = !state.isRequesting;
    final amount = double.tryParse(_amountController.text.trim());

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
                'Withdraw funds',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.01),
              Text(
                'Available to withdraw: ${_wallet.formattedWithdrawable}',
                style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
              ),
              if (notice != null) ...[
                SizedBox(height: w * 0.03),
                InlineMessage(
                  message: _wallet.blockMessage(notice),
                  kind: InlineMessageKind.notice,
                ),
                if (notice == WithdrawBlock.noPayoutDetails &&
                    widget.onAddPayoutMethod != null) ...[
                  SizedBox(height: w * 0.025),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addPayoutMethod,
                      icon: Icon(Icons.add_card_rounded, size: w * 0.05),
                      label: const Text('Add payout method'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        padding: EdgeInsets.symmetric(vertical: w * 0.032),
                        textStyle: TextStyle(fontSize: w * 0.036, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w * 0.035),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              SizedBox(height: w * 0.05),

              _FieldLabel('Amount', w: w),
              SizedBox(height: w * 0.02),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onChanged: (_) => setState(() => _serverError = null),
                style: TextStyle(fontSize: w * 0.045, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: '${_wallet.currency} ',
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
                  for (final fraction in [0.25, 0.5, 1.0])
                    Padding(
                      padding: EdgeInsets.only(right: w * 0.02),
                      child: _PercentChip(
                        label: fraction == 1.0 ? 'Max' : '${(fraction * 100).round()}%',
                        onTap: _wallet.withdrawable > 0 ? () => _applyFraction(fraction) : null,
                        w: w,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'Min ${formatMoney(_wallet.minimumWithdrawal, currency: _wallet.currency)}',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: w * 0.029, color: AppColors.textHint),
                    ),
                  ),
                ],
              ),
              if (amountError != null) ...[
                SizedBox(height: w * 0.02),
                Text(
                  amountError,
                  style: TextStyle(fontSize: w * 0.032, color: AppColors.error),
                ),
              ] else if (amountHint != null) ...[
                SizedBox(height: w * 0.02),
                Text(
                  amountHint,
                  style: TextStyle(fontSize: w * 0.032, color: AppColors.warning),
                ),
              ],
              SizedBox(height: w * 0.05),

              if (_serverError != null) ...[
                SizedBox(height: w * 0.03),
                InlineMessage(message: _serverError!),
              ],

              SizedBox(height: w * 0.06),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: w * 0.035),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: state.isRequesting
                      ? SizedBox(
                          width: w * 0.05,
                          height: w * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          amount != null && amount > 0 && _amountError == null
                              ? 'Withdraw ${formatMoney(amount, currency: _wallet.currency)}'
                              : 'Withdraw',
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
