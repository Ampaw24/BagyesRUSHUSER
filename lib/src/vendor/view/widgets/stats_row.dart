import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
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

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) SizedBox(width: w * 0.025),
          Expanded(child: _StatCard(stat: stats[i])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = stat.iconColor ?? AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(vertical: w * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.02),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: stat.icon,
              color: color,
              size: w * 0.045,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.005),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: w * 0.028,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
