import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../models/consumer_chat_message.dart';
import '../../providers/consumer_chat_provider.dart';

class ConsumerChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConsumerChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ConsumerChatScreen> createState() =>
      _ConsumerChatScreenState();
}

class _ConsumerChatScreenState extends ConsumerState<ConsumerChatScreen>
    with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    ref
        .read(consumerChatProvider.notifier)
        .sendMessage(widget.conversationId, text);
    _textCtrl.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(consumerChatProvider);
    final conversation = chatState.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => chatState.conversations.first,
    );
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        resizeToAvoidBottomInset: true,
        body: FadeTransition(
          opacity: _entryAnim,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: _ChatHeader(
                  name: conversation.participantName,
                  initials: conversation.participantInitials,
                  role: conversation.participantRole,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              const Divider(
                  height: 1, thickness: 0.5, color: AppColors.divider),
              // ── Messages ─────────────────────────────────────────
              Expanded(
                child: conversation.messages.isEmpty
                    ? _EmptyChatPlaceholder(
                        name: conversation.participantName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.symmetric(vertical: w * 0.04),
                        itemCount: conversation.messages.length,
                        itemBuilder: (_, i) => _ConsumerChatBubble(
                          message: conversation.messages[i],
                        ),
                      ),
              ),
              // ── Input bar ────────────────────────────────────────
              AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _ChatInputBar(
                  controller: _textCtrl,
                  focusNode: _focusNode,
                  onSend: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chat header ─────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String name;
  final String initials;
  final String? role;
  final VoidCallback? onBack;

  const _ChatHeader({
    required this.name,
    required this.initials,
    this.role,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.04, w * 0.04, w * 0.03),
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
          SizedBox(width: w * 0.03),
          CircleAvatar(
            radius: w * 0.05,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.032,
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
                  name,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (role != null)
                  Text(
                    role!,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.029,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: AppColors.textSecondary,
              size: w * 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ─────────────────────────────────────────────────────────────

class _ConsumerChatBubble extends StatelessWidget {
  final ConsumerChatMessage message;

  const _ConsumerChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMe = message.isFromMe;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? w * 0.2 : w * 0.05,
        right: isMe ? w * 0.05 : w * 0.2,
        bottom: w * 0.025,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.03,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(w * 0.04),
                topRight: Radius.circular(w * 0.04),
                bottomLeft: isMe ? Radius.circular(w * 0.04) : Radius.zero,
                bottomRight: isMe ? Radius.zero : Radius.circular(w * 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.035,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: w * 0.01),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.027,
                  color: AppColors.textHint,
                ),
              ),
              if (isMe) ...[
                SizedBox(width: w * 0.01),
                HugeIcon(
                  icon: _statusIcon(message.status),
                  size: w * 0.03,
                  color: message.status == ConsumerMessageStatus.read
                      ? AppColors.info
                      : AppColors.textHint,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<List<dynamic>> _statusIcon(ConsumerMessageStatus s) {
    return switch (s) {
      ConsumerMessageStatus.read => HugeIcons.strokeRoundedTick02,
      ConsumerMessageStatus.delivered => HugeIcons.strokeRoundedTick02,
      _ => HugeIcons.strokeRoundedClock01,
    };
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding:
          EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.025),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedAttachment01,
              size: w * 0.048,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.025,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.06),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.036,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.036,
                    color: AppColors.textHint,
                  ),
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          SizedBox(width: w * 0.025),
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: GestureDetector(
              onTap: _hasText ? widget.onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(w * 0.032),
                decoration: BoxDecoration(
                  color: _hasText ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  size: w * 0.048,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty placeholder ────────────────────────────────────────────────────────

class _EmptyChatPlaceholder extends StatelessWidget {
  final String name;
  const _EmptyChatPlaceholder({required this.name});

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
              icon: HugeIcons.strokeRoundedMessage01,
              size: w * 0.1,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: w * 0.04),
          Text(
            'Start the conversation',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Say hello to $name',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
