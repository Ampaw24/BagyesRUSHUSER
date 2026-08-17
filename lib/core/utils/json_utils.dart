/// Defensive coercion for values pulled out of decoded JSON.
///
/// Backend field types aren't guaranteed to match what a model declares
/// (e.g. numeric ids/foreign keys arriving as `int` where a `String` is
/// expected). Use these instead of raw casts/`??` chains so a type drift
/// on a successful response degrades to a fallback value instead of
/// throwing mid-parse.
class JsonUtils {
  const JsonUtils._();

  static String asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static String? asStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static int asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool asBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return fallback;
  }

  static List<String> asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => asString(e)).toList();
  }

  static DateTime? asDateTime(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
