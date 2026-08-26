/// Centralised registry of every API path used in the application.
///
/// Rules:
///   - Fixed paths  → `static const String`.
///   - Dynamic paths (contain an ID segment) → `static String` method.
///
/// Usage:
/// ```dart
/// dio.post(ApiEndpoints.signup, data: body);
/// dio.get(ApiEndpoints.profile);
/// dio.patch(ApiEndpoints.vendorOrderAccept(orderId));
/// ```
abstract final class ApiEndpoints {
  // ─── Authentication ────────────────────────────────────────────────────────
  static const String signup = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String refreshToken = '/auth/refresh-token';

  /// Shared phone-verification pair — used by both customer and vendor OTP flows.
  static const String phoneSendCode = '/phone/send-code';
  static const String phoneVerify = '/phone/verify';
  static const String otpSend = phoneSendCode;
  static const String otpVerify = phoneVerify;

  /// `POST /password/forgot` — public endpoint, requests the OTP that starts
  /// the login screen's "forgot password" flow. Body: `{ phone }`.
  static const String passwordForgot = '/password/forgot';

  /// `POST /password/reset` — consumes the [passwordForgot]-issued,
  /// [phoneVerify]-confirmed OTP session and sets a new password.
  static const String forgotPassword = '/password/reset';

  /// `POST /password/change` — authenticated user changing their own password.
  static const String passwordChange = '/password/change';

  static const String items = '/items';
  static const String deviceToken = '/device-tokens';

  /// `GET /profile` — role-agnostic session-restore endpoint.
  static const String profile = '/profile';

  /// `PUT /customer/me`
  static const String customerMe = '/customer/me';

  /// `POST /customer/me/avatar` (multipart)
  static const String customerAvatar = '/customer/me/avatar';

  // ─── Vendor Registration ───────────────────────────────────────────────────.
  static const String vendorRegister = '/register';
  static const String vendorDocUpload = '/vendors/documents/upload';
  static const String vendorOtpSend = phoneSendCode;
  static const String vendorOtpVerify = phoneVerify;

  // ─── Vendor Dashboard ──────────────────────────────────────────────────────
  static const String vendorDashStats = '/vendor/me/dashboard';
  static const String vendorOrders = '/vendor/me/orders';
  static const String vendorStoreStatus = '/vendor/me/toggle-open';
  static const String vendorMenu = '/vendor/me/menu-items';
  static const String vendorEarnings = '/vendors/earnings';
  static const String vendorProfile = '/vendor/me';
  static const String vendorAccount = '/vendors/account';

  /// `PUT /vendor/me/hours` — accepts `opening_time`, `closing_time`,
  /// `operating_days`, `estimated_prep_time_minutes`. No per-day hours.
  static const String operationsKyc = '/vendor/me/hours';

  /// `POST /vendor/me/documents/:type` (multipart, field: `document`)
  static String vendorMeDocumentUpload(String type) =>
      '/vendor/me/documents/$type';

  /// `GET /vendor/me/documents/:type`
  static String vendorMeDocumentShow(String type) =>
      '/vendor/me/documents/$type';

  /// `POST /vendor/me/images/:type` (multipart, field: `image`)
  static String vendorMeImageUpload(String type) => '/vendor/me/images/$type';

  /// `PUT /vendor/me/payout`
  static const String vendorPayout = '/vendor/me/payout';

  /// `POST /vendor/me/submit-review`
  static const String vendorSubmitReview = '/vendor/me/submit-review';

  //home-page Path 1
  static const String adsBanners = '/banners';
  static const String vendors = '/vendors';

  /// `GET /vendors/featured`
  static const String vendorsFeatured = '/vendors/featured';

  /// `GET /vendors/nearby?lat=&lng=`
  static const String vendorsNearby = '/vendors/nearby';

  /// `GET /vendor/me/orders/:id`
  static String vendorOrderById(String orderId) => '$vendorOrders/$orderId';

  /// `PATCH /vendor/me/orders/:id/accept`
  static String vendorOrderAccept(String orderId) =>
      '$vendorOrders/$orderId/accept';

  /// `PATCH /vendor/me/orders/:id/reject`
  static String vendorOrderReject(String orderId) =>
      '$vendorOrders/$orderId/reject';

  /// `PATCH /vendor/me/orders/:id/preparing`
  static String vendorOrderPreparing(String orderId) =>
      '$vendorOrders/$orderId/preparing';

  /// `PATCH /vendor/me/orders/:id/ready`
  static String vendorOrderReady(String orderId) =>
      '$vendorOrders/$orderId/ready';

  /// `PATCH /vendor/me/orders/:id/out-for-delivery`
  static String vendorOrderOutForDelivery(String orderId) =>
      '$vendorOrders/$orderId/out-for-delivery';

  /// `PATCH /vendor/me/orders/:id/delivered`
  static String vendorOrderDelivered(String orderId) =>
      '$vendorOrders/$orderId/delivered';

  /// `PATCH /vendor/me/orders/:id/cancel`
  static String vendorOrderCancel(String orderId) =>
      '$vendorOrders/$orderId/cancel';

  /// `PATCH /vendor/me/menu-items/:itemId/toggle-availability`
  static String vendorMenuItemAvailability(String itemId) =>
      '/vendor/me/menu-items/$itemId/toggle-availability';

