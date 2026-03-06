/// Centralized route path constants for the entire app.
///
/// Usage:
///   context.go(AppRoutes.home);
///   context.push(AppRoutes.profile);
///   context.push(AppRoutes.routeMap(lat1, lng1, lat2, lng2));
abstract final class AppRoutes {
  // ── Auth flow ──
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String walkthrough = '/walkthrough';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';

  // ── Main app (bottom bar shell) ──
  static const String home = '/home';
  static const String search = '/search';
  static const String orders = '/orders';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';

  // ── Profile ──
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // ── Courier / delivery ──
  static const String sendPackages = '/send-packages';
  static const String foodDelivery = '/food-delivery';
  static const String groceryDelivery = '/grocery-delivery';
  static const String restaurantItems = '/restaurant-items';

  // ── Cart & payment ──
  static const String cart = '/cart';
  static const String payment = '/payment';

  // ── Orders detail ──
  static const String trackOrder = '/orders/track';

  // ── Route map (with query params) ──
  static const String routeMap = '/route-map';

  /// Build route map path with coordinates as query parameters.
  static String routeMapWith({
    required double sourceLat,
    required double sourceLng,
    required double destLat,
    required double destLng,
  }) =>
      '$routeMap?srcLat=$sourceLat&srcLng=$sourceLng&dstLat=$destLat&dstLng=$destLng';

  // ── Vendor ──
  static const String vendorHome = '/vendor';
  static const String vendorRegistration = '/vendor-registration';

  // ── Other ──
  static const String inviteFriend = '/invite-friend';
}
