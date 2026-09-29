import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../../constant/app_theme.dart';
import '../../../../../../src/notification/model/notification.model.dart';
import '../../../../../../src/notification/viewmodel/notification_state.dart';
import '../../../../../../src/notification/viewmodel/notification_viewmodel.dart';
import '../../../../../../src/notification/view/widgets/notifications_body.dart';
import '../../../../../../src/notification/view/widgets/notifications_header.dart';
import 'notification_details_screen.dart';

class ConsumerNotificationsScreen extends StatefulWidget {
  const ConsumerNotificationsScreen({super.key});

  @override
  State<ConsumerNotificationsScreen> createState() =>
      _ConsumerNotificationsScreenState();
}

class _ConsumerNotificationsScreenState
    extends State<ConsumerNotificationsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  NotificationViewmodel? _vm;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm = context.read<NotificationViewmodel>();
      _vm!.addListener(_onNotifState);
      _vm!.getNotifications();
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onNotifState);
    _headerCtrl.dispose();
    super.dispose();
  }

  void _onNotifState() {
    if (!mounted) return;
    final state = _vm!.state;

    switch (state) {
      case NotificationsLoaded():
        setState(() {
          _notifications = state.notifications;
          _isLoading = false;
        });
      case NotificationMarkedRead():
        final updated = state.notification;
        setState(() {
          _notifications = _notifications
              .map((n) => n.id == updated.id ? updated : n)
              .toList();
        });
        _vm!.resetState();
      case NotificationDeleted():
        setState(() {
          _notifications =
              _notifications.where((n) => n.id != state.id).toList();
        });
        _vm!.resetState();
      case AllNotificationsMarkedRead():
        setState(() {
          _notifications =
              _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        _vm!.resetState();
      case NotificationError():
        final message = state.message;
        _vm!.resetState();
        if (_notifications.isEmpty) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      case NotificationLoading():
        if (_notifications.isEmpty) setState(() => _isLoading = true);
      case UnreadCountLoaded():
      case NotificationInitial():
        break;
    }
  }

  void _deleteNotification(NotificationModel notification) {
    _vm?.deleteNotification(notification.id, wasUnread: !notification.isRead);
  }

  void _openNotification(NotificationModel notification) {
    if (!notification.isRead) _vm?.markAsRead(notification.id);
    Navigator.of(context).push(
      _slideRoute(NotificationDetailsScreen(notification: notification)),
    );
  }

  Future<void> _refresh() => _vm?.getNotifications() ?? Future.value();

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              FadeTransition(
                opacity: _headerFade,
                child: NotificationsHeader(
                  unreadCount: _isLoading ? null : _unreadCount,
                  onBack: () => Navigator.of(context).pop(),
                  onMarkAllRead: () => _vm?.markAllAsRead(),
                ),
              ),

              SizedBox(height: w * 0.03),

              // ── Notifications ────────────────────────────────────────
              Expanded(
                child: NotificationsBody(
                  isLoading: _isLoading,
                  notifications: _notifications,
                  onTap: _openNotification,
                  onDelete: _deleteNotification,
                  onRefresh: _refresh,
                  emptySubtitle: 'Order updates and offers will appear here',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Route _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, anim, _) => page,
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}
