import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/presentation/splash_screen.dart';
import 'package:bagyesrushappusernew/presentation/bottom_bar.dart';
import 'package:bagyesrushappusernew/presentation/orders/track_order.dart';
import 'package:bagyesrushappusernew/presentation/profile/profile.dart';
import 'package:bagyesrushappusernew/presentation/profile/edit_profile.dart';
import 'package:bagyesrushappusernew/presentation/courier/send_packages.dart';
import 'package:bagyesrushappusernew/presentation/courier/get_food_deliver.dart';
import 'package:bagyesrushappusernew/presentation/courier/get_grocery_deliver.dart';
import 'package:bagyesrushappusernew/presentation/courier/restaurant_items.dart';
import 'package:bagyesrushappusernew/presentation/courier/route_map.dart';
import 'package:bagyesrushappusernew/presentation/cart_address/cart.dart';
import 'package:bagyesrushappusernew/presentation/payment/payment.dart';
import 'package:bagyesrushappusernew/presentation/invite_friend/invite_friend.dart';
import 'package:bagyesrushappusernew/src/auth/views/login_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/signup_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/otp_view.dart';
import 'package:bagyesrushappusernew/src/auth/views/walkthrough_view.dart';
import 'package:bagyesrushappusernew/src/onboarding/views/onboarding_view.dart';
import 'package:bagyesrushappusernew/src/vendor_registration/views/vendor_registration_view.dart';
import 'package:bagyesrushappusernew/src/vendor/view/vendor_home.dart';

import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
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
    GoRoute(path: AppRoutes.otp, builder: (context, state) => OTPView()),

    // ── Main app (BottomBar manages its own tabs internally) ──
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const BottomBar(),
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
      builder: (context, state) => SendPackages(),
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

    // ── Cart & payment ──
    GoRoute(path: AppRoutes.cart, builder: (context, state) => Cart()),
    GoRoute(path: AppRoutes.payment, builder: (context, state) => Payment()),

    // ── Orders detail ──
    GoRoute(
      path: AppRoutes.trackOrder,
      builder: (context, state) => TrackOrder(),
    ),

    // ── Route map (receives coordinates via query params) ──
    GoRoute(
      path: AppRoutes.routeMap,
      builder: (context, state) {
        final srcLat = double.parse(state.uri.queryParameters['srcLat'] ?? '0');
        final srcLng = double.parse(state.uri.queryParameters['srcLng'] ?? '0');
        final dstLat = double.parse(state.uri.queryParameters['dstLat'] ?? '0');
        final dstLng = double.parse(state.uri.queryParameters['dstLng'] ?? '0');
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

    // ── Other ──
    GoRoute(
      path: AppRoutes.inviteFriend,
      builder: (context, state) => InviteFriend(),
    ),
  ],
);
