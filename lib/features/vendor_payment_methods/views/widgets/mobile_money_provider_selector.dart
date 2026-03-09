import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/mobile_money_model.dart';

/// Animated provider selection grid with brand colors and press feedback.
class MobileMoneyProviderSelector extends StatelessWidget {
  final MobileMoneyProvider? selected;
  final ValueChanged<MobileMoneyProvider> onSelect;

  const MobileMoneyProviderSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Provider',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: MobileMoneyProvider.values.map((provider) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: provider != MobileMoneyProvider.values.last ? 10 : 0,
                ),
                child: _ProviderTile(
                  provider: provider,
                  isSelected: selected == provider,
                  onTap: () => onSelect(provider),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProviderTile extends StatefulWidget {
  final MobileMoneyProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderTile({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ProviderTile> createState() => _ProviderTileState();
}

class _ProviderTileState extends State<_ProviderTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Brand colours ────────────────────────────────────────────────────────

  Color get _brandColor => switch (widget.provider) {
        MobileMoneyProvider.mtnMomo => const Color(0xFFFFCC00),
        MobileMoneyProvider.vodafoneCash => const Color(0xFFE53935),
        MobileMoneyProvider.airtelTigo => const Color(0xFF1565C0),
      };

  String get _initials => switch (widget.provider) {
        MobileMoneyProvider.mtnMomo => 'MTN',
        MobileMoneyProvider.vodafoneCash => 'VF',
        MobileMoneyProvider.airtelTigo => 'AT',
      };

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _brandColor.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _brandColor : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _brandColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _brandColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: widget.provider == MobileMoneyProvider.mtnMomo
                          ? 9
                          : 11,
                      fontWeight: FontWeight.w900,
                      color: widget.provider == MobileMoneyProvider.mtnMomo
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.provider.shortName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _brandColor : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: _brandColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
