import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../models/vendor_withdrawal_model.dart';
import '../viewmodels/vendor_wallet_viewmodel.dart';

/// Shown after a successful `POST /vendor/me/withdrawals` request. No
/// fee/net breakdown — `VendorWithdrawalModel` carries only the requested
/// amount, unlike the old dummy flow's fee-inclusive model.
class VendorWithdrawalSuccessView extends StatefulWidget {
  const VendorWithdrawalSuccessView({super.key, required this.withdrawal});

  final VendorWithdrawalModel withdrawal;

  @override
  State<VendorWithdrawalSuccessView> createState() =>
      _VendorWithdrawalSuccessViewState();
}

class _VendorWithdrawalSuccessViewState
    extends State<VendorWithdrawalSuccessView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _statusLabel => switch (widget.withdrawal.status) {
    VendorWithdrawalStatus.pending => 'Pending',
    VendorWithdrawalStatus.processing => 'Processing',
    VendorWithdrawalStatus.completed => 'Completed',
    VendorWithdrawalStatus.failed => 'Failed',
    VendorWithdrawalStatus.cancelled => 'Cancelled',
  };

  void _backToWallet() {
    final vm = context.read<VendorWalletViewmodel>();
    vm.fetchWallet();
    vm.fetchTransactions();
    vm.fetchWithdrawals();
    Navigator.of(context)
      ..pop() // success screen
      ..pop(); // withdraw screen
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final withdrawal = widget.withdrawal;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: w * 0.24,
                  height: w * 0.24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: w * 0.14,
                  ),
                ),
              ),
              SizedBox(height: w * 0.07),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      Text(
                        'Withdrawal Requested!',
                        style: TextStyle(
                          fontSize: w * 0.06,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: w * 0.025),
                      Text(
                        'Your funds are on the way to your saved payout method.',
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: w * 0.09),
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: EdgeInsets.all(w * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(w * 0.05),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Amount',
                        value: withdrawal.amount.toStringAsFixed(2),
                      ),
                      SizedBox(height: w * 0.025),
                      _SummaryRow(
                        label: 'Status',
                        value: _statusLabel,
                        valueColor: AppColors.warning,
                      ),
                      if (withdrawal.reference != null) ...[
                        SizedBox(height: w * 0.025),
                        _SummaryRow(
                          label: 'Reference',
                          value: withdrawal.reference!,
                          valueColor: AppColors.textSecondary,
                          monospace: true,
                        ),
                      ],
                      SizedBox(height: w * 0.025),
                      _SummaryRow(
                        label: 'Requested',
                        value: _formatDate(withdrawal.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _backToWallet,
                        child: const Text('Back to Wallet'),
                      ),
                    ),
                    SizedBox(height: w * 0.04),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.monospace = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
