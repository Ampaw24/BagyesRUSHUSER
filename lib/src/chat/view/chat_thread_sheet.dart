import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/phone_launcher.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/view/chat_thread_args.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/chat_avatar.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/chat_composer.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/chat_day_separator.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/chat_dimensions.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/message_bubble.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/message_grouping.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/quick_actions_grid.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/typing_bubble.dart';
import 'package:bagyesrushappusernew/src/chat/viewmodel/chat_thread_viewmodel.dart';

/// Presents a conversation thread as a draggable bottom sheet over whatever
/// screen is already on-screen (the live order-tracking map, the inbox
/// list, …) instead of navigating to a new full page — the order/map
/// context underneath stays reachable by dragging the sheet down, matching
/// how Uber Eats/Bolt Food surface order chat rather than a standalone
/// messaging app.
class ChatThreadSheet {
  ChatThreadSheet._();

  static Future<void> show(BuildContext context, {required ChatThreadArgs args}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatThreadSheetBody(args: args),
    );
  }
}

class _ChatThreadSheetBody extends StatefulWidget {
  const _ChatThreadSheetBody({required this.args});

  final ChatThreadArgs args;

  @override
  State<_ChatThreadSheetBody> createState() => _ChatThreadSheetBodyState();
}

class _ChatThreadSheetBodyState extends State<_ChatThreadSheetBody> {
  late final ChatThreadViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<ChatThreadViewModel>(param1: widget.args);
    _vm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final state = _vm.state;
    final loaded = state is ChatThreadLoaded ? state : null;
    final counterpart = loaded?.conversation.counterpart;
    final peerName = counterpart?.name ?? widget.args.peerName ?? 'Chat';
    final isOpen = loaded?.conversation.isOpen ?? false;
    final quickReplies = loaded?.conversation.quickReplies ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.69,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.07)),
          child: ColoredBox(
            color: AppColors.surfaceVariant,
            child: Column(
              children: [
                _SheetHeader(
                  args: widget.args,
                  state: state,
                  peerName: peerName,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (state) {
                      ChatThreadLoading() => const Center(
                          key: ValueKey('loading'),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ChatThreadError(:final message) => _ErrorState(
                          key: const ValueKey('error'),
                          w: w,
                          message: message,
                          onRetry: _vm.retryLoad,
                        ),
                      ChatThreadUnavailable(:final message) => _UnavailableState(
                          key: const ValueKey('unavailable'),
                          w: w,
                          message: message,
                          onRetry: _vm.retryLoad,
                        ),
                      ChatThreadLoaded() => _MessageList(
                          key: const ValueKey('messages'),
                          scrollController: scrollController,
                          messages: state.messages,
                          isLoadingOlder: state.isLoadingOlder,
                          peerReadAt: state.peerReadAt,
                          peerTyping: state.peerTyping,
                          peerName: peerName,
                          peerRole: counterpart?.role,
                          peerPhotoUrl: widget.args.peerPhotoUrl,
                          onRetryMessage: _vm.retry,
                          onLoadOlder: _vm.loadOlderMessages,
                        ),
                    },
                  ),
                ),
                if (isOpen && quickReplies.isNotEmpty)
                  ColoredBox(
                    color: AppColors.card,
                    child: QuickActionsGrid(
                      replies: quickReplies,
                      onSelected: _vm.sendMessage,
                    ),
                  ),
                ChatComposer(
                  enabled: isOpen,
                  hintText: 'Message ${peerName.split(' ').first}…',
                  onSend: _vm.sendMessage,
                  onTyping: _vm.notifyTyping,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drag handle, peer avatar + name, a subtitle that swaps to a live
/// "typing…" state, and call / close actions.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.args,
    required this.state,
    required this.peerName,
  });

  final ChatThreadArgs args;
  final ChatThreadState state;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    // Copied to a local so `is`-promotion applies — a public instance field
    // like `state` is never promotable.
    final currentState = state;
    final loaded = currentState is ChatThreadLoaded ? currentState : null;
    final counterpart = loaded?.conversation.counterpart;
    final order = loaded?.conversation.order;
    final peerTyping = loaded?.peerTyping ?? false;
    final subtitle = [
      if (counterpart != null) counterpart.roleLabel,
      if (order != null) order.orderNumber,
    ].join(' · ');
    final phone = args.peerPhone?.trim() ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.035, w * 0.03),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.025),
            child: Container(
              width: w * 0.1,
              height: w * 0.011,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(w),
              ),
            ),
          ),
          Row(
            children: [
              ChatAvatar(
                name: peerName,
                photoUrl: args.peerPhotoUrl,
                role: counterpart?.role,
                size: w * 0.12,
                showRoleBadge: true,
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      peerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: w * 0.043,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        peerTyping ? 'typing…' : subtitle,
                        key: ValueKey(peerTyping),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.03,
                          fontWeight:
                              peerTyping ? FontWeight.w600 : FontWeight.w400,
                          color: peerTyping
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (phone.isNotEmpty) ...[
                _HeaderAction(
                  icon: HugeIcons.strokeRoundedCall02,
                  tooltip: 'Call',
                  background: AppColors.primary.withValues(alpha: 0.1),
                  foreground: AppColors.primary,
                  onTap: () => launchPhoneCall(context, phone),
                ),
                SizedBox(width: w * 0.02),
              ],
              _HeaderAction(
                icon: HugeIcons.strokeRoundedCancel01,
                tooltip: 'Close',
                background: AppColors.surfaceVariant,
                foreground: AppColors.textSecondary,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = chatScaleWidth(context) * 0.1;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: HugeIcon(icon: icon, color: foreground, size: size * 0.48),
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns the scroll-position listener that triggers older-page pagination —
/// isolated into its own [State] so it attaches to [scrollController]
/// exactly once for the sheet's lifetime, regardless of how often the
/// parent rebuilds on view-model changes. Disposal of [scrollController]
/// itself belongs to the enclosing [DraggableScrollableSheet], not here.
///
/// Also decides which bubbles animate in: only messages that arrive while
/// the thread is open, never history or older pages.
class _MessageList extends StatefulWidget {
  const _MessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isLoadingOlder,
    required this.peerReadAt,
    required this.peerTyping,
    required this.peerName,
    required this.peerRole,
    required this.peerPhotoUrl,
    required this.onRetryMessage,
    required this.onLoadOlder,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isLoadingOlder;
  final DateTime? peerReadAt;
  final bool peerTyping;
  final String peerName;
  final String? peerRole;
  final String? peerPhotoUrl;
  final ValueChanged<ChatMessage> onRetryMessage;
  final VoidCallback onLoadOlder;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  static const _scrollDuration = Duration(milliseconds: 300);

  /// Messages already on screen (or already animated) — keyed by
  /// `client_uuid` when present so an optimistic bubble and its confirmed
  /// server row count as the same message.
  final Set<String> _seenKeys = {};
  DateTime? _newestAtOpen;
  bool _showJumpToLatest = false;

  @override
  void initState() {
    super.initState();
    _seenKeys.addAll(widget.messages.map(_keyOf));
    _newestAtOpen =
        widget.messages.isEmpty ? null : widget.messages.last.createdAt;
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newest = widget.messages.isEmpty ? null : widget.messages.last;
    final previous = oldWidget.messages.isEmpty ? null : oldWidget.messages.last;
    // Sending always brings you back to the latest message.
    if (newest != null &&
        newest.isMine &&
        _keyOf(newest) != (previous == null ? null : _keyOf(previous))) {
      _jumpToLatest();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  String _keyOf(ChatMessage message) => message.clientUuid ?? message.id;

  bool _shouldAnimate(ChatMessage message) {
    if (!_seenKeys.add(_keyOf(message))) return false;
    final newestAtOpen = _newestAtOpen;
    return newestAtOpen == null || message.createdAt.isAfter(newestAtOpen);
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      widget.onLoadOlder();
    }
    final showJump = position.pixels > chatScaleWidth(context) * 0.8;
    if (showJump != _showJumpToLatest) {
      setState(() => _showJumpToLatest = showJump);
    }
  }

  void _jumpToLatest() {
    final controller = widget.scrollController;
    if (!controller.hasClients || controller.offset <= 0) return;
    controller.animateTo(0, duration: _scrollDuration, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    if (widget.messages.isEmpty && !widget.peerTyping) {
      return _EmptyThread(
        peerName: widget.peerName,
        peerRole: widget.peerRole,
        peerPhotoUrl: widget.peerPhotoUrl,
      );
    }

    final descending = widget.messages.reversed.toList();
    final typingSlots = widget.peerTyping ? 1 : 0;
    final itemCount =
        typingSlots + descending.length + (widget.isLoadingOlder ? 1 : 0);

    return Stack(
      children: [
        ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          padding: EdgeInsets.fromLTRB(w * 0.035, w * 0.02, w * 0.04, w * 0.03),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < typingSlots) {
              return _TypingRow(
                peerName: widget.peerName,
                peerPhotoUrl: widget.peerPhotoUrl,
              );
            }
            final i = index - typingSlots;
            if (i >= descending.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: w * 0.03),
                child: Center(
                  child: SizedBox.square(
                    dimension: w * 0.05,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }

            // `descending` is newest-first: i + 1 is the message above.
            final message = descending[i];
            final older = i + 1 < descending.length ? descending[i + 1] : null;
            final newer = i > 0 ? descending[i - 1] : null;
            final startsDay = older == null ||
                !isSameChatDay(older.createdAt, message.createdAt);
            final peerReadAt = widget.peerReadAt;
            final isRead = message.isMine &&
                peerReadAt != null &&
                !message.createdAt.isAfter(peerReadAt);

            final bubble = MessageBubble(
              message: message,
              peerName: widget.peerName,
              peerPhotoUrl: widget.peerPhotoUrl,
              isRead: isRead,
              isFirstInGroup:
                  startsDay || !isSameMessageGroup(older, message),
              isLastInGroup:
                  newer == null || !isSameMessageGroup(message, newer),
              animateIn: _shouldAnimate(message),
              onRetry: message.deliveryStatus == MessageDeliveryStatus.failed
                  ? () => widget.onRetryMessage(message)
                  : null,
            );
            if (!startsDay) return bubble;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [ChatDaySeparator(date: message.createdAt), bubble],
            );
          },
        ),
        Positioned(
          right: w * 0.04,
          bottom: w * 0.03,
          child: AnimatedScale(
            scale: _showJumpToLatest ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: _JumpToLatestButton(onTap: _jumpToLatest),
          ),
        ),
      ],
    );
  }
}

/// Peer avatar + animated dots, pinned below the newest message while the
/// other side is typing.
class _TypingRow extends StatelessWidget {
  const _TypingRow({required this.peerName, required this.peerPhotoUrl});

  final String peerName;
  final String? peerPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final avatarSize = w * peerAvatarSizeFactor;

    return Padding(
      padding: EdgeInsets.only(top: w * 0.025),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * w * 0.03),
            child: child,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ChatAvatar(name: peerName, photoUrl: peerPhotoUrl, size: avatarSize),
            SizedBox(width: w * 0.02),
            const TypingBubble(),
          ],
        ),
      ),
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = chatScaleWidth(context) * 0.1;

    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.divider)),
      elevation: 2,
      shadowColor: AppColors.secondary.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: size * 0.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Fresh thread: the peer's avatar and a nudge to say hello.
