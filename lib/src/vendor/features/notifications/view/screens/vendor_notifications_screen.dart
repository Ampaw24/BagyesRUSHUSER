import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../../../constant/app_theme.dart';
import '../../../../../notification/model/notification.model.dart';
import '../../../../../notification/viewmodel/notification_state.dart';
import '../../../../../notification/viewmodel/notification_viewmodel.dart';
import '../../providers/chat_provider.dart';
import '../widgets/animated_tab_switcher.dart';
import '../widgets/notification_tile.dart';
import '../widgets/conversation_tile.dart';
import 'vendor_chat_screen.dart';
import 'vendor_notification_details_screen.dart';

/// Vendor Notifications Screen.
/// Hosts Notifications and Messages tabs with animated switching.
class VendorNotificationsScreen extends ConsumerStatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  ConsumerState<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState
    extends ConsumerState<VendorNotificationsScreen>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
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
    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOut,
    );

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
      _slideRoute(VendorNotificationDetailsScreen(notification: notification)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final w = MediaQuery.sizeOf(context).width;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              FadeTransition(
                opacity: _headerFade,
                child: _NotifHeader(
                  onBack: () => Navigator.of(context).pop(),
                  onMarkAllRead:
                      _tabIndex == 0 ? () => _vm?.markAllAsRead() : null,
                ),
              ),

              SizedBox(height: w * 0.04),

              // ── Tab switcher ─────────────────────────────────────────
              AnimatedTabSwitcher(
                selectedIndex: _tabIndex,
                labels: const ['Notifications', 'Messages'],
                badgeCounts: [
                  unreadCount,
                  chatState.totalUnread,
                ],
                onTabChanged: (i) => setState(() => _tabIndex = i),
              ),

              SizedBox(height: w * 0.02),

              // ── Tab content ──────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  ),
                  child: _tabIndex == 0
                      ? _NotificationsTab(
                          key: const ValueKey('notif'),
                          isLoading: _isLoading,
                          notifications: _notifications,
                          onTap: _openNotification,
                          onDelete: _deleteNotification,
                        )
                      : _MessagesTab(
                          key: const ValueKey('msgs'),
                          chatState: chatState,
                          onConversationTap: (conv) {
                            ref
                                .read(chatProvider.notifier)
                                .markConversationRead(conv.id);
                            Navigator.of(context).push(
                              _slideRoute(
                                VendorChatScreen(conversationId: conv.id),
                              ),
                            );
                          },
                        ),
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
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _NotifHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMarkAllRead;

  const _NotifHeader({this.onBack, this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: EdgeInsets.all(w * 0.022),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft02,
                color: AppColors.textPrimary,
                size: w * 0.055,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (onMarkAllRead != null)
            GestureDetector(
              onTap: onMarkAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.031,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Notifications tab ───────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final ValueChanged<NotificationModel> onTap;
  final ValueChanged<NotificationModel> onDelete;

  const _NotificationsTab({
    super.key,
    required this.isLoading,
    required this.notifications,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (isLoading && notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifications.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedNotification01,
        message: 'No notifications yet',
        subtitle: 'Activity updates will appear here',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: w * 0.06),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        indent: w * 0.18,
        endIndent: 0,
        color: AppColors.divider,
      ),
      itemBuilder: (_, i) {
        final notif = notifications[i];
        return NotificationTile(
          notification: notif,
          onTap: () => onTap(notif),
          onDelete: () => onDelete(notif),
        );
      },
    );
  }
}

// ─── Messages tab ────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  final ChatState chatState;
  final ValueChanged<dynamic> onConversationTap;

  const _MessagesTab({
    super.key,
    required this.chatState,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chatState.conversations.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedMessage01,
        message: 'No messages yet',
        subtitle: 'Conversations with customers will appear here',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: w * 0.06),
      itemCount: chatState.conversations.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        indent: w * 0.18,
        endIndent: 0,
        color: AppColors.divider,
      ),
      itemBuilder: (_, i) {
        final conv = chatState.conversations[i];
        return ConversationTile(
          conversation: conv,
          onTap: () => onConversationTap(conv),
        );
      },
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: icon,
              size: w * 0.1,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: w * 0.04),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
