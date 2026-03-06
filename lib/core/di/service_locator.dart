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

  // Validators
  sl.registerLazySingleton(() => StepValidator());

  // ViewModels
  sl.registerFactory(() => AuthViewModel(sl(), sl()));
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => VendorRegistrationViewModel(sl(), sl()));
  sl.registerFactory(() => DashboardViewModel(sl()));
  sl.registerFactory(() => OrdersViewModel(sl()));
  sl.registerFactory(() => MenuViewModel(sl()));
  sl.registerFactory(() => EarningsViewModel(sl()));
  sl.registerFactory(() => SettingsViewModel(sl()));
}
