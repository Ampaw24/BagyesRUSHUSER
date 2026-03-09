import 'package:bagyesrushappusernew/main.wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'states/app.state.dart';
import 'core/di/service_locator.dart' as di;
import 'core/di/service_locator.dart';
import 'core/services/user_session_manager.dart';
import 'src/auth/viewmodels/auth_viewmodel.dart';
import 'src/onboarding/viewmodels/onboarding_viewmodel.dart';
import 'src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import 'src/vendor/viewmodel/orders_viewmodel.dart';
import 'src/vendor/viewmodel/menu_viewmodel.dart';
import 'src/vendor/viewmodel/earnings_viewmodel.dart';
import 'src/vendor/viewmodel/settings_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await di.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ProviderScope(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState()),
            ChangeNotifierProvider(create: (_) => sl<UserSessionManager>()),
            ChangeNotifierProvider(create: (_) => sl<AuthViewModel>()),
            ChangeNotifierProvider(create: (_) => sl<OnboardingViewModel>()),
            ChangeNotifierProvider(
              create: (_) => sl<VendorRegistrationViewModel>(),
            ),
            ChangeNotifierProvider(create: (_) => sl<OrdersViewModel>()),
            ChangeNotifierProvider(create: (_) => sl<MenuViewModel>()),
            ChangeNotifierProvider(create: (_) => sl<EarningsViewModel>()),
            ChangeNotifierProvider(create: (_) => sl<SettingsViewModel>()),
          ],
          child: MyApp(),
        ),
      ),
    );
  });
}