class _EmptyThread extends StatelessWidget {
  const _EmptyThread({
    required this.peerName,
    required this.peerRole,
    required this.peerPhotoUrl,
  });

  final String peerName;
  final String? peerRole;
  final String? peerPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (_, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatAvatar(
                name: peerName,
                photoUrl: peerPhotoUrl,
                role: peerRole,
                size: w * 0.2,
                showRoleBadge: true,
              ),
              SizedBox(height: w * 0.04),
              Text(
                'Say hello to ${peerName.split(' ').first} 👋',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.015),
              Text(
                'Messages here are about this order only.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.032,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    super.key,
    required this.w,
    required this.message,
    required this.onRetry,
  });

  final double w;
  final String message;
  final VoidCallback onRetry;

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
              "Couldn't load this conversation",
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

/// Shown instead of [_ErrorState] when the REST fetch behind this thread
/// returned a [ConversationNotAvailableException] (422) — a rider hasn't
/// been assigned to this order yet, not a broken thread. Unlike a real
/// error this can resolve itself while the sheet stays open, so the retry
/// action reads as "check again" rather than "retry".
class _UnavailableState extends StatelessWidget {
  const _UnavailableState({
    super.key,
    required this.w,
    required this.message,
    required this.onRetry,
  });

  final double w;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              size: w * 0.14,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'Chat not available yet',
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
            OutlinedButton(onPressed: onRetry, child: const Text('Check again')),
          ],
        ),
      ),
    );
  }
}
