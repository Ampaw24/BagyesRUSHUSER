import 'package:get_it/get_it.dart';
import '../services/secure_storage_service.dart';
import '../services/user_session_manager.dart';
import '../utils/network_utility.dart';
import '../../src/auth/repositories/auth_repository.dart';
import '../../src/auth/viewmodels/auth_viewmodel.dart';
import '../../src/onboarding/services/onboarding_service.dart';
import '../../src/onboarding/viewmodels/onboarding_viewmodel.dart';
import '../../src/vendor_registration/repositories/vendor_repository.dart';
import '../../src/vendor_registration/viewmodels/vendor_registration_viewmodel.dart';
import '../../src/vendor_registration/viewmodels/step_validator.dart';
import '../../src/vendor/repository/vendor_dashboard_repository.dart';
import '../../src/vendor/viewmodel/dashboard_viewmodel.dart';
import '../../src/vendor/viewmodel/orders_viewmodel.dart';
import '../../src/vendor/viewmodel/menu_viewmodel.dart';
import '../../src/vendor/viewmodel/earnings_viewmodel.dart';
import '../../src/vendor/viewmodel/settings_viewmodel.dart';
import '../../features/vendor_payment_methods/services/payment_api_service.dart';
import '../../features/vendor_payment_methods/services/otp_service.dart';
import '../../features/vendor_payment_methods/repositories/payment_repository.dart';
import '../../features/vendor_wallet/services/wallet_api_service.dart';
import '../../features/vendor_wallet/repositories/wallet_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  final secureStorage = SecureStorageService();
  sl.registerLazySingleton(() => secureStorage);

  final sessionManager = UserSessionManager(sl());
  await sessionManager.init();
  sl.registerLazySingleton(() => sessionManager);

  // Onboarding Service
  sl.registerLazySingleton(() => OnboardingService(sl()));

  // Network
  sl.registerLazySingleton(() => NetworkUtility(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<VendorRepository>(() => VendorRepositoryImpl(sl()));
  sl.registerLazySingleton<VendorDashboardRepository>(
    () => VendorDashboardRepositoryImpl(sl()),
  );

  // Payment methods (dummy — swap sl() args for real deps when API is ready)
  sl.registerLazySingleton(() => PaymentApiService());
  sl.registerLazySingleton(() => OtpService(sl()));
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl(), sl()),
  );

  // Wallet (dummy — swap for real API service when ready)
  sl.registerLazySingleton(() => WalletApiService());
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(sl()),
  );

  // Validators
  sl.registerLazySingleton(() => StepValidator());

  // ViewModels
  sl.registerFactory(() => AuthViewModel(sl(), sl()));
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => VendorRegistrationViewModel(sl(), sl()));
  sl.registerFactory(() => DashboardViewModel(sl()));
  sl.registerFactory(() => OrdersViewModel(sl()));
  sl.registerFactory(() => MenuViewModel(sl()));
  sl.registerFactory(() => EarningsViewModel());
  sl.registerFactory(() => SettingsViewModel(sl()));
}
