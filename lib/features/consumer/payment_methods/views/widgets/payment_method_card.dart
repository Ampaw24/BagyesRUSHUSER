import 'package:flutter/material.dart';
import '../../../../../constant/app_theme.dart';
import '../../../../../src/payment/model/payment_method.dart';
import '../../../../../src/payment/model/payout_provider.dart';

/// A premium fintech-style card tile for a single mobile money payout method.
class PaymentMethodCard extends StatefulWidget {
  final PaymentMethod method;
  final bool isProcessing;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    this.isProcessing = false,
    this.onSetDefault,
    this.onDelete,
    this.onTap,
  });

  @override
  State<PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<PaymentMethodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  List<Color> get _gradient => switch (widget.method.provider) {
        PayoutProvider.mtnMomo => [
            const Color(0xFFFFCC00),
            const Color(0xFFFF8C00),
          ],
        PayoutProvider.telecelCash => [
            const Color(0xFFE53935),
            const Color(0xFFB71C1C),
          ],
        PayoutProvider.airtelTigo => [
            const Color(0xFF1565C0),
            const Color(0xFF0D47A1),
          ],
        null => [AppColors.primary, AppColors.primaryDark],
      };

  Color get _foreground =>
      widget.method.provider == PayoutProvider.mtnMomo
          ? const Color(0xFF1A1A1A)
          : Colors.white;

  Widget _buildBrandIcon() {
    final provider = widget.method.provider;
    final asset = switch (provider) {
      PayoutProvider.mtnMomo => 'assets/icons/mtnbanner.png',
      PayoutProvider.telecelCash => 'assets/icons/telecel_icon.jpg',
      PayoutProvider.airtelTigo => 'assets/icons/atbanner.png',
      null => null,
    };
    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(asset, height: 32, fit: BoxFit.contain),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _foreground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        provider?.shortName ?? 'MoMo',
        style: TextStyle(
          color: _foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _foreground.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _foreground.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBrandIcon(),
                        if (widget.isProcessing)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _foreground.withValues(alpha: 0.8),
                            ),
                          )
                        else
                          _CardMenu(
                            foreground: _foreground,
                            isDefault: method.isDefault,
                            onSetDefault: widget.onSetDefault,
                            onDelete: widget.onDelete,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      method.displayTitle,
                      style: TextStyle(
                        color: _foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.maskedPhone,
                      style: TextStyle(
                        color: _foreground.withValues(alpha: 0.75),
                        fontSize: 14,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (method.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _foreground.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: _foreground,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overflow menu ────────────────────────────────────────────────────────────

class _CardMenu extends StatelessWidget {
  final Color foreground;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  const _CardMenu({
    required this.foreground,
    required this.isDefault,
    this.onSetDefault,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: foreground, size: 20),
      color: AppColors.scaffold,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) {
        switch (value) {
          case 'default':
            onSetDefault?.call();
          case 'delete':
            onDelete?.call();
        }
      },
      itemBuilder: (_) => [
        if (!isDefault)
          const PopupMenuItem(
            value: 'default',
            child: _MenuItem(
              icon: Icons.star_outline_rounded,
              label: 'Set as Default',
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c,
          ),
        ),
      ],
    );
  }
}
