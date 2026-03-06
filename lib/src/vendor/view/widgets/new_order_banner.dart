import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';

class NewOrderBanner extends StatefulWidget {
  final String orderId;
  final String amount;
  final String customerName;
  final int itemCount;
  final int secondsLeft;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;

  const NewOrderBanner({
    super.key,
    required this.orderId,
    required this.amount,
    required this.itemCount,
    required this.secondsLeft,
    this.customerName = '',
    this.onTap,
    this.onAccept,
  });

  @override
  State<NewOrderBanner> createState() => _NewOrderBannerState();
}

class _NewOrderBannerState extends State<NewOrderBanner>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = widget.secondsLeft;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _timer?.cancel();
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress => _remaining / widget.secondsLeft;

  Color get _timerColor {
    if (_remaining <= 15) return AppColors.error;
    if (_remaining <= 30) return AppColors.accent;
    return Colors.white;
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
            borderRadius: BorderRadius.circular(w * 0.04),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular countdown timer
              SizedBox(
                width: w * 0.13,
                height: w * 0.13,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: w * 0.13,
                      height: w * 0.13,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        color: _timerColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_remaining}s',
                          style: TextStyle(
                            color: _timerColor,
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'left',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: w * 0.022,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.03),
              // Order details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: AppColors.accentLight,
                          size: w * 0.04,
                        ),
                        SizedBox(width: w * 0.01),
                        Text(
                          'NEW ORDER',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: w * 0.026,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.01),
                    Text(
                      '${widget.orderId}  •  ${widget.amount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.034,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      '${widget.customerName}  •  ${widget.itemCount} items',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: w * 0.028,
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
                    horizontal: w * 0.035,
                    vertical: w * 0.025,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: w * 0.032,
                      fontWeight: FontWeight.w700,
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