  /// `GET /vendor/me/menu-items/:id` | `PUT` | `DELETE`
  static String vendorMenuItem(String id) => '/vendor/me/menu-items/$id';

  /// `POST /vendor/me/menu-items/:id/image` (multipart)
  static String vendorMenuItemImage(String id) =>
      '/vendor/me/menu-items/$id/image';

  /// `GET /PUT /vendors/menu/:itemId/addon-groups`
  static String vendorMenuItemAddonGroups(String itemId) =>
      '/vendors/menu/$itemId/addon-groups';

  /// `DELETE /vendors/menu/:itemId/addon-groups/:groupId`
  static String vendorMenuItemAddonGroup(String itemId, String groupId) =>
      '/vendors/menu/$itemId/addon-groups/$groupId';

  /// `GET /vendors/:vendorId/menu/:itemId/addon-groups`
  static String consumerMenuItemAddons(String vendorId, String itemId) =>
      '/vendors/$vendorId/menu/$itemId/addon-groups';

  // ─── Vendor Payment Methods ────────────────────────────────────────────────
  static const String vendorPaymentMethods = '/vendors/payment-methods';

  /// `DELETE /vendors/payment-methods/:id`
  static String vendorPaymentMethodById(String id) =>
      '$vendorPaymentMethods/$id';

  /// `PATCH /vendors/payment-methods/:id/default`
  static String vendorPaymentMethodDefault(String id) =>
      '$vendorPaymentMethods/$id/default';

  // ─── Customer Payment Methods ──────────────────────────────────────────────
  static const String customerPaymentMethods = '/customer/payment-methods';

  /// `DELETE /customer/payment-methods/:id`
  static String customerPaymentMethodById(String id) =>
      '$customerPaymentMethods/$id';

  /// `PATCH /customer/payment-methods/:id/default`
  static String customerPaymentMethodDefault(String id) =>
      '$customerPaymentMethods/$id/default';

  // ─── Payout Providers ──────────────────────────────────────────────────────
  /// `GET /payout-providers` — list of active bank/mobile-money payout
  /// providers. Optional `type` query param filters to 'bank' or
  /// 'mobile_money'. Public endpoint.
  static const String payoutProviders = '/payout-providers';

  // ─── Vendor Wallet ─────────────────────────────────────────────────────────
  static const String vendorWallet = '/vendors/wallet';
  static const String vendorWalletTransactions = '/vendors/wallet/transactions';
  static const String vendorWalletWithdraw = '/vendors/wallet/withdraw';

  // ─── Customer Home ─────────────────────────────────────────────────────────
  static const String categories = '/categories';
  static const String businessTypes = '/business-types';
  static const String customerOrders = '/customer/orders';

  /// `GET /vendors/:id`
  static String vendorById(String id) => '/vendors/$id';

  /// `GET /vendors/:id/menu`
  static String vendorMenuItems(String vendorId) => '/vendors/$vendorId/menu';

  /// `GET /customer/orders/:id`
  static String customerOrderById(String orderId) => '$customerOrders/$orderId';

  /// `PATCH /customer/orders/:id/cancel`
  static String customerOrderCancel(String orderId) =>
      '$customerOrders/$orderId/cancel';

  /// `POST /customer/orders/:id/pay`
  static String customerOrderPay(String orderId) =>
      '$customerOrders/$orderId/pay';

  /// `POST /customer/orders/:id/reorder`
  static String customerOrderReorder(String orderId) =>
      '$customerOrders/$orderId/reorder';

  /// `GET /customer/orders/:id/track`
  static String customerOrderTrack(String orderId) =>
      '$customerOrders/$orderId/track';

  /// `POST /customer/orders/:id/verify-payment`
  static String customerOrderVerifyPayment(String orderId) =>
      '$customerOrders/$orderId/verify-payment';

  /// `GET /categories/:id`
  static String categoryById(String id) => '/categories/$id';

  // ─── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  /// `DELETE /notifications/:id`
  static String notificationById(String id) => '/notifications/$id';

  /// `PATCH /notifications/:id/read`
  static String notificationRead(String id) => '/notifications/$id/read';

  // ─── Reports ────────────────────────────────────────────────────────────
  static const String customerReports = '/customer/reports';
  static const String vendorReports = '/vendor/me/reports';

  /// `GET /customer/reports/:id`
  static String customerReportById(String id) => '$customerReports/$id';

  /// `GET /vendor/me/reports/:id`
  static String vendorReportById(String id) => '$vendorReports/$id';

  // ─── Customer Parcels ──────────────────────────────────────────────────────
  static const String customerParcels = '/customer/parcels';
  static const String customerParcelPhotos = '/customer/parcels/photos';
  static const String customerParcelQuotes = '$customerParcels/quotes';

  /// `DELETE /customer/parcels/photos/:id`
  static String customerParcelPhotoById(String id) =>
      '$customerParcelPhotos/$id';

  /// `GET /customer/parcels/:id`
  static String customerParcelById(String id) => '$customerParcels/$id';

  /// `PATCH /customer/parcels/:id/cancel`
  static String customerParcelCancel(String id) =>
      '$customerParcels/$id/cancel';
}
