import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Closes the keyboard when the user taps anywhere outside the focused text
/// field — empty space, cards, buttons, list rows — app-wide, including
/// dialogs and bottom sheets (it sits above the Navigator).
///
/// Flutter's own tap-outside behaviour does nothing for touch on Android
/// and iOS; this overrides [EditableTextTapOutsideIntent] and
/// [EditableTextTapUpOutsideIntent] instead of using a [GestureDetector], so
/// taps that a child claims still count. A drag (scrolling) is not a tap and
/// leaves the keyboard open. Tapping another field just moves focus, and
/// anything wrapped in a [TextFieldTapRegion] (e.g. a chat send button)
/// counts as part of the field.
class KeyboardDismisser extends StatefulWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardDismisser> createState() => _KeyboardDismisserState();
}

class _KeyboardDismisserState extends State<KeyboardDismisser> {
  int? _downPointer;
  Offset? _downPosition;

  late final Map<Type, Action<Intent>> _actions = {
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) {
        _downPointer = intent.pointerDownEvent.pointer;
        _downPosition = intent.pointerDownEvent.position;
        return null;
      },
    ),
    EditableTextTapUpOutsideIntent:
        CallbackAction<EditableTextTapUpOutsideIntent>(
          onInvoke: (intent) {
            final up = intent.pointerUpEvent;
            final down = _downPosition;
            final isSamePointer = up.pointer == _downPointer;
            _downPointer = null;
            _downPosition = null;
            if (!isSamePointer || down == null) return null;
            if ((up.position - down).distance < kTouchSlop) {
              intent.focusNode.unfocus();
            }
            return null;
          },
        ),
  };

  @override
  Widget build(BuildContext context) {
    return Actions(actions: _actions, child: widget.child);
  }
}
