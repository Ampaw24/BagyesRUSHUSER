import 'package:dartz/dartz.dart';
import '../../../core/errors/failure.dart';
import '../../../features/consumer/restaurant/domain/entities/addon.dart';
import '../model/vendor_order.dart';
import '../model/menu_item.dart';
import '../model/earnings_data.dart';
import '../model/vendor_profile.dart';

/// Contract for all vendor dashboard API operations.
abstract class VendorDashboardRepository {
  // ── Dashboard ──
  Future<Either<Failure, Map<String, dynamic>>> fetchDashboardStats();
  Future<Either<Failure, List<VendorOrder>>> fetchActiveOrders();
  Future<Either<Failure, bool>> toggleStoreStatus(bool isOpen);

  // ── Orders ──
  // The backend exposes 7 separate action routes rather than one generic
  // status-update endpoint — each method below hits its own route.
  Future<Either<Failure, List<VendorOrder>>> fetchAllOrders({String? status});
  Future<Either<Failure, VendorOrder>> acceptOrder(String orderId);
  Future<Either<Failure, VendorOrder>> rejectOrder(String orderId);
  Future<Either<Failure, VendorOrder>> markPreparing(String orderId);
  Future<Either<Failure, VendorOrder>> markReady(String orderId);
  Future<Either<Failure, VendorOrder>> markOutForDelivery(String orderId);
  Future<Either<Failure, VendorOrder>> markDelivered(String orderId);
  Future<Either<Failure, VendorOrder>> cancelOrder(String orderId);

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
  Future<Either<Failure, void>> updateOperatingHours(
    Map<String, DayHours> weeklyHours,
  );

  // ── Account ──
  Future<Either<Failure, bool>> deleteVendorAccount();
}
