import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../viewmodel/earnings_viewmodel.dart';
import '../model/earnings_data.dart';

class VendorEarningsView extends StatelessWidget {
  const VendorEarningsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => sl<EarningsViewModel>()..loadEarnings(),
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
                    'Track your revenue & performance',
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

                    // Order Stats Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hp),
                        child: _OrderStatsGrid(data: state.data),
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

// ─── Order Stats Grid ───────────────────────────────────────────────────

class _OrderStatsGrid extends StatelessWidget {
  final EarningsData data;

  const _OrderStatsGrid({required this.data});

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
        SizedBox(height: w * 0.025),
        Row(
          children: [
            _StatMiniCard(
              icon: Icons.percent_rounded,
              iconColor: AppColors.warning,
              value: data.commission,
              label: 'Commission',
            ),
            SizedBox(width: w * 0.025),
            _StatMiniCard(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.success,
              value: data.netEarnings,
              label: 'Net Earnings',
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
