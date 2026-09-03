import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class NewOrderBanner extends StatefulWidget {
  final String orderId;
  final String amount;
  final String customerName;
  final int itemCount;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;

  const NewOrderBanner({
    super.key,
    required this.orderId,
    required this.amount,
    required this.itemCount,
    this.customerName = '',
    this.onTap,
    this.onAccept,
  });

  @override
  State<NewOrderBanner> createState() => _NewOrderBannerState();
}

class _NewOrderBannerState extends State<NewOrderBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(w * 0.05),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Order details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedZap,
                          color: AppColors.accentLight,
                          size: w * 0.035,
                        ),
                        SizedBox(width: w * 0.015),
                        Text(
                          'NEW ORDER',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: w * 0.026,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Mukta',
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      '#${widget.orderId}  •  ${widget.amount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.036,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Mukta',
                      ),
                    ),
                    Text(
                      '${widget.customerName}  •  ${widget.itemCount} items',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: w * 0.028,
                        fontFamily: 'Mukta',
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Accept button
              GestureDetector(
                onTap: widget.onAccept,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.045,
                    vertical: w * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(w * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: w * 0.032,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Mukta',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
