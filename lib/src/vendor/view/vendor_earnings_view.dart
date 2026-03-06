import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../viewmodel/earnings_viewmodel.dart';

class VendorEarningsView extends StatefulWidget {
  const VendorEarningsView({super.key});

  @override
  State<VendorEarningsView> createState() => _VendorEarningsViewState();
}

class _VendorEarningsViewState extends State<VendorEarningsView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EarningsViewModel>().loadEarnings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPad = w * 0.05;

    return Consumer<EarningsViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, w * 0.03, horizontalPad, 0),
              child: Text(
                'Earnings',
                style: TextStyle(
                  fontSize: w * 0.055,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(height: w * 0.03),

            // ── Period filter ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              child: Row(
                children: ['today', 'week', 'month', 'all'].map((period) {
                  final selected = vm.state.selectedPeriod == period;
                  return Padding(
                    padding: EdgeInsets.only(right: w * 0.02),
                    child: GestureDetector(
                      onTap: () => vm.loadEarnings(period: period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.035,
                          vertical: w * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(w * 0.05),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          period[0].toUpperCase() + period.substring(1),
                          style: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: w * 0.04),

            // ── Content ──
            if (vm.state.status == EarningsStatus.loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.state.status == EarningsStatus.error)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: w * 0.1, color: AppColors.error),
                      SizedBox(height: w * 0.03),
                      Text(
                        vm.state.errorMessage ?? 'Something went wrong',
                        style: TextStyle(
                          fontSize: w * 0.035,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: w * 0.04),
                      ElevatedButton(
                        onPressed: () => vm.loadEarnings(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Summary cards ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: Row(
                  children: [
                    _SummaryCard(
                      title: "Today's Revenue",
                      value: vm.state.data.todayRevenue,
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                    ),
                    SizedBox(width: w * 0.025),
                    _SummaryCard(
                      title: 'Pending Payout',
                      value: vm.state.data.pendingPayout,
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.025),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: Row(
                  children: [
                    _SummaryCard(
                      title: 'Total Revenue',
                      value: vm.state.data.totalRevenue,
                      icon: Icons.payments_rounded,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: w * 0.025),
                    _SummaryCard(
                      title: 'Total Orders',
                      value: '${vm.state.data.totalOrders}',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.05),

              // ── Transactions header ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: w * 0.03),

              // ── Transaction list ──
              Expanded(
                child: vm.state.data.transactions.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: w * 0.035,
                            color: AppColors.textHint,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad, 0, horizontalPad, w * 0.25,
                        ),
                        itemCount: vm.state.data.transactions.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: w * 0.005, color: AppColors.divider),
                        itemBuilder: (_, index) {
                          final txn = vm.state.data.transactions[index];
                          final isCredit = txn.type == 'credit';
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: w * 0.025),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(w * 0.025),
                                  decoration: BoxDecoration(
                                    color: (isCredit
                                            ? AppColors.success
                                            : AppColors.error)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCredit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: w * 0.045,
                                    color: isCredit
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                SizedBox(width: w * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ${txn.orderId}',
                                        style: TextStyle(
                                          fontSize: w * 0.035,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        txn.date,
                                        style: TextStyle(
                                          fontSize: w * 0.028,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'}${txn.amount}',
                                  style: TextStyle(
                                    fontSize: w * 0.038,
                                    fontWeight: FontWeight.w700,
                                    color: isCredit
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Icon(icon, size: w * 0.045, color: color),
            ),
            SizedBox(height: w * 0.02),
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.045,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.005),
            Text(
              title,
              style: TextStyle(
                fontSize: w * 0.028,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
