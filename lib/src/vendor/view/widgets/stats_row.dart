import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';

class StatItem {
  final String value;
  final String label;
  final List<List<dynamic>> icon;
  final Color? iconColor;

  const StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
  });
}

class StatsRow extends StatelessWidget {
  final List<StatItem> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < stats.length; i++) ...[
              Expanded(child: _StatCell(stat: stats[i])),
              if (i < stats.length - 1)
                VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: AppColors.border,
                  indent: w * 0.04,
                  endIndent: w * 0.04,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final StatItem stat;

  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = stat.iconColor ?? AppColors.primary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.048),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.016,
            height: w * 0.016,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(height: w * 0.018),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: w * 0.046,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.006),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: w * 0.028,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
