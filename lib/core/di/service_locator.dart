import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/secure_storage_service.dart';
import '../utils/network_utility.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/orders/repositories/orders_repository.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import '../../src/home/repositories/home_repository.dart';
import '../../src/onboarding/services/onboarding_service.dart';
import '../../src/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../src/home/viewmodels/home_viewmodel.dart';
import '../../src/vendor_registration/repositories/vendor_repository.dart';
import '../../src/vendor_registration/repositories/vendor_repository_impl.dart';
import '../../src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import '../../src/vendor_registration/viewmodels/step_validator.dart';
import '../../src/vendor/repository/vendor_dashboard_repository.dart';
import '../../src/vendor/repository/vendor_dashboard_repository_impl.dart';
import '../../src/vendor/viewmodel/dashboard_viewmodel.dart';
import '../../src/vendor/viewmodel/orders_viewmodel.dart' as vendor_orders;
import '../../src/vendor/viewmodel/menu_viewmodel.dart';
import '../../src/vendor/viewmodel/earnings_viewmodel.dart';
import '../../src/vendor/viewmodel/settings_viewmodel.dart';
import '../../features/vendor_payment_methods/services/payment_api_service.dart';
import '../../features/vendor_payment_methods/services/otp_service.dart';
import '../../features/vendor_payment_methods/repositories/payment_repository.dart';
import '../../features/vendor_payment_methods/repositories/payment_repository_impl.dart';
import '../../features/vendor_wallet/services/wallet_api_service.dart';
import '../../features/vendor_wallet/repositories/wallet_repository.dart';
import '../../features/vendor_wallet/repositories/wallet_repository_impl.dart';

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
  sl.registerLazySingleton<VendorRepository>(() => VendorRepositoryImpl(sl()));
  sl.registerLazySingleton<VendorDashboardRepository>(
    () => VendorDashboardRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => PaymentApiService());
  sl.registerLazySingleton(() => OtpService(sl()));
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton(() => WalletApiService());
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(sl()),
  );

  // ── Validators ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => AuthRepository(client: sl(), cacheHelper: sl()));
  sl.registerLazySingleton(() => OrdersRepository(client: sl()));
  sl.registerLazySingleton(() => StepValidator());

  // ── ViewModels ──────────────────────────────────────────────────────────────
  // Auth viewmodel is registered by AppInitializer (uses new MVVM pattern).
  sl.registerFactory(() => AuthViewmodel(repository: sl(), currentUserProvider: sl()));
  sl.registerFactory(() => OrderViewModel(repository: sl()));
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => HomeViewmodel(repository: sl()));
  sl.registerFactory(() => VendorRegistrationViewModel(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => DashboardViewModel(sl()));
  sl.registerFactory(() => vendor_orders.OrdersViewModel(sl()));
  sl.registerFactory(() => MenuViewModel(sl()));
  sl.registerFactory(() => EarningsViewModel());
  sl.registerFactory(() => SettingsViewModel(sl()));
}
