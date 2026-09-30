import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'chat_dimensions.dart';

/// The message input bar — owns its own [TextEditingController] so the
/// parent view only needs [onSend] (called with the trimmed body, already
/// cleared from the field) and [onTyping] (fired on every keystroke, for the
/// view model's throttled `typing` signal). Enforces the API's 2000-char
/// cap directly on the field so a send never round-trips a 422 for length.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onTyping,
    this.enabled = true,
    this.hintText = 'Type a message…',
  });

  final ValueChanged<String> onSend;
  final VoidCallback onTyping;
  final bool enabled;
  final String hintText;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onTyping();
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);

    if (!widget.enabled) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.all(w * 0.04),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: w * 0.035,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.04),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: w * 0.04,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: w * 0.02),
              Flexible(
                child: Text(
                  'This conversation is closed.',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const noBorder = InputBorder.none;

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.035, w * 0.02, w * 0.035, w * 0.025),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.05),
            blurRadius: w * 0.03,
            offset: Offset(0, -w * 0.005),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: w * 0.32),
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.06),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  cursorColor: AppColors.primary,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _onChanged,
                  style: TextStyle(
                    fontSize: w * 0.037,
                    color: AppColors.textPrimary,
                  ),
                  // Every border is spelled out so the app theme's outlined
                  // input style doesn't draw a box inside the pill.
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: w * 0.036,
                      color: AppColors.textHint,
                    ),
                    filled: false,
                    border: noBorder,
                    enabledBorder: noBorder,
                    focusedBorder: noBorder,
                    disabledBorder: noBorder,
                    errorBorder: noBorder,
                    focusedErrorBorder: noBorder,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: w * 0.03),
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.025),
            _SendButton(enabled: _hasText, onPressed: _handleSend),
          ],
        ),
      ),
    );
  }
}

/// Grey and inert while the field is empty; springs to the brand colour
/// with a slight pop once there is something to send.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final size = w * 0.115;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Send message',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedScale(
          scale: enabled ? 1 : 0.9,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primary : AppColors.border,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: w * 0.03,
                        offset: Offset(0, w * 0.008),
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedRotation(
              turns: enabled ? 0 : -0.125,
              duration: const Duration(milliseconds: 220),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSent,
                color: Colors.white,
                size: size * 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
