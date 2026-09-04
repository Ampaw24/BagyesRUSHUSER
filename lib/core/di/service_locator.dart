import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/secure_storage_service.dart';
import '../utils/network_utility.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/cart/repositories/cart_repository.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/orders/repositories/orders_repository.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/parcel_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import '../../src/home/repositories/home_repository.dart';
import '../../src/onboarding/services/onboarding_service.dart';
import '../../src/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../src/notification/repository/notification_repository.dart';
import '../../src/notification/viewmodel/notification_viewmodel.dart';
import '../../src/vendor_registration/repositories/vendor_repository.dart';
import '../../src/vendor_registration/repositories/vendor_repository_impl.dart';
import '../../src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import '../../src/vendor_registration/viewmodels/step_validator.dart';
import '../../src/vendor/repository/vendor_dashboard_repository.dart';
import '../../src/vendor/repository/vendor_dashboard_repository_impl.dart';
import '../../src/vendor/viewmodel/orders_viewmodel.dart' as vendor_orders;
import '../../src/vendor/viewmodel/menu_viewmodel.dart';
import '../../src/vendor/viewmodel/earnings_viewmodel.dart';
import '../../src/vendor/viewmodel/settings_viewmodel.dart';
import '../../src/vendor/viewmodel/vendor_kyc_viewmodel.dart';
import '../../src/payment/repositories/payment_repository.dart';
import '../../src/payment/viewmodels/payment_viewmodel.dart';
import '../../src/transaction/repositories/transaction_repository.dart';
import '../../src/transaction/viewmodels/transaction_viewmodel.dart';
import '../../src/vendor-wallet/repositories/vendor_wallet_repository.dart';
import '../../src/vendor-wallet/viewmodels/vendor_wallet_viewmodel.dart';
import '../../features/vendors/repositories/vendor_repository.dart' as vendor_feature;
import '../../features/vendors/viewmodels/vendor_viewmodel.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Services ────────────────────────────────────────────────────────────────
  final secureStorage = SecureStorageService();
  sl.registerLazySingleton(() => secureStorage);

  sl.registerLazySingleton(() => OnboardingService(sl()));

  // ── Network (legacy — now uses Cache.instance instead of UserSessionManager) ─
  sl.registerLazySingleton(() => NetworkUtility());

  // ── Repositories ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRepository>(() => HomeRepository(client: sl<Dio>()));
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(client: sl<Dio>()),
  );
  sl.registerLazySingleton<VendorRepository>(() => VendorRepositoryImpl(sl()));
  sl.registerLazySingleton<VendorDashboardRepository>(
    () => VendorDashboardRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(
    () => vendor_feature.VendorRepository(client: sl()),
  );

  // ── Validators ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => AuthRepository(client: sl(), cacheHelper: sl()));
  sl.registerLazySingleton(() => CartRepository(client: sl()));
  sl.registerLazySingleton(() => OrdersRepository(client: sl()));
  sl.registerLazySingleton(() => ParcelRepository(client: sl()));
  sl.registerLazySingleton(() => PaymentRepository(client: sl()));
  sl.registerLazySingleton(() => StepValidator());
  sl.registerLazySingleton(() => PaymentGatewayRepository(client: sl()));
  sl.registerLazySingleton(() => TransactionRepository(client: sl()));
  sl.registerLazySingleton(() => VendorWalletRepository(client: sl()));

  // ── ViewModels ──────────────────────────────────────────────────────────────
  // Auth viewmodel is registered by AppInitializer (uses new MVVM pattern).
  sl.registerFactory(() => AuthViewmodel(repository: sl(), currentUserProvider: sl()));
  // Singleton (not factory) — cart is shared app-wide state (restaurant
  // detail, cart screen, checkout all read/mutate the same instance).
  sl.registerLazySingleton(() => CartViewModel(repository: sl()));
  sl.registerFactory(() => PaymentViewmodel(repository: sl()));
  sl.registerFactory(() => OrderViewModel(repository: sl()));
  sl.registerFactory(() => TransactionViewmodel(repository: sl()));
  sl.registerFactory(() => VendorWalletViewmodel(repository: sl()));
  sl.registerFactory(() => ParcelViewModel(repository: sl()));
  sl.registerFactory(() => PayoutProvidersViewModel(repository: sl()));
  sl.registerFactoryParam<PaymentViewModel, bool, void>(
    (isVendor, _) => PaymentViewModel(repository: sl(), isVendor: isVendor),
  );
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => NotificationViewmodel(repository: sl()));
  sl.registerFactory(() => VendorRegistrationViewModel(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => vendor_orders.OrdersViewModel(sl()));
  sl.registerFactory(() => MenuViewModel(sl()));
  sl.registerFactory(() => EarningsViewModel());
  sl.registerFactory(() => SettingsViewModel(sl()));
  sl.registerFactory(
    () => VendorKycViewModel(
      dashboardRepository: sl(),
      currentUserProvider: sl(),
    ),
  );
  sl.registerFactory(() => VendorViewmodel(repository: sl()));
}
