import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../viewmodel/earnings_viewmodel.dart';
import '../model/earnings_data.dart';

class VendorEarningsView extends StatelessWidget {
  const VendorEarningsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EarningsViewModel()..loadEarnings(),
      child: const _EarningsContent(),
    );
  }
}

// ─── Main content ───────────────────────────────────────────────────────

class _EarningsContent extends StatelessWidget {
  const _EarningsContent();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hp = w * 0.05;

    return Consumer<EarningsViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(hp, w * 0.03, hp, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings',
                    style: TextStyle(
                      fontSize: w * 0.06,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    'Track your revenue & payouts',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: w * 0.03),

            // ── Period filter ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'Today',
                    value: 'today',
                    selected: state.selectedPeriod,
                    onTap: vm.setPeriod,
                  ),
                  _PeriodChip(
                    label: 'This Week',
                    value: 'week',
                    selected: state.selectedPeriod,
                    onTap: vm.setPeriod,
                  ),
                  _PeriodChip(
                    label: 'This Month',
                    value: 'month',
                    selected: state.selectedPeriod,
                    onTap: vm.setPeriod,
                  ),
                  _PeriodChip(
                    label: 'All Time',
                    value: 'all',
                    selected: state.selectedPeriod,
                    onTap: vm.setPeriod,
                  ),
                ],
              ),
            ),
            SizedBox(height: w * 0.04),

            // ── Scrollable content ──
            if (state.status == EarningsStatus.loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (state.status == EarningsStatus.error)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: w * 0.1, color: AppColors.error),
                      SizedBox(height: w * 0.03),
                      Text(
                        state.errorMessage ?? 'Something went wrong',
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
            else
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Revenue Hero Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: _RevenueHeroCard(state: state),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),

                    // Payout Banner
                    if (state.data.payouts
                        .any((p) => p.status != 'completed'))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: hp),
                          child: _PendingPayoutBanner(
                            payout: state.data.payouts.firstWhere(
                              (p) => p.status != 'completed',
                            ),
                          ),
                        ),
                      ),
                    if (state.data.payouts
                        .any((p) => p.status != 'completed'))
                      SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),

                    // Revenue Chart
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: _RevenueChart(
                          data: state.data.chartData,
                          periodKey: state.selectedPeriod,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),

                    // Order Stats Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: _OrderStatsGrid(
                          data: state.data,
                          periodKey: state.selectedPeriod,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),

                    // Top Selling Items
                    if (state.data.topItems.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _TopSellingSection(
                          items: state.data.topItems,
                          horizontalPad: hp,
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),
                    ],

                    // Payouts Section
                    if (state.data.payouts
                        .where((p) => p.status == 'completed')
                        .isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: hp),
                          child: _PayoutsSection(
                            payouts: state.data.payouts
                                .where((p) => p.status == 'completed')
                                .toList(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: w * 0.04)),
                    ],

                    // Transactions Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: _TransactionHeader(
                          totalCount: state.data.transactions.length,
                          filter: state.transactionFilter,
                          onFilterChanged: vm.setTransactionFilter,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: w * 0.02)),

                    // Transaction List
                    if (state.filteredTransactions.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: w * 0.08),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_rounded,
                                    size: w * 0.12, color: AppColors.textHint),
                                SizedBox(height: w * 0.03),
                                Text(
                                  'No transactions found',
                                  style: TextStyle(
                                    fontSize: w * 0.035,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final txns = state.filteredTransactions;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                  hp, 0, hp, w * 0.025),
                              child: _TransactionTile(
                                transaction: txns[index],
                              ),
                            );
                          },
                          childCount: state.filteredTransactions.length,
                        ),
                      ),

                    // Bottom padding for nav bar
                    SliverPadding(
                        padding: EdgeInsets.only(bottom: w * 0.28)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Period chip ─────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isSelected = selected == value;

    return Padding(
      padding: EdgeInsets.only(right: w * 0.02),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.022,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(w * 0.06),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Revenue Hero Card ──────────────────────────────────────────────────

class _RevenueHeroCard extends StatelessWidget {
  final EarningsState state;
  const _RevenueHeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final data = state.data;
    final growth = data.revenueGrowth;
    final isPositive = growth >= 0;

    return Container(
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondaryDark],
        ),
        borderRadius: BorderRadius.circular(w * 0.05),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label chip
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.025, vertical: w * 0.01),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Text(
              state.periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: w * 0.028,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: w * 0.04),

          // Revenue amount
          Text(
            state.displayRevenue,
            style: TextStyle(
              color: Colors.white,
              fontSize: w * 0.085,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),

          SizedBox(height: w * 0.015),

          // Growth indicator
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.02, vertical: w * 0.008),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(w * 0.015),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isPositive
                          ? AppColors.accentLight
                          : const Color(0xFFFC8181),
                      size: w * 0.035,
                    ),
                    SizedBox(width: w * 0.01),
                    Text(
                      '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPositive
                            ? AppColors.accentLight
                            : const Color(0xFFFC8181),
                        fontSize: w * 0.028,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.02),
              Text(
                state.growthComparison,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: w * 0.026,
                ),
              ),
            ],
          ),

          SizedBox(height: w * 0.05),

          // Mini stats row
          Row(
            children: [
              _HeroMiniStat(
                value: '${data.totalOrders}',
                label: 'Orders',
                icon: Icons.receipt_long_rounded,
              ),
              SizedBox(width: w * 0.025),
              _HeroMiniStat(
                value: data.avgOrderValue,
                label: 'Avg Order',
                icon: Icons.show_chart_rounded,
              ),
              SizedBox(width: w * 0.025),
              _HeroMiniStat(
                value: '${data.completionRate.toStringAsFixed(0)}%',
                label: 'Success',
                icon: Icons.verified_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Hero mini stat ─────────────────────────────────────────────────────

class _HeroMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroMiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: w * 0.025, horizontal: w * 0.02),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: Colors.white.withValues(alpha: 0.5),
                size: w * 0.04),
            SizedBox(height: w * 0.01),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.03,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: w * 0.003),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: w * 0.024,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Payout Banner ──────────────────────────────────────────────

