import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../providers/consumer_notification_provider.dart';
import '../../providers/consumer_chat_provider.dart';
import '../../models/consumer_conversation.dart';
import '../widgets/consumer_notification_tile.dart';
import '../widgets/consumer_conversation_tile.dart';
import 'consumer_chat_screen.dart';
import '../../../../../../src/vendor/features/notifications/view/widgets/animated_tab_switcher.dart';

class ConsumerNotificationsScreen extends ConsumerStatefulWidget {
  const ConsumerNotificationsScreen({super.key});

  @override
  ConsumerState<ConsumerNotificationsScreen> createState() =>
      _ConsumerNotificationsScreenState();
}

class _ConsumerNotificationsScreenState
    extends ConsumerState<ConsumerNotificationsScreen>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(consumerNotificationProvider);
    final chatState = ref.watch(consumerChatProvider);
    final w = MediaQuery.sizeOf(context).width;

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
                  onMarkAllRead: _tabIndex == 0
                      ? () => ref
                            .read(consumerNotificationProvider.notifier)
                            .markAllRead()
                      : null,
                ),
              ),

              SizedBox(height: w * 0.04),

              // ── Tab switcher ─────────────────────────────────────────
              AnimatedTabSwitcher(
                selectedIndex: _tabIndex,
                labels: const ['Notifications', 'Messages'],
                badgeCounts: [
                  notifState.unreadCount,
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
                          notifState: notifState,
                          onTap: (id) => ref
                              .read(consumerNotificationProvider.notifier)
                              .markRead(id),
                        )
                      : _MessagesTab(
                          key: const ValueKey('msgs'),
                          chatState: chatState,
                          onConversationTap: (conv) {
                            ref
                                .read(consumerChatProvider.notifier)
                                .markConversationRead(conv.id);
                            Navigator.of(context).push(
                              _slideRoute(
                                ConsumerChatScreen(conversationId: conv.id),
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
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

// ─── Header ──────────────────────────────────────────────────────────────────

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
  final ConsumerNotificationState notifState;
  final ValueChanged<String> onTap;

  const _NotificationsTab({
    super.key,
    required this.notifState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (notifState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (notifState.notifications.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedNotification01,
        message: 'No notifications yet',
        subtitle: 'Order updates and offers will appear here',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: w * 0.06),
      itemCount: notifState.notifications.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.5,
        indent: w * 0.18,
        endIndent: 0,
        color: AppColors.divider,
      ),
      itemBuilder: (_, i) {
        final notif = notifState.notifications[i];
        return ConsumerNotificationTile(
          notification: notif,
          onTap: () => onTap(notif.id),
        );
      },
    );
  }
}

// ─── Messages tab ────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  final ConsumerChatState chatState;
  final ValueChanged<ConsumerConversation> onConversationTap;

  const _MessagesTab({
    super.key,
    required this.chatState,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (chatState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (chatState.conversations.isEmpty) {
      return _EmptyState(
        icon: HugeIcons.strokeRoundedMessage01,
        message: 'No messages yet',
        subtitle: 'Chat with restaurants and riders here',
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
        return ConsumerConversationTile(
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
            decoration: const BoxDecoration(
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
