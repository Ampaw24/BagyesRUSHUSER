import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/vendor_profile.dart';

const _kMobileMoneyProviders = {
  'mtn': 'MTN Mobile Money',
  'vodafone': 'Vodafone Cash',
  'airteltigo': 'AirtelTigo Money',
};

/// Bottom sheet for setting bank and/or mobile-money payout details.
/// Submits only the changed fields to `PUT /vendor/me/payout` — account
/// numbers are never round-tripped from the server (only a masked last-4 is
/// shown), so fields start blank rather than pre-filled with real values.
class PayoutSettingsSheet extends StatefulWidget {
  final VendorPayoutInfo payout;
  final ValueChanged<Map<String, dynamic>> onSave;

  const PayoutSettingsSheet({
    super.key,
    required this.payout,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required VendorPayoutInfo payout,
    required ValueChanged<Map<String, dynamic>> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayoutSettingsSheet(payout: payout, onSave: onSave),
    );
  }

  @override
  State<PayoutSettingsSheet> createState() => _PayoutSettingsSheetState();
}

class _PayoutSettingsSheetState extends State<PayoutSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _branchCodeCtrl;
  late final TextEditingController _momoNumberCtrl;
  String? _momoProvider;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController(text: widget.payout.bankName ?? '');
    _accountNumberCtrl = TextEditingController();
    _accountNameCtrl =
        TextEditingController(text: widget.payout.accountName ?? '');
    _branchCodeCtrl = TextEditingController();
    _momoNumberCtrl = TextEditingController();
    _momoProvider = widget.payout.mobileMoneyProvider;
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    _branchCodeCtrl.dispose();
    _momoNumberCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final bankName = _bankNameCtrl.text.trim();
    final accountNumber = _accountNumberCtrl.text.trim();
    final accountName = _accountNameCtrl.text.trim();
    final momoNumber = _momoNumberCtrl.text.trim();

    final hasAnyBankField =
        bankName.isNotEmpty || accountNumber.isNotEmpty || accountName.isNotEmpty;
    if (hasAnyBankField &&
        (bankName.isEmpty || accountNumber.isEmpty || accountName.isEmpty)) {
      setState(() => _formError =
          'Bank name, account number, and account name are all required together');
      return;
    }
    if (momoNumber.isNotEmpty && _momoProvider == null) {
      setState(() => _formError = 'Select a mobile money provider');
      return;
    }
    if (_momoProvider != null && momoNumber.isEmpty) {
      setState(() => _formError = 'Enter a mobile money number');
      return;
    }
    setState(() => _formError = null);

    final data = <String, dynamic>{
      if (bankName.isNotEmpty) 'bank_name': bankName,
      if (accountNumber.isNotEmpty) 'account_number': accountNumber,
      if (accountName.isNotEmpty) 'account_name': accountName,
      if (_branchCodeCtrl.text.trim().isNotEmpty)
        'branch_code': _branchCodeCtrl.text.trim(),
      if (momoNumber.isNotEmpty) 'mobile_money_number': momoNumber,
      if (_momoProvider != null) 'mobile_money_provider': _momoProvider,
    };

    if (data.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: w * 0.035),
            child: Container(
              width: w * 0.1,
              height: w * 0.01,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(w * 0.005),
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.01),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet01,
                  color: AppColors.primary,
                  size: w * 0.055,
                ),
                SizedBox(width: w * 0.02),
                Text(
                  'Payout Settings',
                  style: TextStyle(
                    fontSize: w * 0.05,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: w * 0.045,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.02,
                w * 0.05,
                bottomInset + w * 0.04,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PayoutSectionHeader(
                      icon: HugeIcons.strokeRoundedCreditCard,
                      title: 'Bank Account',
                      w: w,
                    ),
                    SizedBox(height: w * 0.03),
                    TextFormField(
                      controller: _bankNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        hintText: 'e.g. GCB Bank',
                      ),
                      style: TextStyle(fontSize: w * 0.038),
                    ),
                    SizedBox(height: w * 0.03),
                    TextFormField(
                      controller: _accountNumberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Account Number',
                        hintText: widget.payout.accountNumberLast4 != null
                            ? 'Ending in ${widget.payout.accountNumberLast4}'
                            : 'Enter account number',
                      ),
                      style: TextStyle(fontSize: w * 0.038),
                    ),
                    SizedBox(height: w * 0.03),
                    TextFormField(
                      controller: _accountNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                      style: TextStyle(fontSize: w * 0.038),
                    ),
                    SizedBox(height: w * 0.03),
                    TextFormField(
                      controller: _branchCodeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Branch Code (optional)',
                        hintText: widget.payout.branchCodeLast4 != null
                            ? 'Ending in ${widget.payout.branchCodeLast4}'
                            : null,
                      ),
                      style: TextStyle(fontSize: w * 0.038),
                    ),
                    SizedBox(height: w * 0.06),

                    _PayoutSectionHeader(
                      icon: HugeIcons.strokeRoundedSmartPhone01,
                      title: 'Mobile Money',
                      w: w,
                    ),
                    SizedBox(height: w * 0.03),
                    DropdownButtonFormField<String>(
                      initialValue: _momoProvider,
                      decoration: const InputDecoration(labelText: 'Provider'),
                      items: _kMobileMoneyProviders.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _momoProvider = v),
                    ),
                    SizedBox(height: w * 0.03),
                    TextFormField(
                      controller: _momoNumberCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Money Number',
                        hintText: widget.payout.mobileMoneyNumberLast4 != null
                            ? 'Ending in ${widget.payout.mobileMoneyNumberLast4}'
                            : '024XXXXXXX',
                      ),
                      style: TextStyle(fontSize: w * 0.038),
                    ),

                    if (_formError != null) ...[
                      SizedBox(height: w * 0.04),
                      Text(
                        _formError!,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: w * 0.06),

                    SizedBox(
                      width: double.infinity,
                      height: w * 0.135,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(
                          'Save Payout Details',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}

class _PayoutSectionHeader extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final double w;

  const _PayoutSectionHeader({
    required this.icon,
    required this.title,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.045),
        SizedBox(width: w * 0.02),
        Text(
          title,
          style: TextStyle(
            fontSize: w * 0.036,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