class _PendingPayoutBanner extends StatelessWidget {
  final PayoutRecord payout;
  const _PendingPayoutBanner({required this.payout});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.035),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.025),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(w * 0.025),
            ),
            child: Icon(Icons.schedule_rounded,
                color: AppColors.accent, size: w * 0.05),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Payout',
                  style: TextStyle(
                    fontSize: w * 0.026,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: w * 0.005),
                Text(
                  payout.amount,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.003),
                Text(
                  payout.date,
                  style: TextStyle(
                    fontSize: w * 0.025,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payout requests coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.035, vertical: w * 0.018),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
            ),
            child: Text(
              'Request',
              style: TextStyle(
                  fontSize: w * 0.028, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Chart ──────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<DailyRevenue> data;
  final String periodKey;

  const _RevenueChart({required this.data, required this.periodKey});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final chartHeight = w * 0.35;
    final maxVal = data.fold<double>(0, (m, d) => d.amount > m ? d.amount : m);
    final highestIndex =
        data.indexWhere((d) => d.amount == maxVal);

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Revenue Trend',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.02, vertical: w * 0.008),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(w * 0.015),
                ),
                child: Text(
                  '${data.length} periods',
                  style: TextStyle(
                    fontSize: w * 0.024,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.05),

          // Chart bars
          SizedBox(
            height: chartHeight + w * 0.1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final fraction =
                    maxVal > 0 ? d.amount / maxVal : 0.0;
                final isHighest = i == highestIndex;

                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: w * 0.008),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label on highest bar
                        if (isHighest) ...[
                          Text(
                            _formatChartValue(d.amount),
                            style: TextStyle(
                              fontSize: w * 0.022,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: w * 0.01),
                        ] else
                          SizedBox(height: w * 0.04),

                        // Animated bar
                        TweenAnimationBuilder<double>(
                          key: ValueKey('bar_${periodKey}_$i'),
                          tween: Tween(begin: 0.0, end: fraction),
                          duration: Duration(
                              milliseconds: 500 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, _) => Container(
                            height: val * chartHeight,
                            decoration: BoxDecoration(
                              gradient: isHighest
                                  ? const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                    )
                                  : null,
                              color: isHighest
                                  ? null
                                  : AppColors.primary
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(w * 0.015),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: w * 0.02),

                        // Day label
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: w * 0.024,
                            color: isHighest
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            fontWeight: isHighest
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChartValue(double value) {
    if (value >= 1000) {
      return 'GH₵ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'GH₵ ${value.toInt()}';
  }
}

// ─── Order Stats Grid ───────────────────────────────────────────────────

class _OrderStatsGrid extends StatelessWidget {
  final EarningsData data;
  final String periodKey;

  const _OrderStatsGrid({required this.data, required this.periodKey});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Row(
          children: [
            _StatMiniCard(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.info,
              value: '${data.totalOrders}',
              label: 'Total Orders',
            ),
            SizedBox(width: w * 0.025),
            _StatMiniCard(
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              value: '${data.completedOrders}',
              label: 'Completed',
            ),
          ],
        ),
        SizedBox(height: w * 0.025),
        Row(
          children: [
            _StatMiniCard(
              icon: Icons.cancel_outlined,
              iconColor: AppColors.error,
              value: '${data.cancelledOrders}',
              label: 'Cancelled',
            ),
            SizedBox(width: w * 0.025),
            _StatMiniCard(
              icon: Icons.speed_rounded,
              iconColor: AppColors.accent,
              value: '${data.completionRate.toStringAsFixed(1)}%',
              label: 'Success Rate',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatMiniCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Icon(icon, size: w * 0.04, color: iconColor),
            ),
            SizedBox(width: w * 0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: w * 0.025,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Selling Section ────────────────────────────────────────────────

class _TopSellingSection extends StatelessWidget {
  final List<TopSellingItem> items;
  final double horizontalPad;

  const _TopSellingSection({
    required this.items,
    required this.horizontalPad,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Text(
            'Top Selling Items',
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: w * 0.03),
        SizedBox(
          height: w * 0.4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: w * 0.03),
            itemBuilder: (_, index) =>
                _TopSellingCard(item: items[index], rank: index + 1),
          ),
        ),
      ],
    );
  }
}

class _TopSellingCard extends StatelessWidget {
  final TopSellingItem item;
  final int rank;

  const _TopSellingCard({required this.item, required this.rank});

  Color _rankColor() => switch (rank) {
        1 => AppColors.accent,
        2 => AppColors.textSecondary,
        3 => AppColors.warning,
        _ => AppColors.textHint,
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = _rankColor();

    return Container(
      width: w * 0.34,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(
          color: rank == 1
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.border,
          width: rank == 1 ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.02, vertical: w * 0.008),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(w * 0.012),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: w * 0.026,
              ),
            ),
          ),
          SizedBox(height: w * 0.025),

          // Name
          Text(
            item.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: w * 0.03,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Category
          if (item.category.isNotEmpty) ...[
            Text(
              item.category,
              style: TextStyle(
                fontSize: w * 0.024,
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: w * 0.01),
          ],

          // Order count
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: w * 0.03, color: AppColors.textSecondary),
              SizedBox(width: w * 0.01),
              Text(
                '${item.orderCount} orders',
                style: TextStyle(
                  fontSize: w * 0.025,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.01),

          // Revenue
          Text(
            item.revenue,
            style: TextStyle(
              fontSize: w * 0.03,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payouts Section ────────────────────────────────────────────────────

class _PayoutsSection extends StatelessWidget {
  final List<PayoutRecord> payouts;
  const _PayoutsSection({required this.payouts});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Payouts',
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.03),
          ...payouts.indexed.map(((int, PayoutRecord) entry) {
            final i = entry.$1;
            final payout = entry.$2;
            return Column(
              children: [
                if (i > 0)
                  Divider(height: w * 0.005, color: AppColors.divider),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: w * 0.025),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(w * 0.02),
                        decoration: BoxDecoration(
                          color: AppColors.success
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            color: AppColors.success,
                            size: w * 0.035),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              payout.amount,
                              style: TextStyle(
                                fontSize: w * 0.034,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: w * 0.003),
                            Text(
                              '${payout.method} \u2022 ${payout.reference}',
                              style: TextStyle(
                                fontSize: w * 0.025,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        payout.date,
                        style: TextStyle(
                          fontSize: w * 0.025,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Transaction Header ─────────────────────────────────────────────────

class _TransactionHeader extends StatelessWidget {
  final int totalCount;
  final TransactionFilter filter;
  final ValueChanged<TransactionFilter> onFilterChanged;

  const _TransactionHeader({
    required this.totalCount,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(width: w * 0.02),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: w * 0.018, vertical: w * 0.004),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(w * 0.025),
          ),
          child: Text(
            '$totalCount',
            style: TextStyle(
              fontSize: w * 0.025,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        _TxnFilterChip(
          label: 'All',
          isSelected: filter == TransactionFilter.all,
          onTap: () => onFilterChanged(TransactionFilter.all),
        ),
        SizedBox(width: w * 0.015),
        _TxnFilterChip(
          label: 'In',
          isSelected: filter == TransactionFilter.credits,
          onTap: () => onFilterChanged(TransactionFilter.credits),
        ),
        SizedBox(width: w * 0.015),
        _TxnFilterChip(
          label: 'Out',
          isSelected: filter == TransactionFilter.debits,
          onTap: () => onFilterChanged(TransactionFilter.debits),
        ),
      ],
    );
  }
}

class _TxnFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TxnFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: w * 0.025, vertical: w * 0.012),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: w * 0.026,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Tile ───────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  String _paymentLabel(String method) => switch (method) {
        'mobile_money' => 'MoMo',
        'card' => 'Card',
        'cash' => 'Cash',
        'platform_fee' => 'Platform',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final txn = transaction;
    final isCredit = txn.type == 'credit';

    return Container(
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: w * 0.04,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),
          SizedBox(width: w * 0.03),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.orderId.startsWith('#')
                      ? 'Order ${txn.orderId}'
                      : txn.orderId,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.005),
                Row(
                  children: [
                    if (txn.customerName.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          txn.customerName,
                          style: TextStyle(
                            fontSize: w * 0.025,
                            color: AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' \u2022 ',
                        style: TextStyle(
                          fontSize: w * 0.025,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    Text(
                      _paymentLabel(txn.paymentMethod),
                      style: TextStyle(
                        fontSize: w * 0.025,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${txn.amount}',
                style: TextStyle(
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppColors.success : AppColors.error,
                ),
              ),
              SizedBox(height: w * 0.005),
              Text(
                txn.date,
                style: TextStyle(
                  fontSize: w * 0.022,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
