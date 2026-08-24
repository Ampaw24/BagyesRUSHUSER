import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/presentation/providers/report_provider.dart';
import 'package:bagyesrushappusernew/features/report/presentation/report_flow_args.dart';
import 'package:bagyesrushappusernew/features/report/presentation/states/my_reports_state.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/report_card.dart';

/// The primary "Report a Problem" destination — a history of past reports
/// with a way to start a new one, mirroring the "Help" hub pattern in
/// Uber Eats/DoorDash.
class MyReportsView extends ConsumerWidget {
  final ReportRole role;

  const MyReportsView({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(myReportsProvider(role));

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: AppColors.textPrimary,
              size: w * 0.05,
            ),
            onPressed: () => AppNavigator.toReportFlow(
              context,
              args: ReportFlowArgs(role: role),
            ),
          ),
        ],
      ),
      body: switch (state) {
        MyReportsLoading() =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        MyReportsError(:final message) => _ErrorState(
            w: w,
            message: message,
            onRetry: () => ref.read(myReportsProvider(role).notifier).refresh(),
          ),
        MyReportsLoaded(:final reports) when reports.isEmpty => _EmptyState(w: w, role: role),
        MyReportsLoaded(:final reports) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(myReportsProvider(role).notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
              itemCount: reports.length,
              separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
              itemBuilder: (context, i) => ReportCard(
                report: reports[i],
                onTap: () => AppNavigator.toReportDetail(
                  context,
                  reports[i].id,
                  role: role,
                ),
              ),
            ),
          ),
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double w;
  final ReportRole role;
  const _EmptyState({required this.w, required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedFlag02,
              size: w * 0.16,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'No reports yet',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'If something goes wrong with a vendor, rider, or order, you can report it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary, height: 1.4),
            ),
            SizedBox(height: w * 0.06),
            ElevatedButton(
              onPressed: () => AppNavigator.toReportFlow(
                context,
                args: ReportFlowArgs(role: role),
              ),
              child: const Text('New Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final double w;
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.w, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: w * 0.14,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load your reports",
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
