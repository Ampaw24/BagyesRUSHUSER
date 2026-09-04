import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/router/app_router.dart' show appRouteObserver;
import 'package:bagyesrushappusernew/src/report/model/report.dart';
import 'package:bagyesrushappusernew/src/report/viewmodel/my_reports_viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/views/report_flow_args.dart';
import 'package:bagyesrushappusernew/src/report/widgets/report_card.dart';

enum _ReportFilter { open, resolved, all }

bool _isOpen(Report r) =>
    r.status == ReportStatus.pending || r.status == ReportStatus.inReview;
bool _isClosed(Report r) =>
    r.status == ReportStatus.resolved || r.status == ReportStatus.dismissed;

/// The primary "Report a Problem" destination — a history of past reports
/// with a way to start a new one, mirroring the "Help" hub pattern in
/// Uber Eats/DoorDash.
class MyReportsView extends StatefulWidget {
  final ReportRole role;

  const MyReportsView({super.key, required this.role});

  @override
  State<MyReportsView> createState() => _MyReportsViewState();
}

class _MyReportsViewState extends State<MyReportsView> with RouteAware {
  late final MyReportsViewModel _vm;
  _ReportFilter _filter = _ReportFilter.open;

  @override
  void initState() {
    super.initState();
    _vm = sl<MyReportsViewModel>(param1: widget.role);
    _vm.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Fires when a route pushed on top of this one (the report wizard, a
  /// report's detail screen) is popped and this screen is visible again —
  /// e.g. a just-submitted report, or a status change, shows up immediately
  /// instead of waiting for a manual pull-to-refresh.
  @override
  void didPopNext() => _vm.refresh();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = _vm.state;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: switch (state) {
          MyReportsLoading() =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          MyReportsError(:final message) => Column(
              children: [
                _Header(w: w, role: widget.role, openCount: 0, resolvedThisWeek: 0),
                Expanded(
                  child: _ErrorState(
                    w: w,
                    message: message,
                    onRetry: _vm.refresh,
                  ),
                ),
              ],
            ),
          MyReportsLoaded(:final reports) => _Loaded(
              w: w,
              role: widget.role,
              reports: reports,
              filter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
              onRefresh: _vm.refresh,
            ),
        },
      ),
    );
  }
}

// ─── Loaded body ────────────────────────────────────────────────────────────

class _Loaded extends StatelessWidget {
  final double w;
  final ReportRole role;
  final List<Report> reports;
  final _ReportFilter filter;
  final ValueChanged<_ReportFilter> onFilterChanged;
  final Future<void> Function() onRefresh;

  const _Loaded({
    required this.w,
    required this.role,
    required this.reports,
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final open = reports.where(_isOpen).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final resolved = reports.where((r) => r.status == ReportStatus.resolved).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final closed = reports.where(_isClosed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final resolvedThisWeek = reports
        .where((r) =>
            r.status == ReportStatus.resolved &&
            DateTime.now().difference(r.createdAt).inDays <= 7)
        .length;

    final List<Report> waitingSection;
    final List<Report> closedSection;
    switch (filter) {
      case _ReportFilter.open:
        waitingSection = open;
        closedSection = const [];
      case _ReportFilter.resolved:
        waitingSection = const [];
        closedSection = resolved;
      case _ReportFilter.all:
        waitingSection = open;
        closedSection = closed;
    }

    final isEmpty = waitingSection.isEmpty && closedSection.isEmpty;

    return Column(
      children: [
        _Header(
          w: w,
          role: role,
          openCount: open.length,
          resolvedThisWeek: resolvedThisWeek,
          filter: filter,
          onFilterChanged: onFilterChanged,
        ),
        Expanded(
          child: isEmpty
              ? _EmptyState(w: w, role: role, filter: filter)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: onRefresh,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.06),
                    children: [
                      if (waitingSection.isNotEmpty) ...[
                        _SectionLabel('Waiting on us', w: w),
                        SizedBox(height: w * 0.03),
                        for (final r in waitingSection) ...[
                          ReportCard(
                            report: r,
                            onTap: () =>
                                AppNavigator.toReportDetail(context, r.id, role: role),
                          ),
                          SizedBox(height: w * 0.03),
                        ],
                        SizedBox(height: w * 0.02),
                      ],
                      if (closedSection.isNotEmpty) ...[
                        _SectionLabel('Closed', w: w),
                        SizedBox(height: w * 0.03),
                        for (final r in closedSection) ...[
                          ReportCard(
                            report: r,
                            onTap: () =>
                                AppNavigator.toReportDetail(context, r.id, role: role),
                          ),
                          SizedBox(height: w * 0.03),
                        ],
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double w;
  final ReportRole role;
  final int openCount;
  final int resolvedThisWeek;
  final _ReportFilter filter;
  final ValueChanged<_ReportFilter>? onFilterChanged;

  const _Header({
    required this.w,
    required this.role,
    required this.openCount,
    required this.resolvedThisWeek,
    this.filter = _ReportFilter.open,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.025, w * 0.05, w * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: EdgeInsets.all(w * 0.022),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft02,
                    color: AppColors.textPrimary,
                    size: w * 0.05,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => AppNavigator.toReportFlow(
                  context,
                  args: ReportFlowArgs(role: role),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.035,
                    vertical: w * 0.022,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(w * 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: w * 0.04,
                      ),
                      SizedBox(width: w * 0.015),
                      Text(
                        'New report',
                        style: TextStyle(
                          fontSize: w * 0.033,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.045),
          Text(
            'My reports',
            style: TextStyle(
              fontSize: w * 0.075,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          SizedBox(height: w * 0.012),
          Text(
            '$openCount open · $resolvedThisWeek resolved this week',
            style: TextStyle(
              fontSize: w * 0.034,
              color: AppColors.textSecondary,
            ),
          ),
          if (onFilterChanged != null) ...[
            SizedBox(height: w * 0.045),
            Row(
              children: [
                _FilterChip(
                  label: 'Open',
                  count: openCount,
                  selected: filter == _ReportFilter.open,
                  onTap: () => onFilterChanged!(_ReportFilter.open),
                  w: w,
                ),
                SizedBox(width: w * 0.025),
                _FilterChip(
                  label: 'Resolved',
                  selected: filter == _ReportFilter.resolved,
                  onTap: () => onFilterChanged!(_ReportFilter.resolved),
                  w: w,
                ),
                SizedBox(width: w * 0.025),
                _FilterChip(
                  label: 'All',
                  selected: filter == _ReportFilter.all,
                  onTap: () => onFilterChanged!(_ReportFilter.all),
                  w: w,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final double w;

  const _FilterChip({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.022),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(w * 0.06),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          count != null ? '$label · $count' : label,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final double w;
  const _SectionLabel(this.label, {required this.w});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: w * 0.03,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.6,
      ),
    );
  }
}

// ─── Empty / error states ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final double w;
  final ReportRole role;
  final _ReportFilter filter;
  const _EmptyState({required this.w, required this.role, required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ReportFilter.open => 'Nothing waiting on us right now.',
      _ReportFilter.resolved => 'No resolved reports yet.',
      _ReportFilter.all =>
        'If something goes wrong with a vendor, rider, or order, you can report it here.',
    };

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
              'No reports here',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
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
