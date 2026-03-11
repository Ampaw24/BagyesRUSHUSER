import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Convenience navigation helpers accessible via `AppNavigator.toHome(context)`.
///
/// These wrap GoRouter calls so screens don't need to import route constants
/// or know the routing implementation details.
abstract final class AppNavigator {
  // ── Auth ──
  static void toOnboarding(BuildContext context) =>
      context.go(AppRoutes.onboarding);
  static void toLogin(BuildContext context) => context.go(AppRoutes.login);
  static void toSignup(BuildContext context) => context.push(AppRoutes.signup);
  static void toWalkthrough(BuildContext context) =>
      context.push(AppRoutes.walkthrough);
  static void toOtp(BuildContext context) => context.push(AppRoutes.otp);

  // ── Main ──
  static void toHome(BuildContext context) => context.go(AppRoutes.home);

  // ── Profile ──
  static void toProfile(BuildContext context) =>
      context.push(AppRoutes.profile);
  static void toEditProfile(BuildContext context) =>
      context.push(AppRoutes.editProfile);

  // ── Courier ──
  static void toSendPackages(BuildContext context) =>
      context.push(AppRoutes.sendPackages);
  static void toFoodDelivery(BuildContext context) =>
      context.push(AppRoutes.foodDelivery);
  static void toGroceryDelivery(BuildContext context) =>
      context.push(AppRoutes.groceryDelivery);
  static void toRestaurantItems(BuildContext context) =>
      context.push(AppRoutes.restaurantItems);

  // ── Cart & payment ──
  static void toCart(BuildContext context) => context.push(AppRoutes.cart);
  static void toPayment(BuildContext context) =>
      context.push(AppRoutes.payment);

  // ── Orders ──
  static void toTrackOrder(BuildContext context) =>
      context.push(AppRoutes.trackOrder);

  static void toRouteMap(
    BuildContext context, {
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) => context.push(
    AppRoutes.routeMapWith(
      sourceLat: sourceLat,
      sourceLng: sourceLng,
      destLat: destLat,
      destLng: destLng,
    ),
  );

  // ── Vendor ──
  static void toVendorHome(BuildContext context) =>
      context.go(AppRoutes.vendorHome);
  static void toVendorRegistration(BuildContext context) =>
      context.push(AppRoutes.vendorRegistration);
  static void toVendorPaymentMethods(BuildContext context) =>
      context.push(AppRoutes.vendorPaymentMethods);
  static void toVendorWallet(BuildContext context) =>
      context.push(AppRoutes.vendorWallet);

  // ── Other ──
  static void toInviteFriend(BuildContext context) =>
      context.push(AppRoutes.inviteFriend);
}
