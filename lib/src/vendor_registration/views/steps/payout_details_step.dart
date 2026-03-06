import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';
import '../../models/payout_details_data.dart';
import '../widgets/vendor_text_field.dart';

/// Step 4 - Bank account / mobile money payout details
class PayoutDetailsStep extends StatefulWidget {
  final PayoutDetailsData data;
  final ValueChanged<PayoutDetailsData> onChanged;

  const PayoutDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<PayoutDetailsStep> createState() => _PayoutDetailsStepState();
}

class _PayoutDetailsStepState extends State<PayoutDetailsStep> {
  late TextEditingController _bankCtrl;
  late TextEditingController _accountNumCtrl;
  late TextEditingController _accountNameCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _momoNumCtrl;

  int _selectedTab = 0; // 0 = Bank, 1 = Mobile Money

  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController(text: widget.data.bankName);
    _accountNumCtrl = TextEditingController(text: widget.data.accountNumber);
    _accountNameCtrl = TextEditingController(text: widget.data.accountName);
    _branchCtrl = TextEditingController(text: widget.data.branchCode ?? '');
    _momoNumCtrl = TextEditingController(
      text: widget.data.mobileMoneyNumber ?? '',
    );

    // Auto-select mobile money tab if data exists
    if ((widget.data.mobileMoneyNumber ?? '').isNotEmpty) {
      _selectedTab = 1;
    }
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accountNumCtrl.dispose();
    _accountNameCtrl.dispose();
    _branchCtrl.dispose();
    _momoNumCtrl.dispose();
    super.dispose();
  }

  void _emitBank() {
    widget.onChanged(
      widget.data.copyWith(
        bankName: _bankCtrl.text,
        accountNumber: _accountNumCtrl.text,
        accountName: _accountNameCtrl.text,
        branchCode: _branchCtrl.text,
      ),
    );
  }

  void _emitMomo() {
    widget.onChanged(
      widget.data.copyWith(
        mobileMoneyNumber: _momoNumCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.03),
            color: AppColors.surfaceVariant,
          ),
          padding: EdgeInsets.all(size.width * 0.01),
          child: Row(
            children: [
              _buildTab(0, 'Bank Account', size),
              _buildTab(1, 'Mobile Money', size),
            ],
          ),
        ),
        SizedBox(height: size.height * 0.025),

        // Tab content with animated switch
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _selectedTab == 0
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buildBankForm(size),
          secondChild: _buildMomoForm(size),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label, Size size) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.025),
            color: isSelected ? Colors.white : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: size.width * 0.02,
                      offset: Offset(0, size.height * 0.002),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: size.width * 0.034,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankForm(Size size) {
    return Column(
      children: [
        VendorTextField(
          label: 'Bank Name',
          hint: 'e.g. Ghana Commercial Bank',
          controller: _bankCtrl,
          onChanged: (_) => _emitBank(),
        ),
        SizedBox(height: size.height * 0.022),
        VendorTextField(
          label: 'Account Number',
          hint: 'Enter account number',
          controller: _accountNumCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _emitBank(),
        ),
        SizedBox(height: size.height * 0.022),
        VendorTextField(
          label: 'Account Name',
          hint: 'Name on the bank account',
          controller: _accountNameCtrl,
          onChanged: (_) => _emitBank(),
        ),
        SizedBox(height: size.height * 0.022),
        VendorTextField(
          label: 'Branch Code (optional)',
          hint: 'Bank branch code',
          controller: _branchCtrl,
          onChanged: (_) => _emitBank(),
        ),
      ],
    );
  }

  Widget _buildMomoForm(Size size) {
    return Column(
      children: [
        // Provider selection
        Text(
          'Mobile Money Provider',
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.012),
        _MomoProviderSelector(
          selected: widget.data.mobileMoneyProvider,
          onChanged: (provider) {
            widget.onChanged(
              widget.data.copyWith(mobileMoneyProvider: provider),
            );
          },
        ),
        SizedBox(height: size.height * 0.022),
        VendorTextField(
          label: 'Mobile Money Number',
          hint: '024 123 4567',
          controller: _momoNumCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _emitMomo(),
        ),
      ],
    );
  }
}

class _MomoProviderSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const _MomoProviderSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _providers = ['MTN MoMo', 'Vodafone Cash', 'AirtelTigo Money'];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Wrap(
      spacing: size.width * 0.025,
      runSpacing: size.height * 0.01,
      children: _providers.map((provider) {
        final isSelected = selected == provider;
        return GestureDetector(
          onTap: () => onChanged(provider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.012,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.025),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              provider,
              style: TextStyle(
                fontSize: size.width * 0.032,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
