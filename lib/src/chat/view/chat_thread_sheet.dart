import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/phone_launcher.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'package:bagyesrushappusernew/src/chat/view/chat_thread_args.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/chat_composer.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/message_bubble.dart';
import 'package:bagyesrushappusernew/src/chat/view/widgets/quick_actions_grid.dart';
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
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final state = _vm.state;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
            ),
            child: Column(
              children: [
                _DragHandle(w: w),
                _SheetHeader(
                  w: w,
                  args: widget.args,
                  state: state,
                  peerTyping: state is ChatThreadLoaded && state.peerTyping,
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: switch (state) {
                    ChatThreadLoading() =>
                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    ChatThreadError(:final message) =>
                      _ErrorState(w: w, message: message, onRetry: _vm.retryLoad),
                    ChatThreadUnavailable(:final message) =>
                      _UnavailableState(w: w, message: message, onRetry: _vm.retryLoad),
                    ChatThreadLoaded(:final messages, :final isLoadingOlder, :final peerReadAt) =>
                      _MessageList(
                        w: w,
                        scrollController: scrollController,
                        messages: messages,
                        isLoadingOlder: isLoadingOlder,
                        peerReadAt: peerReadAt,
                        onRetryMessage: _vm.retry,
                        onLoadOlder: _vm.loadOlderMessages,
                      ),
                  },
                ),
                if (state is ChatThreadLoaded &&
                    state.conversation.isOpen &&
                    state.conversation.quickReplies.isNotEmpty)
                  QuickActionsGrid(
                    replies: state.conversation.quickReplies,
                    onSelected: _vm.sendMessage,
                  ),
                ChatComposer(
                  enabled: state is ChatThreadLoaded && state.conversation.isOpen,
                  onSend: _vm.sendMessage,
                  onTyping: _vm.notifyTyping,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.025),
      child: Container(
        width: w * 0.1,
        height: w * 0.011,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(w * 0.01),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.w,
    required this.args,
    required this.state,
    required this.peerTyping,
  });

  final double w;
  final ChatThreadArgs args;
  final ChatThreadState state;
  final bool peerTyping;

  @override
  Widget build(BuildContext context) {
    // Copied to a local so `is`-promotion applies — a public instance field
    // like `state` is never promotable.
    final currentState = state;
    final counterpart =
        currentState is ChatThreadLoaded ? currentState.conversation.counterpart : null;
    final title = counterpart?.name ?? args.peerName ?? 'Chat';
    final order = currentState is ChatThreadLoaded ? currentState.conversation.order : null;
    final subtitleParts = <String>[
      if (counterpart != null) counterpart.roleLabel,
      if (order != null) order.orderNumber,
    ];
    final subtitle = peerTyping ? 'typing…' : subtitleParts.join(' · ');
    final phone = args.peerPhone;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.01, w * 0.03, w * 0.03),
      child: Row(
        children: [
          Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              title.isNotEmpty ? title[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.029,
                      fontStyle: peerTyping ? FontStyle.italic : FontStyle.normal,
                      color: peerTyping ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null && phone.trim().isNotEmpty)
            IconButton(
              onPressed: () => launchPhoneCall(context, phone),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCall,
                color: AppColors.primary,
                size: w * 0.052,
              ),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded, color: AppColors.textHint, size: w * 0.06),
          ),
        ],
      ),
    );
  }
}

/// Owns the scroll-position listener that triggers older-page pagination —
/// isolated into its own [State] so it attaches to [scrollController]
/// exactly once for the sheet's lifetime, regardless of how often the
/// parent rebuilds on view-model changes. Disposal of [scrollController]
/// itself belongs to the enclosing [DraggableScrollableSheet], not here.
class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.w,
    required this.scrollController,
    required this.messages,
    required this.isLoadingOlder,
    required this.peerReadAt,
    required this.onRetryMessage,
    required this.onLoadOlder,
  });

  final double w;
  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isLoadingOlder;
  final DateTime? peerReadAt;
  final ValueChanged<ChatMessage> onRetryMessage;
  final VoidCallback onLoadOlder;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      widget.onLoadOlder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          'Say hello 👋',
          style: TextStyle(fontSize: w * 0.036, color: AppColors.textHint),
        ),
      );
    }

    final descending = widget.messages.reversed.toList();
    final itemCount = descending.length + (widget.isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= descending.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }
        final message = descending[index];
        final peerReadAt = widget.peerReadAt;
        final isRead = message.isMine &&
            peerReadAt != null &&
            !message.createdAt.isAfter(peerReadAt);
        return MessageBubble(
          message: message,
          isRead: isRead,
          onRetry: message.deliveryStatus == MessageDeliveryStatus.failed
              ? () => widget.onRetryMessage(message)
              : null,
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.w, required this.message, required this.onRetry});

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
  const _UnavailableState({required this.w, required this.message, required this.onRetry});

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
