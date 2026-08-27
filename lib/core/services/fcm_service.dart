import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bagyesrushappusernew/core/router/app_router.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

/// Same order-related push convention already used by the in-app
/// notification list (see `NotificationDetailsScreen._isOrderRelated`):
/// an order id under `orderId`/`order_id`, tagged with one of these types
/// (or an explicit `screen: order_tracking`).
const _orderRelatedTypes = {'order_placed', 'order_update', 'delivery'};

String? _orderIdFrom(RemoteMessage message) {
  final data = message.data;
  final orderId = (data['orderId'] ?? data['order_id'])?.toString();
  if (orderId == null || orderId.isEmpty) return null;
  final isOrderRelated = _orderRelatedTypes.contains(data['type']) ||
      data['screen'] == 'order_tracking';
  return isOrderRelated ? orderId : null;
}

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for order updates and other important alerts.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Must be a top-level function (or static) — Firebase invokes it in a
/// separate isolate when a message arrives while the app is terminated
/// or backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  appLogger.i('FCM background message: ${message.messageId}');

  // When the payload includes a `notification` block, the OS already
  // auto-displayed it before this handler ran — building one here too
  // would show a duplicate. Only data-only messages need to be surfaced
  // manually.
  if (message.notification == null) {
    await _initLocalNotifications();
    await _showLocalNotification(message);
  }
}

/// Handles FCM setup: permission request, local-notification display, and
/// device token retrieval.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Set when the app is cold-launched by tapping an order-related push,
  /// before the router/widget tree exists to navigate into it yet.
  /// Consumed once by [SplashScreen] after it finishes its normal
  /// auth-based routing.
  static String? pendingOrderId;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      appLogger.w('FCM: notification permission denied');
      return;
    }

    await _initLocalNotifications();

    final token = await getToken();
    appLogger.i('FCM token: $token');

    _messaging.onTokenRefresh.listen((newToken) {
      appLogger.i('FCM token refreshed: $newToken');
    });

    // Neither Android nor iOS auto-display a system banner while the app is
    // in the foreground, regardless of whether the payload has a
    // `notification` block — this is the only place a foreground message
    // needs to be turned into a visible notification manually.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // User tapped a notification while the app was backgrounded — the app
    // (and its router) is already up, so navigate immediately.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      appLogger.i('Notification opened app: ${message.messageId}');
      final orderId = _orderIdFrom(message);
      if (orderId != null) {
        appRouter.push(AppRoutes.trackOrder, extra: orderId);
      }
    });

    // App was launched from a terminated state by tapping a notification.
    // The router isn't guaranteed to exist yet at this point (this races
    // against runApp() in main.dart) — stash the id for SplashScreen to
    // pick up once it's actually mounted, instead of navigating here.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      appLogger.i(
        'App launched from notification: ${initialMessage.messageId}',
      );
      pendingOrderId = _orderIdFrom(initialMessage);
    }
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

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_androidChannel);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'];
  final body = notification?.body ?? message.data['body'];
  if (title == null && body == null) {
    appLogger.w(
      'FCM message ${message.messageId} has no title/body to display '
      '(neither `notification` nor `data.title`/`data.body` set)',
    );
    return;
  }

  await _localNotifications.show(
    id:
        (message.messageId ?? DateTime.now().toIso8601String()).hashCode &
        0x7fffffff,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: jsonEncode(message.data),
  );
}
