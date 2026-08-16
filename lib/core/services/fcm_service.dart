import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

/// Must be a top-level function (or static) — Firebase invokes it in a
/// separate isolate when a message arrives while the app is terminated
/// or backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  appLogger.i('FCM background message: ${message.messageId}');
}

/// Handles FCM setup: permission request and device token retrieval.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      appLogger.w('FCM: notification permission denied');
      return;
    }

    final token = await getToken();
    appLogger.i('FCM token: $token');

    _messaging.onTokenRefresh.listen((newToken) {
      appLogger.i('FCM token refreshed: $newToken');
    });
  }

  /// Returns the current FCM registration token for this device, or `null`
  /// if permission hasn't been granted / the token isn't available yet.
  static Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // FCM tokens on iOS depend on an APNs token being assigned first.
      await _messaging.getAPNSToken();
    }
    return _messaging.getToken();
  }
}
