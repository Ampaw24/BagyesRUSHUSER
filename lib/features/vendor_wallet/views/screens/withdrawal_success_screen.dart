import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/withdrawal_model.dart';
import '../../models/transaction_model.dart';

/// Shown after a successful withdrawal request.
class WithdrawalSuccessScreen extends StatefulWidget {
  final WithdrawalModel withdrawal;

  const WithdrawalSuccessScreen({super.key, required this.withdrawal});

  @override
  State<WithdrawalSuccessScreen> createState() =>
      _WithdrawalSuccessScreenState();
}

class _WithdrawalSuccessScreenState extends State<WithdrawalSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
        TransactionStatus.processing => 'Processing',
        TransactionStatus.completed  => 'Completed',
        TransactionStatus.failed     => 'Failed',
        TransactionStatus.pending    => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            children: [
              const Spacer(),

              // ── Success icon ─────────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Heading ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const Text(
                        'Withdrawal Requested!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your funds are on the way to\n${widget.withdrawal.paymentMethodLabel}.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Summary card ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
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
                        value:
                            'GH₵ ${widget.withdrawal.amount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Processing Fee',
                        value:
                            '- GH₵ ${widget.withdrawal.fee.toStringAsFixed(2)}',
                        valueColor: AppColors.error,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: 'You Receive',
                        value:
                            'GH₵ ${widget.withdrawal.netAmount.toStringAsFixed(2)}',
                        bold: true,
                        valueColor: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _SummaryRow(
                        label: 'Status',
                        value: _statusLabel,
                        valueColor: AppColors.warning,
                      ),
                      if (widget.withdrawal.referenceCode != null) ...[
                        const SizedBox(height: 10),
                        _SummaryRow(
                          label: 'Reference',
                          value: widget.withdrawal.referenceCode!,
                          valueColor: AppColors.textSecondary,
                          monospace: true,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Estimated Arrival',
                        value: '1–3 business hours',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Done button ──────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop back to wallet screen
                          Navigator.of(context)
                            ..pop() // success screen
                            ..pop(); // withdraw screen
                        },
                        child: const Text('Back to Wallet'),
                      ),
                    ),
                    const SizedBox(height: 16),
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
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool monospace;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
