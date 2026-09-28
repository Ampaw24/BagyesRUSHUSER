import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

import '../utils/app_logger.dart';
import '../utils/phone_utils.dart';

class PickedContact {
  const PickedContact({required this.name, required this.phone});

  final String name;

  /// Local Ghana format (`0XXXXXXXXX`) when recognisable.
  final String phone;
}

/// Opens the OS-native contact picker — no contacts permission is needed
/// because the app only receives the single number the user taps.
abstract final class ContactPickerService {
  static final _picker = FlutterNativeContactPicker();

  /// Returns null when the user cancels or the picker fails.
  static Future<PickedContact?> pickPhoneContact() async {
    try {
      final contact = await _picker.selectPhoneNumber();
      if (contact == null) return null;
      final rawPhone = contact.selectedPhoneNumber ??
          (contact.phoneNumbers?.isNotEmpty == true
              ? contact.phoneNumbers!.first
              : '');
      return PickedContact(
        name: contact.fullName?.trim() ?? '',
        phone: PhoneUtils.toLocalFormat(rawPhone),
      );
    } catch (e, s) {
      appLogger.e('ContactPickerService.pickPhoneContact failed', error: e, stackTrace: s);
      return null;
    }
  }
}
