import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../../../src/restaurant/models/addon.dart';
import '../model/vendor_dashboard_stats.dart';
import '../model/vendor_order.dart';
import '../model/vendor_order_stats.dart';
import '../model/menu_item.dart';
import '../model/earnings_data.dart';
import '../model/vendor_profile.dart';

/// Contract for all vendor dashboard API operations.
abstract class VendorDashboardRepository {
  // ── Dashboard ──
  Future<Either<Failure, VendorDashboardStats>> fetchDashboardStats();
  Future<Either<Failure, List<VendorOrder>>> fetchActiveOrders();
  /// Flips the store's open/closed status server-side. Returns the
  /// resulting `isOpen` state from the response — the caller doesn't
  /// need to (and shouldn't) tell the backend what to set it to.
  Future<Either<Failure, bool>> toggleStoreStatus();

  // ── Orders ──
  // The backend exposes 7 separate action routes rather than one generic
  // status-update endpoint — each method below hits its own route.
  Future<Either<Failure, List<VendorOrder>>> fetchAllOrders({
    String? status,
    String? type,
    String? paymentStatus,
    String? search,
    DateTime? from,
    DateTime? to,
    int? perPage,
  });

  /// `GET /vendor/me/orders/stats`
  Future<Either<Failure, VendorOrderStats>> fetchOrderStats();

  /// `GET /vendor/me/orders/:id`
  Future<Either<Failure, VendorOrder>> fetchOrderById(String orderId);

  /// `estimatedPrepMinutes` is optional (1-600).
  Future<Either<Failure, VendorOrder>> acceptOrder(
    String orderId, {
    int? estimatedPrepMinutes,
  });

  /// `reason` is required (5-255 chars).
  Future<Either<Failure, VendorOrder>> rejectOrder(
    String orderId, {
    required String reason,
  });

  Future<Either<Failure, VendorOrder>> markPreparing(String orderId);
  Future<Either<Failure, VendorOrder>> markReady(String orderId);
  Future<Either<Failure, VendorOrder>> markOutForDelivery(String orderId);
  Future<Either<Failure, VendorOrder>> markDelivered(String orderId);

  /// `reason` is required (5-255 chars).
  Future<Either<Failure, VendorOrder>> cancelOrder(
    String orderId, {
    required String reason,
  });

  // ── Menu ──
  Future<Either<Failure, List<MenuItem>>> fetchMenuItems();
  Future<Either<Failure, MenuItem>> toggleMenuItemAvailability(
    String itemId,
    bool isAvailable,
  );
  Future<Either<Failure, MenuItem>> toggleMenuItemPopular(
    String id,
    bool isPopular,
  );
  Future<Either<Failure, MenuItem>> createMenuItem(Map<String, dynamic> data);
  Future<Either<Failure, MenuItem>> updateMenuItem(
    String id,
    Map<String, dynamic> data,
  );
  Future<Either<Failure, bool>> deleteMenuItem(String id);

  /// Full-replace all addon groups for a menu item (PUT).
  Future<Either<Failure, MenuItem>> upsertAddonGroups(
    String menuItemId,
    List<AddonGroup> groups,
  );

  /// Remove a single addon group from a menu item.
  Future<Either<Failure, bool>> deleteAddonGroup(
    String menuItemId,
    String groupId,
  );

  // ── Earnings ──
  Future<Either<Failure, EarningsData>> fetchEarnings({String? period});

  // ── Settings / Profile ──
  Future<Either<Failure, VendorProfile>> fetchVendorProfile();
  Future<Either<Failure, VendorProfile>> updateVendorProfile(
    Map<String, dynamic> data,
  );

  /// Submits the operational details (opening/closing time, operating days,
  /// estimated prep time) required to complete vendor KYC, in one call to
  /// `PUT operationsKyc`.
  Future<Either<Failure, VendorProfile>> submitOperationalKyc({
    required String openingTime,
    required String closingTime,
    required List<String> operatingDays,
    int? estimatedPrepTimeMinutes,
  });

  /// Uploads a single vendor document (e.g. `logo`, `owner_id`,
  /// `business_registration_certificate`, `food_safety_license`) to
  /// `POST /vendor/me/documents/:type`. Returns the resulting profile with
  /// its updated document URLs/status.
  Future<Either<Failure, VendorProfile>> uploadVendorDocument(
    String type,
    String filePath,
  );

  /// Fetches a single uploaded document's status/details.
  /// `GET /vendor/me/documents/:type`
  Future<Either<Failure, Map<String, dynamic>>> fetchVendorDocument(
    String type,
  );

  /// Uploads a display image (e.g. `logo`, `cover`) to
  /// `POST /vendor/me/images/:type`. Returns the resulting profile with
  /// its updated image URLs.
  Future<Either<Failure, VendorProfile>> uploadVendorImage(
    String type,
    String filePath,
  );

  /// Updates bank/mobile-money payout details via `PUT /vendor/me/payout`.
  Future<Either<Failure, VendorProfile>> updateVendorPayout(
    Map<String, dynamic> data,
  );

  /// Submits the completed profile for admin review.
  /// `POST /vendor/me/submit-review`
  Future<Either<Failure, VendorProfile>> submitVendorForReview();

  // ── Account ──
  Future<Either<Failure, bool>> deleteVendorAccount();
}
