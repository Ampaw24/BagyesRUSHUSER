import 'package:bagyesrushappusernew/main.wrapper.dart';
import 'package:bagyesrushappusernew/scw_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constant/config.dart';
import 'core/widgets/config_error_app.dart';
import 'core/di/service_locator.dart' as di;
import 'core/services/app_initializer.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    Config.validate();
  } on StateError catch (e) {
    runApp(ConfigErrorApp(message: e.message));
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Phase 1 — legacy vendor/onboarding services
  await di.init();
  // Phase 2 — new MVVM auth services (Cache, CacheHelper, Dio, CurrentUserProvider,
  // AuthRepository, AuthViewmodel); guarded with isRegistered checks.
  await AppInitializer.initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,                                                              
  ]).then((_) {
    runApp(
      MultiProvider(
        providers: ScwProviders.providers,
        child: const MyApp(),
      ),
    );
  });
  // Phase 3 — non-critical background init (analytics, push notifications, etc.)
  AppInitializer.initializeRemaining();
}
