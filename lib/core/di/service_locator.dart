import 'package:get_it/get_it.dart';
import '../services/secure_storage_service.dart';
import '../utils/network_utility.dart';
import '../../src/onboarding/services/onboarding_service.dart';
import '../../src/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../src/vendor_registration/repositories/vendor_repository.dart';
import '../../src/vendor_registration/repositories/vendor_repository_impl.dart';
import '../../src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import '../../src/vendor_registration/viewmodels/step_validator.dart';
import '../../src/vendor/repository/vendor_dashboard_repository.dart';
import '../../src/vendor/repository/vendor_dashboard_repository_impl.dart';
import '../../src/vendor/viewmodel/dashboard_viewmodel.dart';
import '../../src/vendor/viewmodel/orders_viewmodel.dart';
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
  sl.registerLazySingleton(() => StepValidator());

  // ── ViewModels ──────────────────────────────────────────────────────────────
  // Auth viewmodel is registered by AppInitializer (uses new MVVM pattern).
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => VendorRegistrationViewModel(sl(), sl()));
  sl.registerFactory(() => DashboardViewModel(sl()));
  sl.registerFactory(() => OrdersViewModel(sl()));
  sl.registerFactory(() => MenuViewModel(sl()));
  sl.registerFactory(() => EarningsViewModel());
  sl.registerFactory(() => SettingsViewModel(sl()));
}
