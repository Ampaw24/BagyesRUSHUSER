import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/presentation/splash_screen.dart';
import 'package:bagyesrushappusernew/presentation/home/courier_home.dart';
import 'package:bagyesrushappusernew/presentation/orders/track_order.dart';
import 'package:bagyesrushappusernew/presentation/profile/profile.dart';
import 'package:bagyesrushappusernew/presentation/profile/edit_profile.dart';
import 'package:bagyesrushappusernew/features/parcel/presentation/views/send_parcel_view.dart';
import 'package:bagyesrushappusernew/presentation/courier/get_food_deliver.dart';
import 'package:bagyesrushappusernew/presentation/courier/get_grocery_deliver.dart';
import 'package:bagyesrushappusernew/presentation/courier/restaurant_items.dart';
import 'package:bagyesrushappusernew/presentation/courier/route_map.dart';
import 'package:bagyesrushappusernew/presentation/payment/payment.dart';
import 'package:bagyesrushappusernew/presentation/invite_friend/invite_friend.dart';
import 'package:bagyesrushappusernew/presentation/help_support/help_support_view.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/presentation/report_flow_args.dart';
import 'package:bagyesrushappusernew/features/report/presentation/views/my_reports_view.dart';
import 'package:bagyesrushappusernew/features/report/presentation/views/report_detail_view.dart';
import 'package:bagyesrushappusernew/features/report/presentation/views/report_flow_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/login_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/signup_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/otp_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/reset_password_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/walkthrough_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/kyc_verification_view.dart';
import 'package:bagyesrushappusernew/src/onboarding/views/onboarding_view.dart';
import 'package:bagyesrushappusernew/src/vendor_registration/views/vendor_registration_view.dart';
import 'package:bagyesrushappusernew/src/vendor/view/vendor_home.dart';
import 'package:bagyesrushappusernew/src/vendor/view/vendor_kyc_view.dart';
import 'package:bagyesrushappusernew/src/vendor/view/vendor_payout_view.dart';
import 'package:bagyesrushappusernew/features/vendor_payment_methods/views/screens/payment_methods_screen.dart';
import 'package:bagyesrushappusernew/features/vendor_wallet/views/screens/wallet_screen.dart';
import 'package:bagyesrushappusernew/features/courier_wallet/views/screens/courier_wallet_screen.dart';

// ── Consumer feature screens ──
import 'package:bagyesrushappusernew/features/consumer/restaurant/presentation/views/restaurant_detail_view.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/views/cart_view.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/views/checkout_view.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/views/order_tracking_view.dart';
import 'package:bagyesrushappusernew/features/consumer/search/presentation/views/consumer_search_view.dart';
import 'package:bagyesrushappusernew/features/consumer/notifications/view/screens/consumer_notifications_screen.dart';

import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that do not require authentication.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.walkthrough,
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.otp,
  AppRoutes.resetPassword,
  AppRoutes.vendorRegistration,
};

