import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';

/// 6-digit OTP input with auto-focus-advance, paste support, and
/// animated focus highlight on each cell.
class OtpInputWidget extends StatefulWidget {
  final List<String> digits;       // current 6 values from state
  final bool hasError;
  final ValueChanged<(int index, String digit)> onDigitChanged;
  final ValueChanged<int> onBackspace;
  final ValueChanged<String> onPaste;

  const OtpInputWidget({
    super.key,
    required this.digits,
    required this.onDigitChanged,
    required this.onBackspace,
    required this.onPaste,
    this.hasError = false,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  static const int _length = 6;
  final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Listen for paste via clipboard
    for (int i = 0; i < _length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) _checkClipboard(i);
      });
    }
  }

  @override
  void didUpdateWidget(OtpInputWidget old) {
    super.didUpdateWidget(old);
    // Sync controller text with external state (e.g. after clear)
    for (int i = 0; i < _length; i++) {
      final d = widget.digits[i];
      if (_controllers[i].text != d) {
        _controllers[i].text = d;
        _controllers[i].selection = TextSelection.fromPosition(
          TextPosition(offset: d.length),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final fn in _focusNodes) { fn.dispose(); }
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  void _checkClipboard(int index) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final digits = data!.text!.replaceAll(RegExp(r'\D'), '');
      if (digits.length == _length) {
        widget.onPaste(digits);
        // Advance focus to last cell
        _focusNodes.last.requestFocus();
      }
    }
  }

  void _onKey(int index, String value) {
    if (value.isEmpty) return; // handled by backspace
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) return;

    // If more than one char was typed (paste via keyboard), handle as paste
    if (digit.length > 1) {
      widget.onPaste(digit);
      _focusNodes.last.requestFocus();
      return;
    }

    widget.onDigitChanged((index, digit));
    if (index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  void _onBackspace(int index) {
    if (widget.digits[index].isNotEmpty) {
      widget.onBackspace(index);
    } else if (index > 0) {
      widget.onBackspace(index - 1);
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_length, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < _length - 1 ? 10 : 0),
          child: _OtpCell(
            focusNode: _focusNodes[i],
            controller: _controllers[i],
            digit: widget.digits[i],
            hasError: widget.hasError,
            onChanged: (v) => _onKey(i, v),
            onBackspace: () => _onBackspace(i),
          ),
        );
      }),
    );
  }
}

// ── Single OTP cell ──────────────────────────────────────────────────────────

class _OtpCell extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final String digit;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpCell({
    required this.focusNode,
    required this.controller,
    required this.digit,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_OtpCell> createState() => _OtpCellState();
}

class _OtpCellState extends State<_OtpCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusCtrl;
  late Animation<double> _scaleAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut),
    );
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
    if (_isFocused) {
      _focusCtrl.forward();
    } else {
      _focusCtrl.reverse();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.digit.isNotEmpty;
    final primary = Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: _scaleAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 56,
        decoration: BoxDecoration(
          color: filled
              ? primary.withValues(alpha: 0.07)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.hasError
                ? AppColors.error
                : _isFocused
                    ? primary
                    : filled
                        ? primary.withValues(alpha: 0.4)
                        : AppColors.border,
            width: _isFocused || widget.hasError ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace) {
              widget.onBackspace();
            }
          },
          child: TextField(
            focusNode: widget.focusNode,
            controller: widget.controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            obscureText: filled,
            obscuringCharacter: '•',
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: widget.hasError ? AppColors.error : AppColors.textPrimary,
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
