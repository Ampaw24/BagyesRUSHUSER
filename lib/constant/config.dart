import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  Config._();
  static final String GMAPIKEY =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''; //Goofle Maps API Key

  static final String baseUrl = dotenv.env['DEV_BASE_URL'] ?? '';
  static final String googleNearbyUrl =
      dotenv.env['GOOGLE_NEARBY_URL'] ?? ''; // Google Nearby Search URL
  static final String wsUrl = dotenv.env['WS_BASE_URL'] ?? ''; // WebSocket URL

  static final String appVersion =
      dotenv.env['APPVERSION'] ?? '1.0.0'; // App Version

  // Android OAuth Client ID - Used for Android platform authentication
  static final String googleSignInClientId =
      dotenv.env['G_CLIENTID_ANDROID'] ?? '';

  // Web OAuth Client ID - Used for server-side token validation (serverClientId)
  // This MUST be different from the Android client ID
  static final String googleSignInClientIdWEB =
      dotenv.env['G_CLIENTID_WEB'] ?? '';

  static final String googleSignInClientIdIOS =
      dotenv.env['G_CLIENTID_IOS'] ?? '';
}
