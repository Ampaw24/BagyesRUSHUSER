import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class StoreToggleCard extends StatefulWidget {
  final bool isOpen;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  const StoreToggleCard({
    super.key,
    required this.isOpen,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  State<StoreToggleCard> createState() => _StoreToggleCardState();
}

class _StoreToggleCardState extends State<StoreToggleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isOpen) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StoreToggleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isOpen && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isOpen
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.secondaryLight, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(w * 0.05),
        boxShadow: [
          BoxShadow(
            color: (widget.isOpen ? AppColors.primary : AppColors.secondary)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Pulsing status indicator dot
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, child) => Transform.scale(
                  scale: widget.isOpen ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: w * 0.025,
                  height: w * 0.025,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isOpen
                        ? AppColors.accentLight
                        : Colors.white.withValues(alpha: 0.4),
                    boxShadow: widget.isOpen
                        ? [
                            BoxShadow(
                              color: AppColors.accentLight
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.isOpen ? 'Store is Open' : 'Store is Closed',
                        key: ValueKey(widget.isOpen),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(height: w * 0.005),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.isOpen
                            ? 'Accepting new orders'
                            : 'Toggle to start receiving orders',
                        key: ValueKey('sub_${widget.isOpen}'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: w * 0.031,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle button
              GestureDetector(
                onTap: widget.isLoading
                    ? null
                    : () => widget.onToggle(!widget.isOpen),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  width: w * 0.15,
                  height: w * 0.08,
                  padding: EdgeInsets.all(w * 0.008),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(w * 0.04),
                    color: widget.isOpen
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: widget.isLoading
                      ? Center(
                          child: SizedBox(
                            width: w * 0.04,
                            height: w * 0.04,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : AnimatedAlign(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          alignment: widget.isOpen
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: w * 0.06,
                            height: w * 0.06,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: widget.isOpen
                                    ? HugeIcons.strokeRoundedStore01
                                    : HugeIcons.strokeRoundedCancel01,
                                size: w * 0.035,
                                color: widget.isOpen
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          // Status chips row
          SizedBox(height: w * 0.03),
          Row(
            children: [
              _StatusChip(
                icon: Icons.wifi,
                label: 'Online',
                isActive: widget.isOpen,
              ),
              SizedBox(width: w * 0.02),
              _StatusChip(
                icon: Icons.location_on_outlined,
                label: 'Location',
                isActive: widget.isOpen,
              ),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: widget.isOpen ? 1.0 : 0.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.025,
                    vertical: w * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.026,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.022,
        vertical: w * 0.012,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(w * 0.02),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.032, color: Colors.white.withValues(alpha: 0.9)),
          SizedBox(width: w * 0.012),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: w * 0.026,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
