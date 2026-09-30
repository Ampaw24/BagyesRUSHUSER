import 'package:flutter/material.dart';

import '../utils/money_format.dart';

/// A money amount that counts smoothly to each new [amount] instead of
/// jumping — e.g. the "left to pay" figure as the wallet is toggled.
/// Renders without animation the first time it's built.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.amount,
    required this.style,
    this.currency = 'GHS',
    this.prefix = '',
    this.duration = const Duration(milliseconds: 450),
  });

  final double amount;
  final TextStyle style;
  final String currency;

  /// Prepended to the formatted amount, e.g. `-` for a deduction.
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: amount),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => Text(
        '$prefix${formatMoney(value, currency: currency)}',
        style: style,
      ),
    );
  }
}
