/// Build-time configuration, injected with
/// `--dart-define-from-file=env/app.json` (see `env/app.example.json`).
///
/// Nothing here is bundled as an asset, so no key ships as a readable file.
/// This is the only place that reads `String.fromEnvironment`.
class Config {
  Config._();

  /// API root including the version prefix, e.g. `https://host/api/v1`.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  /// Web-service key for Places / Geocoding / Directions REST calls.
  static const String mapsApiKey = String.fromEnvironment('PLACES_API_KEY');

  static const String splashText = String.fromEnvironment('SPLASH_TEXT');

  static const String defaultCountryCode = '+233';

  // Central Accra — map-center fallback when no device location or search
  // bias is available yet.
  static const double defaultMapCenterLat = 5.6037;
  static const double defaultMapCenterLng = -0.1870;

  /// Throws if the app was launched without its build-time config, so a
  /// missing `--dart-define-from-file` fails loudly instead of as a
  /// confusing network error on the first request.
  static void validate() {
    if (baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Run with '
        '--dart-define-from-file=env/app.json (copy env/app.example.json).',
      );
    }
  }
}
