import 'package:bagyesrushappusernew/main.wrapper.dart';
import 'package:bagyesrushappusernew/scw_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/di/service_locator.dart' as di;
import 'core/services/app_initializer.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      ProviderScope(
        child: MultiProvider(
          providers: ScwProviders.providers,
          child: const MyApp(),
        ),
      ),
    );
  });
  // Phase 3 — non-critical background init (analytics, push notifications, etc.)
  AppInitializer.initializeRemaining();
}
