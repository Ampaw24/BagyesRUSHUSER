import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/widgets/inline_message.dart';
import 'package:bagyesrushappusernew/src/payment/model/payout_provider_model.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_state.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/views/widgets/payout_provider_visuals.dart';
import '../viewmodels/payout_setup_viewmodel.dart';

/// Sets where wallet withdrawals are paid out: the account's verified phone
/// number is shown (it is the payout number), and the customer only picks
/// the mobile-money network. Saves with `PUT /customer/wallet/payout-method`
/// and pops `true`.
///
/// Expects a [PayoutSetupViewModel] and a [PayoutProvidersViewModel] above it.
class AddPayoutMethodView extends StatefulWidget {
  const AddPayoutMethodView({super.key});

  @override
  State<AddPayoutMethodView> createState() => _AddPayoutMethodViewState();
}

class _AddPayoutMethodViewState extends State<AddPayoutMethodView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PayoutProvidersViewModel>().load();
    });
  }

  Future<void> _save() async {
    final saved = await context.read<PayoutSetupViewModel>().save();
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final setup = context.watch<PayoutSetupViewModel>();
    final providers = context.watch<PayoutProvidersViewModel>();
    final user = context.watch<CurrentUserProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Add payout method')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Where should we send your money?',
                      style: TextStyle(
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.015),
                    Text(
                      'Withdrawals are paid to your verified phone number. '
                      'Choose the network it\'s on.',
                      style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: w * 0.06),
                    _SectionLabel('PAYOUT NUMBER', w: w),
                    SizedBox(height: w * 0.025),
                    _PhoneCard(
                      phone: user?.phone ?? '',
                      verified: user?.phoneVerified ?? false,
                    ),
                    SizedBox(height: w * 0.06),
                    _SectionLabel('CHOOSE YOUR NETWORK', w: w),
                    SizedBox(height: w * 0.025),
                    _Networks(
                      providers: providers,
                      selectedId: setup.state.selectedProviderId,
                      onSelect: setup.select,
                    ),
                    if (setup.state.errorMessage != null) ...[
                      SizedBox(height: w * 0.04),
                      InlineMessage(message: setup.state.errorMessage!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: setup.state.canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: w * 0.038),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: setup.state.isSaving
                      ? SizedBox(
                          width: w * 0.05,
                          height: w * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save payout method',
                          style: TextStyle(fontSize: w * 0.038, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.w});

  final String text;
  final double w;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: w * 0.028,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.phone, required this.verified});

  final String phone;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final accent = verified ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_iphone_rounded, size: w * 0.07, color: AppColors.textSecondary),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Text(
              phone.isEmpty ? 'No phone number on this account' : phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.008),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(w),
            ),
            child: Text(
              verified ? 'Verified' : 'Not verified',
              style: TextStyle(
                fontSize: w * 0.027,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Networks extends StatelessWidget {
  const _Networks({
    required this.providers,
    required this.selectedId,
    required this.onSelect,
  });

  final PayoutProvidersViewModel providers;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final networks = providers.mobileMoneyProviders;

    if (providers.isLoading || providers.state is PayoutProvidersInitial) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.08),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (providers.error != null) {
      return Column(
        children: [
          Text(
            'Couldn\'t load the networks.',
            style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
          ),
          SizedBox(height: w * 0.03),
          OutlinedButton(
            onPressed: () => providers.load(force: true),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (networks.isEmpty) {
      return Text(
        'No payout networks are available right now.',
        style: TextStyle(fontSize: w * 0.035, color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        for (final network in networks)
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.03),
            child: _NetworkTile(
              provider: network,
              selected: network.id == selectedId,
              onTap: () => onSelect(network.id),
            ),
          ),
      ],
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final PayoutProviderModel provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final accent = payoutProviderVisual(provider).color;

    return Material(
      color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(w * 0.04),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(w * 0.035),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              PayoutProviderAvatar(provider: provider, size: w * 0.11),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: w * 0.06,
                color: selected ? accent : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
