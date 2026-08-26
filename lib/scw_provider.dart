import 'package:bagyesrushappusernew/core/di/service_locator.dart' show sl;
import 'package:bagyesrushappusernew/core/providers/app_providers.dart'
    as core_providers;
import 'package:bagyesrushappusernew/src/home/viewmodels/home_viewmodel.dart';
import 'package:bagyesrushappusernew/src/notification/viewmodel/notification_viewmodel.dart';
import 'package:bagyesrushappusernew/src/onboarding/viewmodels/onboarding_viewmodel.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/parcel_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/earnings_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/menu_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/settings_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor/viewmodel/vendor_kyc_viewmodel.dart';
import 'package:bagyesrushappusernew/src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class ScwProviders {
  static List<SingleChildWidget> get providers => [
        // ── Global state ────────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AppState()),
        // ── Auth + current user (new MVVM pattern) ──────────────────────
        ...core_providers.AppProviders.allProviders,
        // ── Other feature viewmodels ────────────────────────────────────
        ChangeNotifierProvider(create: (_) => sl<OnboardingViewModel>()),
        ChangeNotifierProvider(
          create: (_) => sl<VendorRegistrationViewModel>(),
        ),
        ChangeNotifierProvider(create: (_) => sl<OrdersViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<MenuViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<EarningsViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<SettingsViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<VendorKycViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<HomeViewmodel>()),
        ChangeNotifierProvider(create: (_) => sl<NotificationViewmodel>()),
        ChangeNotifierProvider(create: (_) => sl<ParcelViewModel>()),
        ChangeNotifierProvider(create: (_) => sl<PayoutProvidersViewModel>()),
      ];
}
