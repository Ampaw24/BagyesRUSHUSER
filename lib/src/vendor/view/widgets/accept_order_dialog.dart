import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_dialogs.dart';

/// Asks the vendor for an optional estimated preparation time, then calls
/// [onAccept] with it (null when left blank or not a number).
///
/// The text field owns its controller, so it is disposed with the dialog's
/// content — after the exit animation — rather than leaked or disposed while
/// still on screen.
Future<void> showAcceptOrderDialog(
  BuildContext context, {
  required void Function(int? estimatedPrepMinutes) onAccept,
}) {
  int? minutes;
  return CustomDialog.showConfirmation(
    context: context,
    title: 'Accept Order',
    subtitle: 'Optionally set an estimated preparation time (minutes).',
    confirmText: 'Accept',
    content: _PrepTimeField(onChanged: (value) => minutes = value),
    onConfirm: () => onAccept(minutes),
  );
}

class _PrepTimeField extends StatefulWidget {
  const _PrepTimeField({required this.onChanged});

  final ValueChanged<int?> onChanged;

  @override
  State<_PrepTimeField> createState() => _PrepTimeFieldState();
}

class _PrepTimeFieldState extends State<_PrepTimeField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      onChanged: (text) => widget.onChanged(int.tryParse(text.trim())),
      decoration: const InputDecoration(
        hintText: 'e.g. 15',
        border: OutlineInputBorder(),
      ),
    );
  }
}
