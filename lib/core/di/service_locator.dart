import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/payout_setup_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../services/secure_storage_service.dart';
import '../utils/network_utility.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/customer_address/repositories/customer_address_repository.dart';
import 'package:bagyesrushappusernew/src/cart/repositories/cart_repository.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart' as consumer_orders;
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/payment_receipt_viewmodel.dart';
import 'package:bagyesrushappusernew/src/orders/repositories/orders_repository.dart';
import 'package:bagyesrushappusernew/src/orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import '../../src/home/repositories/home_repository.dart';
import '../../src/home/viewmodel/home_discovery_viewmodel.dart';
import '../../src/restaurant/repositories/restaurant_repository.dart';
import '../../src/restaurant/viewmodels/restaurant_detail_viewmodel.dart';
import '../../src/checkout/viewmodels/checkout_viewmodel.dart';
import '../../src/search/viewmodels/search_viewmodel.dart';
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
import '../../src/vendor/viewmodel/dashboard_viewmodel.dart';
import '../../src/vendor/viewmodel/earnings_viewmodel.dart';
import '../../src/vendor/viewmodel/settings_viewmodel.dart';
import '../../src/vendor/viewmodel/vendor_kyc_viewmodel.dart';
import '../../src/payment/repositories/payment_repository.dart';
import '../../src/payment/viewmodels/payment_viewmodel.dart';
import '../../src/transaction/repositories/transaction_repository.dart';
import '../../src/transaction/viewmodels/transaction_viewmodel.dart';
import '../../src/vendor-wallet/repositories/vendor_wallet_repository.dart';
import '../../src/vendor-wallet/viewmodels/vendor_wallet_viewmodel.dart';
import '../../src/customer-wallet/repositories/customer_wallet_repository.dart';
import '../../src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import '../../src/report/model/report.dart';
import '../../src/report/repository/report_repository.dart';
import '../../src/report/viewmodel/my_reports_viewmodel.dart';
import '../../src/report/viewmodel/report_detail_viewmodel.dart';
import '../../src/report/viewmodel/report_form_viewmodel.dart';
import '../../src/report/viewmodel/report_vendors_viewmodel.dart';
import '../../src/report/views/report_flow_args.dart';
import '../../src/order_reviews/models/review_target.dart';
import '../../src/order_reviews/repositories/order_review_repository.dart';
import '../../src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import '../../src/order_reviews/viewmodels/review_composer_viewmodel.dart';
import '../../src/vendor_reviews/repositories/review_repository.dart';
import '../../src/vendor_reviews/viewmodels/reviews_viewmodel.dart';
import '../../src/chat/repository/chat_repository.dart';
import '../../src/chat/viewmodel/chat_list_viewmodel.dart';
import '../../src/chat/viewmodel/chat_thread_viewmodel.dart';
import '../../src/chat/view/chat_thread_args.dart';
import '../services/realtime_repository.dart';
import '../services/realtime_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Services ────────────────────────────────────────────────────────────────
  final secureStorage = SecureStorageService();
  sl.registerLazySingleton(() => secureStorage);

  sl.registerLazySingleton(() => OnboardingService(sl()));

  // ── Network (legacy handle over the shared Dio registered by AppInitializer) ─
  sl.registerLazySingleton(() => NetworkUtility(sl<Dio>()));

  // ── Repositories ────────────────────────────────────────────────────────────
  sl.registerLazySingleton<HomeRepository>(() => HomeRepository(client: sl<Dio>()));
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(client: sl<Dio>()),
  );
  sl.registerLazySingleton<VendorRepository>(() => VendorRepositoryImpl(sl()));
  sl.registerLazySingleton<VendorDashboardRepository>(
    () => VendorDashboardRepositoryImpl(sl()),
  );

  // ── Validators ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => AuthRepository(client: sl(), cacheHelper: sl()));
  sl.registerLazySingleton(() => CartRepository(client: sl()));
  sl.registerLazySingleton(() => ConsumerOrdersRepository(client: sl()));
  sl.registerLazySingleton(() => CustomerAddressRepository(client: sl()));
  sl.registerLazySingleton(() => OrdersRepository(client: sl()));
  sl.registerLazySingleton(() => RestaurantRepository(client: sl()));
  sl.registerLazySingleton(() => ParcelRepository(client: sl()));
  sl.registerLazySingleton(() => PaymentRepository(client: sl()));
  sl.registerLazySingleton(() => StepValidator());
  sl.registerLazySingleton(() => PaymentGatewayRepository(client: sl()));
  sl.registerLazySingleton(() => TransactionRepository(client: sl()));
  sl.registerLazySingleton(() => VendorWalletRepository(client: sl()));
  sl.registerLazySingleton(() => CustomerWalletRepository(client: sl()));
  sl.registerLazySingleton(() => ReportRepository(client: sl()));
  sl.registerLazySingleton(() => ReviewRepository(client: sl()));
  sl.registerLazySingleton(() => OrderReviewRepository(client: sl()));
  sl.registerLazySingleton(() => ChatRepository(client: sl()));
  sl.registerLazySingleton(() => RealtimeRepository(client: sl()));
  sl.registerLazySingleton(() => RealtimeService(repository: sl(), authDio: sl()));

  // ── ViewModels ──────────────────────────────────────────────────────────────
  // AuthViewmodel is registered by AppInitializer as an app-wide singleton —
  // don't register it here: this runs first, and any registration would win
  // over (and silently replace) that singleton.
  // Singleton (not factory) — cart is shared app-wide state (restaurant
  // detail, cart screen, checkout all read/mutate the same instance).
  sl.registerLazySingleton(() => CartViewModel(repository: sl(), session: sl()));
  // Singleton — the order list is shared app-wide state (My Orders, order
  // tracking, checkout, and the report flow's rider-target picker all
  // read/mutate the same instance), same rationale as CartViewModel above.
  // Also subscribes to RealtimeService's order-status/rider-location streams
  // for its whole lifetime, so every screen watching orders gets live
  // updates, not just whichever tracking screen is currently open.
  sl.registerLazySingleton(() => consumer_orders.OrdersViewModel(sl(), sl(), sl()));
  // Factory + param — one fresh receipt per payment, keyed by the order and
  // the gateway reference it was paid with.
  sl.registerFactoryParam<PaymentReceiptViewModel, PaymentReceiptArgs, void>(
    (args, _) => PaymentReceiptViewModel(args, sl(), sl()),
  );
  // Singleton — which orders are already rated is read by My Orders, order
  // tracking and every review sheet, same rationale as OrdersViewModel.
  sl.registerLazySingleton(() => OrderReviewsViewModel(sl(), sl()));
  // Factory + param — one fresh form per review sheet, keyed by the order
  // being rated.
  sl.registerFactoryParam<ReviewComposerViewModel, ReviewTarget, void>(
    (target, _) => ReviewComposerViewModel(
      target: target,
      reviewsViewModel: sl(),
    ),
  );
  // Singleton — backs the Home tab (discovery feed, promo banners, popular
  // restaurants) for the app session, same rationale as CartViewModel above.
  sl.registerLazySingleton(
    () => HomeDiscoveryViewModel(restaurantRepository: sl(), homeRepository: sl()),
  );
  // Factory + param — one fresh instance per RestaurantDetailView push, not
  // shared across screens (see the class doc on RestaurantDetailViewModel).
  sl.registerFactoryParam<RestaurantDetailViewModel, String, void>(
    (restaurantId, _) =>
        RestaurantDetailViewModel(repository: sl(), restaurantId: restaurantId),
  );
  sl.registerFactory(() => PaymentViewmodel(repository: sl()));
  sl.registerFactory(() => OrderViewModel(repository: sl(), session: sl()));
  sl.registerFactory(() => TransactionViewmodel(repository: sl(), session: sl()));
  sl.registerFactory(() => VendorWalletViewmodel(repository: sl(), session: sl()));
  sl.registerFactory(() => CustomerWalletViewmodel(repository: sl(), session: sl()));
  sl.registerFactory(
    () => CustomerWithdrawalsViewModel(repository: sl(), session: sl()),
  );
  sl.registerFactory(() => PayoutSetupViewModel(repository: sl()));
  // Factory (not singleton, not app-wide) — one fresh instance per
  // SendParcelView visit, matching the original `.autoDispose` semantics.
  // Owned/disposed directly by that view's State; not in ScwProviders.
  sl.registerFactoryParam<SendParcelViewModel, ParcelDirection, void>(
    (direction, _) => SendParcelViewModel(sl(), direction: direction),
  );
  sl.registerFactory(() => PayoutProvidersViewModel(repository: sl()));
  sl.registerFactoryParam<PaymentViewModel, bool, void>(
    (isVendor, _) => PaymentViewModel(repository: sl(), isVendor: isVendor),
  );
  sl.registerFactory(() => OnboardingViewModel(sl()));
  sl.registerFactory(() => NotificationViewmodel(repository: sl(), session: sl()));
  // Owns a dedicated AuthViewmodel: the registration flow is driven by
  // observing that instance's state (AuthError, OTPSent, … then resetState()),
  // so it must not share the app-wide one — it would consume the outcomes of
  // login/OTP screens elsewhere before they could react to them.
  sl.registerFactory(() => VendorRegistrationViewModel(
        sl(),
        sl(),
        AuthViewmodel(
          repository: sl(),
          currentUserProvider: sl(),
          realtimeService: sl(),
        ),
        sl(),
      ));
  sl.registerFactory(() => vendor_orders.OrdersViewModel(sl(), sl()));
  sl.registerFactory(() => DashboardViewModel(sl(), sl()));
  sl.registerFactory(() => EarningsViewModel(sl()));
  sl.registerFactory(() => SettingsViewModel(sl(), sl()));
  // Factory, root-provided (the reply sheet is a modal route outside the
  // reviews screen's own subtree, so it can't be screen-scoped). SessionAware:
  // the reviews screen reloads on entry, logout drops the previous vendor's.
  sl.registerFactory(() => ReviewsViewModel(sl(), sl()));
  sl.registerFactory(
    () => VendorKycViewModel(
      dashboardRepository: sl(),
      currentUserProvider: sl(),
    ),
  );
  sl.registerFactory(() => CheckoutViewModel(
        ordersViewModel: sl(),
        ordersRepository: sl(),
        addressRepository: sl(),
        session: sl(),
      ));
  sl.registerFactory(() => SearchViewModel(sl()));
  // Factory + param — one fresh instance per ReportFlowView push, matching
  // the report wizard's screen-scoped lifetime (see the class doc on
  // ReportFormViewModel).
  sl.registerFactoryParam<ReportFormViewModel, ReportFlowArgs, void>(
    (args, _) => ReportFormViewModel(sl(), args: args),
  );
  // Factory + param — one fresh instance per MyReportsView push/role.
  sl.registerFactoryParam<MyReportsViewModel, ReportRole, void>(
    (role, _) => MyReportsViewModel(repository: sl(), role: role),
  );
  // Factory + 2 params — one fresh instance per ReportDetailView push.
  sl.registerFactoryParam<ReportDetailViewModel, String, ReportRole>(
    (reportId, role) =>
        ReportDetailViewModel(repository: sl(), reportId: reportId, role: role),
  );
  // Factory — owned by the report flow's vendor-target-picker step only.
  sl.registerFactory(() => ReportVendorsViewModel(sl()));

  // Factory — one fresh instance per ChatListView visit, matching
  // MyReportsViewModel's rationale (a message sent elsewhere then popped
  // back to shows up without a manual refresh).
  sl.registerFactory(() => ChatListViewModel(repository: sl()));
  // Factory + param — one fresh instance per ChatThreadView push, matching
  // ReportDetailViewModel's rationale.
  sl.registerFactoryParam<ChatThreadViewModel, ChatThreadArgs, void>(
    (args, _) => ChatThreadViewModel(repository: sl(), realtimeService: sl(), args: args),
  );
}
