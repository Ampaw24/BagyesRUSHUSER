import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

class CartRepository {
  const CartRepository({required Dio client}) : _client = client;

  final Dio _client;

  /// `GET /customer/carts` — one cart per vendor.
  ResultFuture<List<CartModel>> getCarts() async {
    appLogger.d('CartRepository.getCarts → initiated');
    try {
      final response = await _client.get(ApiEndpoints.customerCarts);

      if ([200, 201].contains(response.statusCode)) {
        final carts = _extractList(response.data)
            .map((e) => CartModel.fromJson(e as DataMap))
            .toList();
        appLogger.i('CartRepository.getCarts → loaded ${carts.length} carts');
        return Right(carts);
      }

      appLogger.w('CartRepository.getCarts → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CartRepository.getCarts → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'getCarts',
      );
    }
  }

  /// `GET /customer/carts/:vendorId`
  ResultFuture<CartModel> getCart(String vendorId) async {
    appLogger.d('CartRepository.getCart → vendorId=$vendorId');
    try {
      final response =
          await _client.get(ApiEndpoints.customerCartByVendor(vendorId));

      if ([200, 201].contains(response.statusCode)) {
        final cart = CartModel.fromJson(_dataMap(response.data));
        appLogger.i(
          'CartRepository.getCart → success vendorId=$vendorId '
          'items=${cart.items.length}',
        );
        return Right(cart);
      }

      appLogger.w('CartRepository.getCart → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      // No cart created for this vendor yet — treat as empty, not an error.
      if (e.response?.statusCode == 404) {
        appLogger.d('CartRepository.getCart → 404, treating as empty cart');
        return Right(CartModel.empty(vendorId));
      }
      appLogger.e('CartRepository.getCart → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'getCart',
      );
    }
  }

  /// `POST /customer/carts/:vendorId/items`
  ResultFuture<void> addItem({
    required String vendorId,
    required int menuItemId,
    int quantity = 1,
    String? notes,
    List<int> addonOptionIds = const [],
  }) async {
    appLogger.d(
      'CartRepository.addItem → vendorId=$vendorId menuItemId=$menuItemId',
    );
    try {
      final response = await _client.post(
        ApiEndpoints.customerCartItems(vendorId),
        data: {
          'menu_item_id': menuItemId,
          'quantity': quantity,
          if (notes != null) 'notes': notes,
          if (addonOptionIds.isNotEmpty) 'addon_option_ids': addonOptionIds,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('CartRepository.addItem → success');
        return const Right(null);
      }

      appLogger.w('CartRepository.addItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CartRepository.addItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'addItem',
      );
    }
  }

  /// `PATCH /customer/cart-items/:id`
  ResultFuture<void> updateItem(
    String itemId, {
    int? quantity,
    String? notes,
    List<int>? addonOptionIds,
  }) async {
    appLogger.d('CartRepository.updateItem → itemId=$itemId');
    try {
      final response = await _client.patch(
        ApiEndpoints.customerCartItemById(itemId),
        data: {
          if (quantity != null) 'quantity': quantity,
          if (notes != null) 'notes': notes,
          if (addonOptionIds != null) 'addon_option_ids': addonOptionIds,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('CartRepository.updateItem → success');
        return const Right(null);
      }

      appLogger.w('CartRepository.updateItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CartRepository.updateItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'updateItem',
      );
    }
  }

  /// `DELETE /customer/cart-items/:id`
  ResultFuture<void> removeItem(String itemId) async {
    appLogger.d('CartRepository.removeItem → itemId=$itemId');
    try {
      final response =
          await _client.delete(ApiEndpoints.customerCartItemById(itemId));

      if ([200, 201, 204].contains(response.statusCode)) {
        appLogger.i('CartRepository.removeItem → success');
        return const Right(null);
      }

      appLogger.w('CartRepository.removeItem → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CartRepository.removeItem → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'removeItem',
      );
    }
  }

  /// `DELETE /customer/carts/:vendorId`
  ResultFuture<void> clearCart(String vendorId) async {
    appLogger.d('CartRepository.clearCart → vendorId=$vendorId');
    try {
      final response =
          await _client.delete(ApiEndpoints.customerCartByVendor(vendorId));

      if ([200, 201, 204].contains(response.statusCode)) {
        appLogger.i('CartRepository.clearCart → success');
        return const Right(null);
      }

      appLogger.w('CartRepository.clearCart → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('CartRepository.clearCart → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'CartRepository',
        methodName: 'clearCart',
      );
    }
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  DataMap _dataMap(dynamic body) {
    if (body is DataMap) {
      final d = body['data'];
      if (d is DataMap) return d;
      return body;
    }
    return const {};
  }

  /// Mirrors the defensive envelope-unwrapping used across the other
  /// repositories in this app: accepts a bare list, `{ data: [...] }`, or
  /// `{ data: { carts | items | data: [...] } }`.
  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is DataMap) {
      final d = body['data'];
      if (d is List) return d;
      if (d is DataMap) {
        for (final key in ['carts', 'items', 'data']) {
          final nested = d[key];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }
}
