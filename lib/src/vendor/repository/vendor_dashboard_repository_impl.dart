import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/network_utility.dart';
import '../../../features/consumer/restaurant/domain/entities/addon.dart';
import '../model/vendor_order.dart';
import '../model/menu_item.dart';
import '../model/earnings_data.dart';
import '../model/vendor_profile.dart';
import 'vendor_dashboard_repository.dart';

class VendorDashboardRepositoryImpl implements VendorDashboardRepository {
  final NetworkUtility _networkUtility;

  VendorDashboardRepositoryImpl(this._networkUtility);

  ///  ── Dashboard ───────────────────────────

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchDashboardStats() async {
    try {
      final response = await _networkUtility.dio.get(ApiEndpoints.vendorDashStats);
      if (response.data['success'] == true) {
        return Right(response.data['data'] as Map<String, dynamic>);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to fetch stats'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchActiveOrders() async {
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorOrders,
        queryParameters: {'status': 'active'},
      );
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List<dynamic>)
            .map((e) => VendorOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to fetch orders'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleStoreStatus(bool isOpen) async {
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorStoreStatus,
        data: {'is_open': isOpen},
      );
      if (response.data['success'] == true) {
        return Right(isOpen);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to toggle status'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Orders ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<VendorOrder>>> fetchAllOrders({
    String? status,
  }) async {
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorOrders,
        queryParameters: {'status': status},
      );
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List<dynamic>)
            .map((e) => VendorOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to fetch orders'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorOrder>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorOrderStatus(orderId),
        data: {'status': status},
      );
      if (response.data['success'] == true) {
        return Right(
          VendorOrder.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to update order status',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Menu ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<MenuItem>>> fetchMenuItems() async {
    try {
      final response = await _networkUtility.dio.get(ApiEndpoints.vendorMenu);
      if (response.data['success'] == true) {
        final list = (response.data['data'] as List<dynamic>)
            .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(list);
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to fetch menu items',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> toggleMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    try {
      final response = await _networkUtility.dio.patch(
        ApiEndpoints.vendorMenuItemAvailability(itemId),
        data: {'is_available': isAvailable},
      );
      if (response.data['success'] == true) {
        return Right(
          MenuItem.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to update availability',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> createMenuItem(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.post(
        ApiEndpoints.vendorMenu,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(
          MenuItem.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to create menu item',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> updateMenuItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorMenuItem(id),
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(
          MenuItem.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to update menu item',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMenuItem(String id) async {
    try {
      final response = await _networkUtility.dio.delete(
        ApiEndpoints.vendorMenuItem(id),
      );
      if (response.data['success'] == true) {
        return const Right(true);
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to delete menu item',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItem>> upsertAddonGroups(
    String menuItemId,
    List<AddonGroup> groups,
  ) async {
    try {
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorMenuItemAddonGroups(menuItemId),
        data: {'addon_groups': groups.map((g) => g.toJson()).toList()},
      );
      if (response.data['success'] == true) {
        return Right(
          MenuItem.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to update addon groups',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAddonGroup(
    String menuItemId,
    String groupId,
  ) async {
    try {
      final response = await _networkUtility.dio.delete(
        ApiEndpoints.vendorMenuItemAddonGroup(menuItemId, groupId),
      );
      if (response.data['success'] == true) {
        return const Right(true);
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to delete addon group',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Earnings ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, EarningsData>> fetchEarnings({String? period}) async {
    try {
      final response = await _networkUtility.dio.get(
        ApiEndpoints.vendorEarnings,
        queryParameters: {'period': period},
      );
      if (response.data['success'] == true) {
        return Right(
          EarningsData.fromJson(response.data['data'] as Map<String, dynamic>),
        );
      }
      return Left(
        ServerFailure(
          response.data['message'] ?? 'Failed to fetch earnings',
        ),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Settings / Profile ────────────────────────────────────────────────

  @override
  Future<Either<Failure, VendorProfile>> fetchVendorProfile() async {
    try {
      final response = await _networkUtility.dio.get(ApiEndpoints.vendorProfile);
      if (response.data['success'] == true) {
        return Right(
          VendorProfile.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to fetch profile'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VendorProfile>> updateVendorProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _networkUtility.dio.put(
        ApiEndpoints.vendorProfile,
        data: data,
      );
      if (response.data['success'] == true) {
        return Right(
          VendorProfile.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to update profile'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Account ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> deleteVendorAccount() async {
    try {
      final response = await _networkUtility.dio.delete(ApiEndpoints.vendorAccount);
      if (response.data['success'] == true) {
        return const Right(true);
      }
      return Left(
        ServerFailure(response.data['message'] ?? 'Failed to delete account'),
      );
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
