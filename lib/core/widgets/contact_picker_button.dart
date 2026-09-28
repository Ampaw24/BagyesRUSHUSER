import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../constant/app_theme.dart';
import '../services/contact_picker_service.dart';

/// Compact "pick from contacts" action that fills a name + phone pair.
class ContactPickerButton extends StatelessWidget {
  final ValueChanged<PickedContact> onPicked;

  const ContactPickerButton({super.key, required this.onPicked});

  Future<void> _pick() async {
    final contact = await ContactPickerService.pickPhoneContact();
    if (contact != null) onPicked(contact);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return TextButton.icon(
      onPressed: _pick,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: w * 0.02),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedContactBook,
        color: AppColors.primary,
        size: w * 0.042,
      ),
      label: Text(
        'Contacts',
        style: TextStyle(fontSize: w * 0.032, fontWeight: FontWeight.w600),
      ),
    );
  }
}