/// Routes exempt from KYC verification checks (user is logged in but
/// allowed to access these even when not fully verified).
const _kycExemptRoutes = {
  AppRoutes.kycVerification,
  AppRoutes.editProfile,
  AppRoutes.profile,
  AppRoutes.vendorKyc,
  AppRoutes.helpSupport,
  AppRoutes.reportFlow,
  AppRoutes.myReports,
  '/report/history/:id',
};

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: kDebugMode,
  // Re-evaluate the redirect whenever auth state changes so that background
  // token expiry / logout immediately redirects the user to login.
  refreshListenable: GetIt.instance<CurrentUserProvider>(),

  // ── Centralized redirect guard ──────────────────────────────────────────
  redirect: (context, state) {
    final location = state.matchedLocation;
    final isPublicRoute = _publicRoutes.contains(location);
    final hasToken = Cache.instance.sessionToken != null;

    // 1. Unauthenticated user trying to access a protected route → login
    if (!hasToken && !isPublicRoute) {
      return AppRoutes.login;
    }

    // 2. Authenticated user trying to access auth pages → role-based home
    if (hasToken && isPublicRoute && location != AppRoutes.splash) {
      final sl = GetIt.instance;
      if (sl.isRegistered<CurrentUserProvider>()) {
        final user = sl<CurrentUserProvider>().user;
        if (user != null && user.role == 'vendor') {
          return AppRoutes.vendorHome;
        }
      }
      return AppRoutes.home;
    }

    // 3. KYC gating — redirect unverified users away from protected routes
    if (hasToken && !isPublicRoute && !_kycExemptRoutes.contains(location)) {
      final sl = GetIt.instance;
      if (sl.isRegistered<CurrentUserProvider>()) {
        final user = sl<CurrentUserProvider>().user;
        if (user != null && !user.phoneVerified) {
          return AppRoutes.kycVerification;
        }
      }
    }

    return null; // no redirect
  },

  routes: [
    // ── Auth flow ──
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(
      path: AppRoutes.walkthrough,
      builder: (context, state) => WalkThrough(),
    ),
    GoRoute(path: AppRoutes.login, builder: (context, state) => LoginView()),
    GoRoute(
      path: AppRoutes.signup,
      builder: (context, state) => const SignupView(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) {
        final extra = state.extra;
        bool showSuccess = false;
        bool isForgotPassword = false;
        if (extra is bool) {
          showSuccess = extra;
        } else if (extra is Map<String, dynamic>) {
          showSuccess = extra['showSuccessOnVerify'] as bool? ?? false;
          isForgotPassword = extra['isForgotPassword'] as bool? ?? false;
        }
        return OTPView(
          showSuccessOnVerify: showSuccess,
          isForgotPassword: isForgotPassword,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return ResetPasswordView(phone: phone);
      },
    ),

    // ── KYC verification gate ──
    GoRoute(
      path: AppRoutes.kycVerification,
      builder: (context, state) => const KycVerificationView(),
    ),

    // ── Consumer home shell ──
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Home(),
    ),

    // ── Consumer: restaurant discovery ──
    GoRoute(
      path: '/restaurant/:id',
      builder: (context, state) => RestaurantDetailView(
        restaurantId: state.pathParameters['id']!,
      ),
    ),

    // ── Consumer: cart ──
    GoRoute(
      path: AppRoutes.cart,
      builder: (context, state) => const CartView(),
    ),

    // ── Consumer: checkout ──
    GoRoute(
      path: AppRoutes.checkout,
      builder: (context, state) => const CheckoutView(),
    ),

    // ── Consumer: order tracking ──
    GoRoute(
      path: AppRoutes.trackOrder,
      builder: (context, state) {
        // Accept orderId via `extra` (from placeOrder) or fall back to legacy TrackOrder
        final orderId = state.extra as String?;
        if (orderId != null) {
          return OrderTrackingView(orderId: orderId);
        }
        return TrackOrder();
      },
    ),

    // ── Consumer: search ──
    GoRoute(
      path: AppRoutes.consumerSearch,
      builder: (context, state) => const ConsumerSearchView(),
    ),

    // ── Consumer: notifications ──
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const ConsumerNotificationsScreen(),
    ),

    // ── Profile ──
    GoRoute(path: AppRoutes.profile, builder: (context, state) => Profile()),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => EditProfile(),
    ),

    // ── Courier / delivery ──
    GoRoute(
      path: AppRoutes.sendPackages,
      builder: (context, state) => const SendParcelView(),
    ),
    GoRoute(
      path: AppRoutes.foodDelivery,
      builder: (context, state) => GetFoodDeliver(),
    ),
    GoRoute(
      path: AppRoutes.groceryDelivery,
      builder: (context, state) => GetGroceryDeliver(),
    ),
    GoRoute(
      path: AppRoutes.restaurantItems,
      builder: (context, state) => RestaurantItems(),
    ),

    // ── Legacy cart & payment ──
    GoRoute(path: AppRoutes.payment, builder: (context, state) => Payment()),

    // ── Route map (receives coordinates via query params) ──
    GoRoute(
      path: AppRoutes.routeMap,
      builder: (context, state) {
        final srcLat =
            double.parse(state.uri.queryParameters['srcLat'] ?? '0');
        final srcLng =
            double.parse(state.uri.queryParameters['srcLng'] ?? '0');
        final dstLat =
            double.parse(state.uri.queryParameters['dstLat'] ?? '0');
        final dstLng =
            double.parse(state.uri.queryParameters['dstLng'] ?? '0');
        return RouteMap(
          sourceLat: srcLat,
          sourceLang: srcLng,
          destinationLat: dstLat,
          destinationLang: dstLng,
        );
      },
    ),

    // ── Vendor ──
    GoRoute(
      path: AppRoutes.vendorHome,
      builder: (context, state) => const VendorHome(),
    ),
    GoRoute(
      path: AppRoutes.vendorRegistration,
      builder: (context, state) => const VendorRegistrationView(),
    ),
    GoRoute(
      path: AppRoutes.vendorKyc,
      builder: (context, state) =>
          VendorKycView(initialStep: state.extra as int? ?? 0),
    ),
    GoRoute(
      path: AppRoutes.vendorPaymentMethods,
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: AppRoutes.vendorPayout,
      builder: (context, state) => const VendorPayoutView(),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      builder: (context, state) => const CourierWalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.vendorWallet,
      builder: (context, state) => const VendorWalletScreen(),
    ),

    // ── Other ──
    GoRoute(
      path: AppRoutes.inviteFriend,
      builder: (context, state) => InviteFriend(),
    ),
    GoRoute(
      path: AppRoutes.helpSupport,
      builder: (context, state) => const HelpSupportView(),
    ),

    // ── Report a problem ──
    GoRoute(
      path: AppRoutes.reportFlow,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is ReportFlowArgs
            ? extra
            : const ReportFlowArgs(role: ReportRole.customer);
        return ReportFlowView(args: args);
      },
    ),
    GoRoute(
      path: AppRoutes.myReports,
      builder: (context, state) {
        final role = state.extra is ReportRole
            ? state.extra as ReportRole
            : ReportRole.customer;
        return MyReportsView(role: role);
      },
    ),
    GoRoute(
      path: '/report/history/:id',
      builder: (context, state) {
        final role = state.extra is ReportRole
            ? state.extra as ReportRole
            : ReportRole.customer;
        return ReportDetailView(
          reportId: state.pathParameters['id']!,
          role: role,
        );
      },
    ),
  ],
);
