import '../models/visa_card_model.dart';

/// Utilities for card number validation, formatting, and masking.
abstract final class CardUtils {
  // ── Luhn algorithm ─────────────────────────────────────────────────────

  /// Returns true if [number] passes the Luhn checksum.
  static bool isValidLuhn(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // ── Expiry ─────────────────────────────────────────────────────────────

  /// Validates expiry string in "MM/YY" format.
  static bool isValidExpiry(String expiry) {
    final parts = expiry.split('/');
    if (parts.length != 2) return false;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final fullYear = 2000 + year;
    if (fullYear < now.year) return false;
    if (fullYear == now.year && month < now.month) return false;
    return true;
  }

  // ── CVV ────────────────────────────────────────────────────────────────

  static bool isValidCvv(String cvv) {
    final digits = cvv.replaceAll(RegExp(r'\D'), '');
    return digits.length == 3 || digits.length == 4;
  }

  // ── Formatting ─────────────────────────────────────────────────────────

  /// Formats raw digits into "XXXX XXXX XXXX XXXX".
  static String formatCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Formats raw digits into "MM/YY".
  static String formatExpiry(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return digits;
    return '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
  }

  // ── Extraction ─────────────────────────────────────────────────────────

  /// Returns last 4 digits from a raw (unformatted) card number.
  static String extractLast4(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return digits.padLeft(4, '0');
    return digits.substring(digits.length - 4);
  }

  /// Parses "MM/YY" into [expiryMonth, expiryYear].
  static (String month, String year) parseExpiry(String expiry) {
    final parts = expiry.split('/');
    if (parts.length == 2) return (parts[0], parts[1]);
    return ('01', '00');
  }

  // ── Brand detection ────────────────────────────────────────────────────

  static CardBrand detectBrand(String rawNumber) =>
      CardBrand.fromNumber(rawNumber);
}

/// Utilities for phone number validation and masking.
abstract final class PhoneUtils {
  // ── Validation ─────────────────────────────────────────────────────────

  /// Validates a Ghanaian phone in local (0XXXXXXXXX) or E.164 (+233XXXXXXXXX) format.
  static bool isValidGhanaPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    // Local: 10 digits starting with 0
    if (RegExp(r'^0[0-9]{9}$').hasMatch(digits)) return true;
    // E.164: 12 digits starting with 233
    if (RegExp(r'^233[0-9]{9}$').hasMatch(digits)) return true;
    return false;
  }

  // ── Normalisation ──────────────────────────────────────────────────────

  /// Converts local "054XXXXXXX" → E.164 "+233XXXXXXXXX".
  static String toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '+233${digits.substring(1)}';
    }
    if (digits.startsWith('233') && digits.length == 12) {
      return '+$digits';
    }
    return phone;
  }

  // ── Display formatting ─────────────────────────────────────────────────

  /// "+233541234567" → "+233 54 123 4567"
  static String formatDisplay(String e164) {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('233')) {
      final local = digits.substring(3); // 9 digits
      return '+233 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
    }
    return e164;
  }
}
