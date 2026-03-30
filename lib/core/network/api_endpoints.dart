/// Centralised registry of every API path used in the application.
///
/// Rules:
///   - Fixed paths  → `static const String`.
///   - Dynamic paths (contain an ID segment) → `static String` method.
///
/// Usage:
/// ```dart
/// dio.post(ApiEndpoints.customerSignup, data: body);
/// dio.get(ApiEndpoints.customerDetails(userId));
/// dio.patch(ApiEndpoints.vendorOrderStatus(orderId), data: body);
/// ```
abstract final class ApiEndpoints {
  // ─── Authentication ────────────────────────────────────────────────────────
  static const String signup = '/auth/register';
  static const String login = '/auth/login';
  static const String otpSend = '/otp/send';
  static const String otpVerify = '/otp/verify';

  /// `POST /customers/details/:id`
  static String customerDetails(String id) => '/customers/details/$id';

  // ─── Vendor Registration ───────────────────────────────────────────────────
  static const String vendorRegister = '/vendors/register';
  static const String vendorDocUpload = '/vendors/documents/upload';
  static const String vendorOtpSend = '/vendors/otp/send';
  static const String vendorOtpVerify = '/vendors/otp/verify';

  // ─── Vendor Dashboard ──────────────────────────────────────────────────────
  static const String vendorDashStats = '/vendors/dashboard/stats';
  static const String vendorOrders = '/vendors/orders';
  static const String vendorStoreStatus = '/vendors/store/status';
  static const String vendorMenu = '/vendors/menu';
  static const String vendorEarnings = '/vendors/earnings';
  static const String vendorProfile = '/vendors/profile';
  static const String vendorAccount = '/vendors/account';

  /// `PATCH /vendors/orders/:orderId/status`
  static String vendorOrderStatus(String orderId) =>
      '/vendors/orders/$orderId/status';

  /// `PATCH /vendors/menu/:itemId/availability`
  static String vendorMenuItemAvailability(String itemId) =>
      '/vendors/menu/$itemId/availability';

  /// `PUT /vendors/menu/:id`  |  `DELETE /vendors/menu/:id`
  static String vendorMenuItem(String id) => '/vendors/menu/$id';

  // ─── Vendor Payment Methods ────────────────────────────────────────────────
  static const String vendorPaymentMethods = '/vendors/payment-methods';

  /// `POST /vendors/payment-methods/:id/send-otp`
  static String vendorPaymentMethodSendOtp(String id) =>
      '/vendors/payment-methods/$id/send-otp';

  /// `POST /vendors/payment-methods/:id/verify-otp`
  static String vendorPaymentMethodVerifyOtp(String id) =>
      '/vendors/payment-methods/$id/verify-otp';

  // ─── Vendor Wallet ─────────────────────────────────────────────────────────
  static const String vendorWallet = '/vendors/wallet';
  static const String vendorWalletTransactions = '/vendors/wallet/transactions';
  static const String vendorWalletWithdraw = '/vendors/wallet/withdraw';
}
