import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum DialogType { success, error, confirmation, info, warning }

class CustomDialogConfig {
  final String title;
  final String subtitle;
  final DialogType type;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;
  final bool showCancelButton;
  final Color? customColor;
  final Widget? content;
  final bool barrierDismissible;

  CustomDialogConfig({
    required this.title,
    required this.subtitle,
    this.type = DialogType.info,
    this.onConfirm,
    this.onCancel,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
    this.showCancelButton = false,
    this.customColor,
    this.content,
    this.barrierDismissible = false,
  });
}

class CustomDialog extends StatefulWidget {
  final CustomDialogConfig config;

  const CustomDialog({super.key, required this.config});

  @override
  State<CustomDialog> createState() => _CustomDialogState();

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.success,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.error,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.confirmation,
          onConfirm: onConfirm,
          onCancel: onCancel,
          confirmText: confirmText,
          cancelText: cancelText,
          showCancelButton: true,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.warning,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String subtitle,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          type: DialogType.info,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }
}

class _CustomDialogState extends State<CustomDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Per-type colour ──────────────────────────────────────────────────────

  Color _color() {
    if (widget.config.customColor != null) return widget.config.customColor!;
    switch (widget.config.type) {
      case DialogType.error:
        return const Color(0xFFE53935);
      case DialogType.success:
        return const Color(0xFF2E7D32);
      case DialogType.warning:
        return const Color(0xFFE65100);
      case DialogType.confirmation:
        return const Color(0xFF5C35D4);
      case DialogType.info:
        return const Color(0xFF0056D2);
    }
  }

  // ── Per-type HugeIcon ────────────────────────────────────────────────────

  List<List<dynamic>> _icon() {
    switch (widget.config.type) {
      case DialogType.error:
        return HugeIcons.strokeRoundedAlertCircle;
      case DialogType.success:
        return HugeIcons.strokeRoundedCheckmarkCircle01;
      case DialogType.warning:
        return HugeIcons.strokeRoundedAlert01;
      case DialogType.confirmation:
        return HugeIcons.strokeRoundedHelpCircle;
      case DialogType.info:
        return HugeIcons.strokeRoundedInformationCircle;
    }
  }

  // ── Button handlers ──────────────────────────────────────────────────────

  void _handleConfirm() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.config.onConfirm?.call();
    });
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.config.onCancel?.call();
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final sw     = mq.size.width;
    final sh     = mq.size.height;
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: widget.config.barrierDismissible,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.06,
            vertical: sh * 0.02,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: sw * 0.85,
                  maxHeight: sh * 0.52,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(sw * 0.045),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: sw * 0.05,
                      offset: Offset(0, sw * 0.02),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.055,
                    vertical: sh * 0.022,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconBadge(sw),
                      SizedBox(height: sh * 0.016),
                      Text(
                        widget.config.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: sw * 0.046,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: sh * 0.009),
                      Text(
                        widget.config.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: sw * 0.034,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.config.content != null) ...[
                        SizedBox(height: sh * 0.015),
                        widget.config.content!,
                      ],
                      SizedBox(height: sh * 0.024),
                      _buildButtons(sw, sh, theme, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(double sw) {
    final badgeSize = sw * 0.155;
    final iconSize  = sw * 0.075;
    final accent    = _color();

    return Container(
      width:  badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
          width: sw * 0.004,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: _icon(),
          size: iconSize,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildButtons(double sw, double sh, ThemeData theme, bool isDark) {
    if (widget.config.showCancelButton) {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              text: widget.config.cancelText,
              onPressed: _handleCancel,
              isPrimary: false,
              sw: sw, sh: sh, theme: theme, isDark: isDark,
            ),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: _buildButton(
              text: widget.config.confirmText,
              onPressed: _handleConfirm,
              isPrimary: true,
              sw: sw, sh: sh, theme: theme, isDark: isDark,
            ),
          ),
        ],
      );
    }
    return _buildButton(
      text: widget.config.confirmText,
      onPressed: _handleConfirm,
      isPrimary: true,
      sw: sw, sh: sh, theme: theme, isDark: isDark,
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required double sw,
    required double sh,
    required ThemeData theme,
    required bool isDark,
  }) {
    final accent = _color();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(sw * 0.03),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: sh * 0.013,
            horizontal: sw * 0.04,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? accent
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(sw * 0.03),
            border: Border.all(
              color: isPrimary
                  ? accent
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
              width: sw * 0.003,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: sw * 0.038,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
