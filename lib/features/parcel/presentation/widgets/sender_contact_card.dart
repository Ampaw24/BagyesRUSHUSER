import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/services/contact_picker_service.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../../core/widgets/contact_picker_button.dart';
import 'parcel_form_fields.dart';
import 'parcel_ui.dart';

/// Receive flow: who the rider collects the package from. Name and phone
/// are required — the backend texts this person the collection code.
class SenderContactCard extends StatefulWidget {
  final String name;
  final String phone;
  final String instructions;
  final void Function({required String name, required String phone})
  onContactChanged;
  final ValueChanged<String> onInstructionsChanged;

  const SenderContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.instructions,
    required this.onContactChanged,
    required this.onInstructionsChanged,
  });

  @override
  State<SenderContactCard> createState() => _SenderContactCardState();
}

class _SenderContactCardState extends State<SenderContactCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _instrCtrl;
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _instrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _phoneCtrl = TextEditingController(text: widget.phone);
    _instrCtrl = TextEditingController(text: widget.instructions);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _instrCtrl.dispose();
    _phoneFocus.dispose();
    _instrFocus.dispose();
    super.dispose();
  }

  void _pushContact() => widget.onContactChanged(
    name: _nameCtrl.text.trim(),
    phone: _phoneCtrl.text.trim(),
  );

  void _onContactEdited(String _) {
    setState(() {});
    _pushContact();
  }

  void _applyContact(PickedContact contact) {
    setState(() {
      if (contact.name.isNotEmpty) _nameCtrl.text = contact.name;
      if (contact.phone.isNotEmpty) _phoneCtrl.text = contact.phone;
    });
    _pushContact();
  }

  String? get _phoneError {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || PhoneUtils.isValidGhanaPhone(phone)) return null;
    return 'Enter a valid Ghana phone number';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final senderName = _nameCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParcelSectionLabel(
          label: 'Who has the package?',
          caption: 'The rider will call this person on arrival',
        ),
        SizedBox(height: w * 0.035),
        ParcelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedUser,
                label: 'Sender name',
                hint: null,
                required: true,
                trailing: ContactPickerButton(onPicked: _applyContact),
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
                controller: _nameCtrl,
                hint: 'e.g. Yaw Boateng',
                maxLength: 60,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                onChanged: _onContactEdited,
                w: w,
              ),
              SizedBox(height: w * 0.035),
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedCall,
                label: 'Sender phone',
                hint: null,
                required: true,
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                hint: 'e.g. 024 400 0003',
                keyboardType: TextInputType.phone,
                maxLength: 20,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
                ],
                errorText: _phoneError,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_instrFocus),
                onChanged: _onContactEdited,
                w: w,
              ),
              SizedBox(height: w * 0.035),
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Pickup instructions',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
                controller: _instrCtrl,
                focusNode: _instrFocus,
                hint: 'e.g. Ask at the counter for the sealed package',
                textInputAction: TextInputAction.done,
                maxLength: 500,
                onFieldSubmitted: (_) => _instrFocus.unfocus(),
                onChanged: (value) =>
                    widget.onInstructionsChanged(value.trim()),
                w: w,
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.03),
        _CollectionCodeNote(
          senderName: senderName.isEmpty ? 'The sender' : senderName,
        ),
      ],
    );
  }
}

class _CollectionCodeNote extends StatelessWidget {
  final String senderName;

  const _CollectionCodeNote({required this.senderName});

  @override
  Widget build(BuildContext context) => ParcelNote(
    tone: ParcelNoteTone.info,
    icon: HugeIcons.strokeRoundedSquareLock02,
    message:
        '$senderName gets a 4-digit pickup code by SMS once a rider '
        'accepts, and gives it to the rider to release the package.',
  );
}
