import 'package:flutter/material.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/notification/model/notification.model.dart';
import 'package:bagyesrushappusernew/src/notification/utils/notification_style.dart';
import 'notification_card.dart';
import 'notifications_placeholders.dart';

/// Loading / empty / list body shared by the consumer and vendor
/// notifications screens. Cross-fades between the three states.
class NotificationsBody extends StatelessWidget {
  const NotificationsBody({
    super.key,
    required this.isLoading,
    required this.notifications,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
    required this.emptySubtitle,
  });

  final bool isLoading;
  final List<NotificationModel> notifications;
  final ValueChanged<NotificationModel> onTap;
  final ValueChanged<NotificationModel> onDelete;
  final Future<void> Function() onRefresh;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (isLoading && notifications.isEmpty) {
      child = const NotificationsSkeleton(key: ValueKey('loading'));
    } else if (notifications.isEmpty) {
      child = _RefreshableEmptyState(
        key: const ValueKey('empty'),
        subtitle: emptySubtitle,
        onRefresh: onRefresh,
      );
    } else {
      child = _NotificationsList(
        key: const ValueKey('list'),
        notifications: notifications,
        onTap: onTap,
        onDelete: onDelete,
        onRefresh: onRefresh,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

// ─── Empty state (pull-to-refresh enabled) ───────────────────────────────────

class _RefreshableEmptyState extends StatelessWidget {
  const _RefreshableEmptyState({
    super.key,
    required this.subtitle,
    required this.onRefresh,
  });

  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (_, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: NotificationsEmptyState(subtitle: subtitle),
          ),
        ),
      ),
    );
  }
}

// ─── Day-sectioned list with staggered entrance ─────────────────────────────

sealed class _ListEntry {
  const _ListEntry();
}

final class _HeaderEntry extends _ListEntry {
  const _HeaderEntry(this.group);
  final NotificationDayGroup group;
}

final class _ItemEntry extends _ListEntry {
  const _ItemEntry(this.notification);
  final NotificationModel notification;
}

class _NotificationsList extends StatefulWidget {
  const _NotificationsList({
    super.key,
    required this.notifications,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
  });

  final List<NotificationModel> notifications;
  final ValueChanged<NotificationModel> onTap;
  final ValueChanged<NotificationModel> onDelete;
  final Future<void> Function() onRefresh;

  @override
  State<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<_NotificationsList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late List<_ListEntry> _entries = _buildEntries(widget.notifications);

  @override
  void didUpdateWidget(covariant _NotificationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.notifications, widget.notifications)) {
      _entries = _buildEntries(widget.notifications);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  static List<_ListEntry> _buildEntries(List<NotificationModel> items) {
    final grouped = <NotificationDayGroup, List<NotificationModel>>{};
    for (final item in items) {
      grouped
          .putIfAbsent(NotificationStyle.dayGroup(item.createdAt), () => [])
          .add(item);
    }
    return [
      for (final group in NotificationDayGroup.values)
        if (grouped[group] case final groupItems?) ...[
          _HeaderEntry(group),
          for (final item in groupItems) _ItemEntry(item),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, w * 0.06),
        itemCount: _entries.length,
        itemBuilder: (_, index) => switch (_entries[index]) {
          _HeaderEntry(:final group) => _StaggeredEntrance(
              key: ValueKey(group),
              animation: _entrance,
              index: index,
              child: _SectionLabel(group: group),
            ),
          _ItemEntry(:final notification) => _StaggeredEntrance(
              key: ValueKey(notification.id),
              animation: _entrance,
              index: index,
              child: Padding(
                padding: EdgeInsets.only(bottom: w * 0.025),
                child: NotificationCard(
                  notification: notification,
                  onTap: () => widget.onTap(notification),
                  onDelete: () => widget.onDelete(notification),
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.group});

  final NotificationDayGroup group;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.01, w * 0.03, w * 0.01, w * 0.02),
      child: Text(
        group.label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: w * 0.029,
          fontWeight: FontWeight.w700,
          letterSpacing: w * 0.002,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}

/// Fades + slides a list row in, offset by its index. Rows past
/// [_maxStaggered] share the last slot so long lists don't lag.
class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  static const int _maxStaggered = 8;
  static const double _step = 0.06;
  static const double _span = 0.45;

  @override
  Widget build(BuildContext context) {
    final start = index.clamp(0, _maxStaggered) * _step;
    final interval =
        Interval(start, start + _span, curve: Curves.easeOutCubic);
    final travel = MediaQuery.sizeOf(context).height * 0.03;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * travel),
            child: child,
          ),
        );
      },
    );
  }
}
