import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../constant/app_theme.dart';
import '../../../vendor_payment_methods/models/payment_method_model.dart';
import '../../../vendor_payment_methods/providers/payment_providers.dart';
import '../../../vendor_payment_methods/viewmodels/payment_methods_viewmodel.dart';
import '../../models/withdrawal_model.dart';
import '../../providers/wallet_providers.dart';
import 'withdrawal_success_screen.dart';

/// Three-step withdrawal flow:
///   Step 1 — Select a verified payment method
///   Step 2 — Enter amount + review fee breakdown
///   Step 3 → navigate to WithdrawalSuccessScreen
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  int _step = 0; // 0 = select method, 1 = enter amount
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  bool _showAmountError = false;

  @override
  void initState() {
    super.initState();
    // Ensure payment methods are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentMethodsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ── Step navigation ───────────────────────────────────────────────────────

  void _onMethodSelected(PaymentMethodModel method) {
    ref.read(withdrawalProvider.notifier).selectMethod(
          method.id,
          method.displayTitle,
        );
    setState(() => _step = 1);
    Future.delayed(
      const Duration(milliseconds: 300),
      () => _amountFocus.requestFocus(),
    );
  }

  Future<void> _submit() async {
    setState(() => _showAmountError = true);
    final state = ref.read(withdrawalProvider);
    if (!state.canSubmit) return;

    await ref.read(withdrawalProvider.notifier).submit();

    final newState = ref.read(withdrawalProvider);
    if (!mounted) return;

    if (newState.status == WithdrawalStatus.success &&
        newState.result != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, _) =>
              WithdrawalSuccessScreen(withdrawal: newState.result!),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      ref.read(withdrawalProvider.notifier).reset();
    } else if (newState.status == WithdrawalStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newState.errorMessage ?? 'Withdrawal failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final withdrawState = ref.watch(withdrawalProvider);
    final walletState   = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(_step == 0 ? 'Select Payment Method' : 'Withdraw Funds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: _step == 0
              ? _MethodStep(
                  key: const ValueKey(0),
                  onSelect: _onMethodSelected,
                )
              : _AmountStep(
                  key: const ValueKey(1),
                  amountCtrl: _amountCtrl,
                  amountFocus: _amountFocus,
                  showError: _showAmountError,
                  withdrawState: withdrawState,
                  availableBalance: walletState.wallet.availableBalance,
                  currency: walletState.wallet.currency,
                  onAmountChanged: (v) {
                    final parsed = double.tryParse(v) ?? 0;
                    ref.read(withdrawalProvider.notifier).setAmount(parsed);
                  },
                  onSubmit: _submit,
                ),
        ),
      ),
    );
  }
}

// ── Step 1: Select payment method ─────────────────────────────────────────────

class _MethodStep extends ConsumerWidget {
  final ValueChanged<PaymentMethodModel> onSelect;
  const _MethodStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pmState = ref.watch(paymentMethodsProvider);
    final verified = pmState.paymentMethods
        .where((m) => m.isVerified && m.isEnabled)
        .toList();

    if (pmState.status == PaymentMethodsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (verified.isEmpty) {
      return _NoMethodsPlaceholder();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Text(
          'Where should we send your funds?',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ...verified.map((m) => _MethodTile(method: m, onTap: () => onSelect(m))),
      ],
    );
  }
}

class _MethodTile extends StatefulWidget {
  final PaymentMethodModel method;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.onTap});

  @override
  State<_MethodTile> createState() => _MethodTileState();
}

class _MethodTileState extends State<_MethodTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDefault = widget.method.isDefault;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDefault
                  ? primary.withValues(alpha: 0.4)
                  : AppColors.border,
              width: isDefault ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.method.type == PaymentMethodType.mobileMoney
                      ? Icons.phone_android_rounded
                      : Icons.credit_card_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.method.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.method.displaySubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoMethodsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 52, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'No verified payment methods',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add and verify a payment method first to receive withdrawals.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Enter amount ──────────────────────────────────────────────────────

class _AmountStep extends StatelessWidget {
  final TextEditingController amountCtrl;
  final FocusNode amountFocus;
  final bool showError;
  final WithdrawalState withdrawState;
  final double availableBalance;
  final String currency;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onSubmit;

  const _AmountStep({
    super.key,
    required this.amountCtrl,
    required this.amountFocus,
    required this.showError,
    required this.withdrawState,
    required this.availableBalance,
    required this.currency,
    required this.onAmountChanged,
    required this.onSubmit,
  });

  String? get _amountError {
    if (!showError) return null;
    if (withdrawState.amount <= 0) return 'Enter an amount';
    if (withdrawState.amount < kMinWithdrawal) {
      return 'Minimum withdrawal is $currency ${kMinWithdrawal.toStringAsFixed(2)}';
    }
    if (withdrawState.amount > availableBalance) {
      return 'Amount exceeds available balance';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isLoading = withdrawState.status == WithdrawalStatus.loading;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Selected method recap
        if (withdrawState.selectedMethodLabel != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  'To: ${withdrawState.selectedMethodLabel}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),

        // Available balance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$currency ${availableBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Amount input
        TextField(
          controller: amountCtrl,
          focusNode: amountFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: onAmountChanged,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: AppColors.textHint,
            ),
            prefix: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                currency,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            errorText: _amountError,
            errorStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Quick-amount chips
        const SizedBox(height: 16),
        _QuickAmountRow(
          availableBalance: availableBalance,
          onSelect: (v) {
            amountCtrl.text = v.toStringAsFixed(2);
            onAmountChanged(amountCtrl.text);
          },
        ),

        const SizedBox(height: 28),

        // Fee breakdown
        if (withdrawState.amount >= kMinWithdrawal)
          _FeeBreakdown(
            amount: withdrawState.amount,
            fee: withdrawState.fee,
            net: withdrawState.net,
            currency: currency,
          ),

        const SizedBox(height: 32),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Withdrawal'),
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          'Funds typically arrive within 1–3 business hours.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ],
    );
  }
}

// ── Quick amount chips ────────────────────────────────────────────────────────

class _QuickAmountRow extends StatelessWidget {
  final double availableBalance;
  final ValueChanged<double> onSelect;

  const _QuickAmountRow({
    required this.availableBalance,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [50.0, 100.0, 200.0, 500.0]
        .where((v) => v <= availableBalance)
        .toList();
    if (availableBalance > 0) presets.add(availableBalance); // "Max"

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: presets.map((v) {
        final isMax = v == availableBalance;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              isMax && !presets
                      .sublist(0, presets.length - 1)
                      .contains(availableBalance)
                  ? 'Max'
                  : v.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Fee breakdown ─────────────────────────────────────────────────────────────

class _FeeBreakdown extends StatelessWidget {
  final double amount;
  final double fee;
  final double net;
  final String currency;

  const _FeeBreakdown({
    required this.amount,
    required this.fee,
    required this.net,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _Row('Withdrawal Amount', '$currency ${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _Row(
            'Processing Fee (1.5%)',
            '- $currency ${fee.toStringAsFixed(2)}',
            valueColor: AppColors.error,
          ),
          const Divider(height: 20),
          _Row(
            'You Receive',
            '$currency ${net.toStringAsFixed(2)}',
            bold: true,
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
