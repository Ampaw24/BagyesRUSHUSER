/// Utility functions for phone number masking, formatting, and validation.
abstract final class PhoneUtils {
  /// Masks a phone number showing only the last 4 digits.
  ///
  /// Examples:
  /// - "+233241234567" -> "+233 ••• ••4567"
  /// - "0241234567" -> "••••••4567"
  /// - "4567" -> "****"
  static String maskPhoneNumber(String rawPhone) {
    final cleaned = rawPhone.trim();
    if (cleaned.length <= 4) {
      return '•' * cleaned.length;
    }

    final last4 = cleaned.substring(cleaned.length - 4);

    if (cleaned.startsWith('+233')) {
      final middleLength = cleaned.length - 4 - 4; // prefix +233 is 4 chars
      final maskedMiddle = '•' * (middleLength > 0 ? middleLength : 3);
      return '+233 ••• $maskedMiddle$last4';
    } else if (cleaned.startsWith('0')) {
      final masked = '•' * (cleaned.length - 4);
      return '$masked$last4';
    } else {
      final masked = '•' * (cleaned.length - 4);
      return '$masked$last4';
    }
  }

  /// Normalizes a 9-digit or 10-digit local phone input into standard international format.
  /// E.g. "241234567" or "0241234567" -> "+233241234567".
  static String formatToInternational(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+233$digits';
  }

  /// Returns true if the phone number is a valid 9-digit (without leading 0)
  /// or 10-digit (with leading 0) Ghana mobile number.
  static bool isValidGhanaPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return !digits.startsWith('0');
    }
    if (digits.length == 10 && digits.startsWith('0')) {
      return true;
    }
    if (digits.length == 12 && digits.startsWith('233')) {
      return true;
    }
    return false;
  }
}
