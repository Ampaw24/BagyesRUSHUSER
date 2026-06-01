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
          Expanded(child: _StatCard(stat: stats[i])),
          if (i < stats.length - 1) SizedBox(width: w * 0.035),
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
      padding: EdgeInsets.symmetric(vertical: w * 0.04, horizontal: w * 0.025),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.015),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: stat.icon,
              color: color,
              size: w * 0.04,
            ),
          ),
          SizedBox(height: w * 0.025),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: (w * 0.04).clamp(14.0, 18.0),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Mukta',
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: w * 0.005),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (w * 0.024).clamp(9.0, 12.0),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Mukta',
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
