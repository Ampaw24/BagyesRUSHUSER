import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Enum for dialog types
enum DialogType { success, error, confirmation, info, warning }

/// Model class for dialog configuration
class CustomDialogConfig {
  final String title;
  final String subtitle;
  final String iconPath;
  final bool isLottie;
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
    required this.iconPath,
    this.isLottie = false,
    this.type = DialogType.info,
    this.onConfirm,
    this.onCancel,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.showCancelButton = false,
    this.customColor,
    this.content,
    this.barrierDismissible = false,
  });
}

/// Main Custom Dialog Widget
class CustomDialog extends StatefulWidget {
  final CustomDialogConfig config;

  const CustomDialog({super.key, required this.config});

  @override
  State<CustomDialog> createState() => _CustomDialogState();

  /// Static method to show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    bool isLottie = true,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          isLottie: isLottie,
          type: DialogType.success,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  /// Static method to show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    bool isLottie = true,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          isLottie: isLottie,
          type: DialogType.error,
          onConfirm: onConfirm,
          confirmText: confirmText,
          barrierDismissible: barrierDismissible,
        ),
      ),
    );
  }

  /// Static method to show confirmation dialog
  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    bool isLottie = true,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          isLottie: isLottie,
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

  /// Static method to show warning dialog
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String iconPath,
    bool isLottie = true,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        config: CustomDialogConfig(
          title: title,
          subtitle: subtitle,
          iconPath: iconPath,
          isLottie: isLottie,
          type: DialogType.warning,
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
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
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

  Color _getDialogColor() {
    if (widget.config.customColor != null) {
      return widget.config.customColor!;
    }

    // Use primary color for all except error (red)
    switch (widget.config.type) {
      case DialogType.error:
        return const Color(0xFFE53935); // Red for errors
      case DialogType.success:
      case DialogType.confirmation:
      case DialogType.warning:
      case DialogType.info:
        return const Color(0xFF0056D2); // Your app primary color
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: widget.config.barrierDismissible,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(size.width * 0.05),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon
                            _buildIcon(size),

                            SizedBox(height: size.height * 0.02),

                            // Title
                            Text(
                              widget.config.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.055,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: size.height * 0.015),

                            // Subtitle
                            Text(
                              widget.config.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: size.width * 0.04,
                                color: isDark ? Colors.white70 : Colors.black54,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            if (widget.config.content != null) ...[
                              SizedBox(height: size.height * 0.02),
                              widget.config.content!,
                            ],

                            SizedBox(height: size.height * 0.03),

                            // Buttons
                            _buildButtons(size, theme, isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Size size) {
    final iconSize = size.width * 0.25;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: _getDialogColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: iconSize * 1.8,
          height: iconSize * 1.8,
          child: widget.config.isLottie
              ? Lottie.asset(
                  widget.config.iconPath,
                  fit: BoxFit.contain,
                  repeat:
                      widget.config.type == DialogType.success ||
                      widget.config.type == DialogType.error,
                )
              : Image.asset(widget.config.iconPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildButtons(Size size, ThemeData theme, bool isDark) {
    if (widget.config.showCancelButton) {
      // Two buttons (Confirmation dialog)
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              text: widget.config.cancelText,
              onPressed: _handleCancel,
              isPrimary: false,
              size: size,
              theme: theme,
              isDark: isDark,
            ),
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: _buildButton(
              text: widget.config.confirmText,
              onPressed: _handleConfirm,
              isPrimary: true,
              size: size,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ],
      );
    } else {
      // Single button
      return _buildButton(
        text: widget.config.confirmText,
        onPressed: _handleConfirm,
        isPrimary: true,
        size: size,
        theme: theme,
        isDark: isDark,
      );
    }
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Size size,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: size.height * 0.018,
            horizontal: size.width * 0.04,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? _getDialogColor()
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(size.width * 0.03),
            border: Border.all(
              color: isPrimary
                  ? _getDialogColor()
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: size.width * 0.04,
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
