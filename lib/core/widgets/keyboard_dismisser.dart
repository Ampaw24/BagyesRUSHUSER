import 'package:flutter/material.dart';

/// Drops keyboard focus when a tap lands on empty space.
///
/// Taps claimed by a descendant (text fields, buttons, list rows) win the
/// gesture arena, so only taps nobody handles reach [onTap]. Placed above the
/// Navigator it also covers dialogs and bottom sheets.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
