import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../constant/app_theme.dart';
import '../model/vendor_profile.dart';
import '../viewmodel/settings_viewmodel.dart';

const _kMobileMoneyProviders = {
  'mtn': 'MTN Mobile Money',
  'vodafone': 'Vodafone Cash',
  'airteltigo': 'AirtelTigo Money',
};

/// Full-screen payout configuration for `PUT /vendor/me/payout` — lets a
/// vendor set the bank and/or mobile-money details they get paid out to.
class VendorPayoutView extends StatefulWidget {
  const VendorPayoutView({super.key});

  @override
  State<VendorPayoutView> createState() => _VendorPayoutViewState();
}

class _VendorPayoutViewState extends State<VendorPayoutView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _accountNameCtrl;
  late final TextEditingController _branchCodeCtrl;
  late final TextEditingController _momoNumberCtrl;
  String? _momoProvider;
  String? _formError;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController();
    _accountNumberCtrl = TextEditingController();
    _accountNameCtrl = TextEditingController();
    _branchCodeCtrl = TextEditingController();
    _momoNumberCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final vm = context.read<SettingsViewModel>();
      final existing = vm.state.profile?.payout;
      if (existing != null) _prefill(existing);
      if (vm.state.profile == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => vm.loadProfile());
      }
    }
  }

  void _prefill(VendorPayoutInfo payout) {
    _bankNameCtrl.text = payout.bankName ?? '';
    _accountNameCtrl.text = payout.accountName ?? '';
    _momoProvider = payout.mobileMoneyProvider;
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

  Future<void> _save(SettingsViewModel vm) async {
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

    if (data.isEmpty) return;

    final success = await vm.updatePayout(data);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.success : AppColors.error,
        content: Text(
          success
              ? 'Payout details updated'
              : vm.state.errorMessage ?? 'Failed to update payout details',
        ),
      ),
    );
    if (!success) return;

    _bankNameCtrl.clear();
    _accountNumberCtrl.clear();
    _accountNameCtrl.clear();
    _branchCodeCtrl.clear();
    _momoNumberCtrl.clear();
    setState(() => _momoProvider = null);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Payout Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: w * 0.045,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mukta',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: w * 0.05),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          final saving = vm.state.status == SettingsStatus.saving;
          final payout = vm.state.profile?.payout ?? const VendorPayoutInfo();

          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.3),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PayoutStatusHero(w: w, payout: payout),
                        SizedBox(height: w * 0.06),
                        _SectionCard(
                          w: w,
                          icon: HugeIcons.strokeRoundedBank,
                          title: 'Bank Account',
                          children: [
                            _PayoutField(
                              w: w,
                              controller: _bankNameCtrl,
                              label: 'Bank Name',
                              hint: 'e.g. GCB Bank',
                              icon: HugeIcons.strokeRoundedBuilding05,
                            ),
                            SizedBox(height: w * 0.035),
                            _PayoutField(
                              w: w,
                              controller: _accountNumberCtrl,
                              label: 'Account Number',
                              hint: payout.accountNumberLast4 != null
                                  ? 'Ending in ${payout.accountNumberLast4}'
                                  : 'Enter account number',
                              icon: HugeIcons.strokeRoundedCreditCard,
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: w * 0.035),
                            _PayoutField(
                              w: w,
                              controller: _accountNameCtrl,
                              label: 'Account Name',
                              icon: HugeIcons.strokeRoundedUserAccount,
                            ),
                            SizedBox(height: w * 0.035),
                            _PayoutField(
                              w: w,
                              controller: _branchCodeCtrl,
                              label: 'Branch Code (optional)',
                              hint: payout.branchCodeLast4 != null
                                  ? 'Ending in ${payout.branchCodeLast4}'
                                  : null,
                              icon: HugeIcons.strokeRoundedLocation01,
                            ),
                          ],
                        ),
                        SizedBox(height: w * 0.05),
                        _SectionCard(
                          w: w,
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          title: 'Mobile Money',
                          children: [
                            Text(
                              'Provider',
                              style: TextStyle(
                                fontSize: w * 0.032,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: w * 0.018),
                            DropdownButtonFormField<String>(
                              initialValue: _momoProvider,
                              hint: Text(
                                'Select provider',
                                style: TextStyle(
                                  fontSize: w * 0.038,
                                  color: AppColors.textHint,
                                ),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(w * 0.032),
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedMoneyExchange01,
                                    color: AppColors.textSecondary,
                                    size: w * 0.045,
                                  ),
                                ),
                              ),
                              items: _kMobileMoneyProviders.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _momoProvider = v),
                            ),
                            SizedBox(height: w * 0.035),
                            _PayoutField(
                              w: w,
                              controller: _momoNumberCtrl,
                              label: 'Mobile Money Number',
                              hint: payout.mobileMoneyNumberLast4 != null
                                  ? 'Ending in ${payout.mobileMoneyNumberLast4}'
                                  : '024XXXXXXX',
                              icon: HugeIcons.strokeRoundedCall,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                        if (_formError != null) ...[
                          SizedBox(height: w * 0.04),
                          _ErrorBanner(w: w, message: _formError!),
                        ],
                        SizedBox(height: w * 0.05),
                        _InfoNote(w: w),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.035, w * 0.05, w * 0.035),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: w * 0.13,
                      child: ElevatedButton(
                        onPressed: saving ? null : () => _save(vm),
                        child: saving
                            ? SpinKitThreeBounce(color: Colors.white, size: w * 0.05)
                            : Text(
                                'Save Payout Details',
                                style: TextStyle(
                                  fontSize: w * 0.042,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PayoutStatusHero extends StatelessWidget {
  final double w;
  final VendorPayoutInfo payout;

  const _PayoutStatusHero({required this.w, required this.payout});

  @override
  Widget build(BuildContext context) {
    final configured = payout.isConfigured;
    final summary = configured
        ? [
            if (payout.bankName != null && payout.accountNumberLast4 != null)
              '${payout.bankName} •••• ${payout.accountNumberLast4}',
            if (payout.mobileMoneyProvider != null &&
                payout.mobileMoneyNumberLast4 != null)
              '${_kMobileMoneyProviders[payout.mobileMoneyProvider] ?? payout.mobileMoneyProvider} •••• ${payout.mobileMoneyNumberLast4}',
          ]
        : <String>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
        borderRadius: BorderRadius.circular(w * 0.045),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet01,
                  color: AppColors.accentLight,
                  size: w * 0.06,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Text(
                  'How you get paid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.012),
                decoration: BoxDecoration(
                  color: configured
                      ? AppColors.success.withValues(alpha: 0.18)
                      : AppColors.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: configured
                          ? HugeIcons.strokeRoundedCheckmarkCircle02
                          : HugeIcons.strokeRoundedAlert02,
                      color: configured ? AppColors.success : AppColors.warning,
                      size: w * 0.032,
                    ),
                    SizedBox(width: w * 0.012),
                    Text(
                      configured ? 'Configured' : 'Not set up',
                      style: TextStyle(
                        color: configured ? AppColors.success : AppColors.warning,
                        fontSize: w * 0.028,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),
          if (summary.isEmpty)
            Text(
              'Add a bank account or mobile money number so we know where to send your earnings.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: w * 0.032,
                height: 1.4,
              ),
            )
          else
            ...summary.map(
              (line) => Padding(
                padding: EdgeInsets.only(bottom: w * 0.012),
                child: Row(
                  children: [
                    Container(
                      width: w * 0.014,
                      height: w * 0.014,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Text(
                      line,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final double w;
  final List<List<dynamic>> icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.w,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.05),
              SizedBox(width: w * 0.025),
              Text(
                title,
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.04),
          ...children,
        ],
      ),
    );
  }
}

class _PayoutField extends StatelessWidget {
  final double w;
  final TextEditingController controller;
  final String label;
  final String? hint;
  final List<List<dynamic>> icon;
  final TextInputType? keyboardType;

  const _PayoutField({
    required this.w,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.018),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: w * 0.038),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: EdgeInsets.all(w * 0.032),
              child: HugeIcon(icon: icon, color: AppColors.textSecondary, size: w * 0.045),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final double w;
  final String message;

  const _ErrorBanner({required this.w, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: AppColors.error,
            size: w * 0.045,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: w * 0.032,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final double w;
  const _InfoNote({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedShieldKey,
            color: AppColors.info,
            size: w * 0.045,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              'Your account details are securely stored. Only the last 4 digits are ever shown after saving.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: w * 0.03,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
