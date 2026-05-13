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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
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
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.05,
        vertical: w * 0.042,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isOpen
              ? [AppColors.primary, AppColors.primaryDark]
              : [const Color(0xFF374151), const Color(0xFF1F2937)],
        ),
        borderRadius: BorderRadius.circular(w * 0.045),
        boxShadow: [
          BoxShadow(
            color: (widget.isOpen ? AppColors.primary : const Color(0xFF374151))
                .withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: widget.isOpen ? _pulseAnimation.value : 1.0,
              child: child,
            ),
            child: Container(
              width: w * 0.022,
              height: w * 0.022,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOpen
                    ? AppColors.accentLight
                    : Colors.white.withValues(alpha: 0.35),
                boxShadow: widget.isOpen
                    ? [
                        BoxShadow(
                          color: AppColors.accentLight.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
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
                        : 'Tap to start receiving orders',
                    key: ValueKey('sub_${widget.isOpen}'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: w * 0.031,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.isLoading
                ? null
                : () => widget.onToggle(!widget.isOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              width: w * 0.145,
              height: w * 0.077,
              padding: EdgeInsets.all(w * 0.008),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(w * 0.04),
                color: widget.isOpen
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: w * 0.038,
                        height: w * 0.038,
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
                        width: w * 0.057,
                        height: w * 0.057,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
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
                            size: w * 0.033,
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
    );
  }
}
