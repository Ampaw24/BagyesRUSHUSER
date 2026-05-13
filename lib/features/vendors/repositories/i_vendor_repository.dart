import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_profile.dart';

/// Contract for all vendor self-service API operations.
///
/// Every method returns [ResultFuture<T>] — an [Either] of [Failure] (left)
/// or the success value (right) — so callers never touch raw exceptions.
abstract interface class IVendorRepository {
  // ── Profile ──────────────────────────────────────────────────────────────────

  /// Fetch the authenticated vendor's own profile.
  ResultFuture<VendorProfile> getVendorProfile();

  /// Partially update the vendor profile (PATCH).
  /// [data] contains only the fields to change (snake_case keys).
  ResultFuture<VendorProfile> updateVendorProfile(Map<String, dynamic> data);

  // ── Menu Items ────────────────────────────────────────────────────────────────

  /// List all menu items for the authenticated vendor.
  ResultFuture<List<MenuItem>> getMenuItems();

  /// Create a new menu item.
  /// [data] must include at minimum: name, price, category.
  ResultFuture<MenuItem> createMenuItem(Map<String, dynamic> data);

  /// Full or partial update of a menu item by [id].
  ResultFuture<MenuItem> updateMenuItem(String id, Map<String, dynamic> data);

  /// Toggle a menu item's availability (is_available flag).
  ResultFuture<MenuItem> toggleMenuItemAvailability(
    String id,
    bool isAvailable,
  );

  /// Permanently delete a menu item by [id].
  ResultFuture<bool> deleteMenuItem(String id);

  // ── Orders ────────────────────────────────────────────────────────────────────

  /// List vendor orders, optionally filtered by [status].
  /// status values: 'new' | 'preparing' | 'rider_assigned' | 'completed' | 'cancelled'
  ResultFuture<List<VendorOrder>> getOrders({String? status});

  /// Fetch a single order by [orderId].
  ResultFuture<VendorOrder> getOrderById(String orderId);

  /// Update an order's status (accept, reject, mark ready, etc.).
  /// [status] must be one of the accepted status strings from the API.
  ResultFuture<VendorOrder> updateOrderStatus(String orderId, String status);
}
