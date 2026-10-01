import 'dart:async';

import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:bagyesrushappusernew/core/services/realtime_events.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/rider_location.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_state.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/delivery_location.dart';

class OrdersViewModel extends ViewModel<OrdersState> with SessionAware {
  OrdersViewModel(
    this._repository,
    this._realtimeService,
    CurrentUserProvider session,
  ) : super(const OrdersLoading()) {
    bindSession(session);
    _loadOrders();
    _orderStatusSub = _realtimeService.orderStatusEvents.listen(applyOrderStatusEvent);
    _riderLocationSub = _realtimeService.riderLocationEvents.listen(_applyRiderLocationEvent);
  }

  final ConsumerOrdersRepository _repository;
  final RealtimeService _realtimeService;
  StreamSubscription<OrderStatusEvent>? _orderStatusSub;
  StreamSubscription<RiderLocationEvent>? _riderLocationSub;

  /// Orders fetched one-off by id that aren't in the paged list (yet) — a
  /// just-created parcel, or a push-notification deep link to an older
  /// order. Kept apart from [OrdersLoaded.orders] so they never distort the
  /// list's ordering/pagination, but still resolvable via [orderById] and
  /// patched by realtime events.
  final Map<String, ConsumerOrder> _standalone = {};

  /// Orders the verify endpoint confirmed paid this session. [orderById]
  /// always reports them paid, so a lagging refresh can never bring back
  /// "Pay Now" for a charge that already went through.
  final Set<String> _confirmedPayments = {};

  /// Orders paid at the gateway but not yet confirmed by the server, with
  /// when that started. "Pay Now" stays disabled for these until the payment
  /// resolves or [paymentConfirmationWindow] passes, so an unconfirmed
  /// charge can't be paid twice.
  final Map<String, DateTime> _awaitingPayment = {};
  static const paymentConfirmationWindow = Duration(minutes: 3);

  /// Bumped by [onSignedOut] so a page request still in flight from the
  /// previous account can't land in the (now cleared) list.
  int _sessionGeneration = 0;

  /// Set once the list is cleared for a new session; [ensureLoaded] then
  /// fetches it again.
  bool _needsLoad = false;

  /// Loads the list if it was cleared by a sign-out since the last load —
  /// the constructor's initial load covers the first session.
  Future<void> ensureLoaded() async {
    if (!_needsLoad) return;
    _needsLoad = false;
    await _loadOrders();
  }

  @override
  void onSignedOut() {
    _sessionGeneration++;
    _needsLoad = true;
    _standalone.clear();
    _confirmedPayments.clear();
    _awaitingPayment.clear();
    emit(const OrdersLoading());
  }

  Future<void> _loadOrders() async {
    final generation = _sessionGeneration;
    try {
      final result = await _repository.getOrdersPaged(page: 1);
      if (generation != _sessionGeneration) return;
      emit(OrdersLoaded(
        orders: result.orders,
        hasMore: result.hasMore,
        currentPage: result.page,
      ));
    } catch (e) {
      if (generation != _sessionGeneration) return;
      emit(OrdersError(message: e.toString()));
    }
  }

  /// Pull-to-refresh: re-fetch page 1 and replace the list.
  Future<void> refresh() => _loadOrders();

  /// Infinite scroll on the Past tab.
  Future<void> loadMore() async {
    final current = state;
    if (current is! OrdersLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    emit(OrdersLoaded(
      orders: current.orders,
      hasMore: current.hasMore,
      isLoadingMore: true,
      currentPage: current.currentPage,
    ));

    final generation = _sessionGeneration;
    try {
      final result = await _repository.getOrdersPaged(page: current.currentPage + 1);
      if (generation != _sessionGeneration) return;
      emit(OrdersLoaded(
        orders: [...current.orders, ...result.orders],
        hasMore: result.hasMore,
        currentPage: result.page,
      ));
    } catch (_) {
      if (generation != _sessionGeneration) return;
      // Keep existing data; clear loading flag so the user can retry by
      // scrolling again.
      emit(OrdersLoaded(
        orders: current.orders,
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
    }
  }

  Future<ConsumerOrder> placeOrder({
    required String vendorId,
    required String paymentMethod,
    int? customerAddressId,
    DeliveryLocation? location,
    required int deliveryQuoteId,
    required bool useWallet,
    String? notes,
  }) async {
    final order = await _repository.placeOrder(
      vendorId: vendorId,
      paymentMethod: paymentMethod,
      customerAddressId: customerAddressId,
      location: location,
      deliveryQuoteId: deliveryQuoteId,
      useWallet: useWallet,
      notes: notes,
    );

    final current = state;
    if (current is OrdersLoaded) {
      emit(OrdersLoaded(
        orders: [order, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
    } else {
      emit(OrdersLoaded(orders: [order]));
    }

    return order;
  }

  Future<void> _replaceOrder(ConsumerOrder updated) async {
    if (_standalone.containsKey(updated.id)) {
      _standalone[updated.id] = updated;
      emit(state);
    }
    final current = state;
    if (current is! OrdersLoaded) return;
    emit(OrdersLoaded(
      orders: current.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
      hasMore: current.hasMore,
      currentPage: current.currentPage,
    ));
  }

  Future<void> cancelOrder(String orderId, {required String reason}) async {
    final updated = await _repository.cancelOrder(orderId, reason: reason);
    await _replaceOrder(updated);
  }

  Future<void> reorder(String orderId) async {
    final newOrder = await _repository.reorder(orderId);
    final current = state;
    if (current is OrdersLoaded) {
      emit(OrdersLoaded(
        orders: [newOrder, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
    } else {
      emit(OrdersLoaded(orders: [newOrder]));
    }
  }

  /// Refreshes the live tracking fields for [orderId]. An order that isn't
  /// cached yet is first loaded in full — the track endpoint alone carries
  /// no items/totals/address — and cached so the tracking screen can render
  /// it. Throws if the order can't be loaded at all.
  Future<void> trackOrder(String orderId) async {
    final previous = orderById(orderId) ?? await _fetchFullOrder(orderId);
    final updated = await _repository.trackOrder(orderId, previous: previous);
    // With no `previous`, the slim track payload carries no `id` — stamp it.
    _upsertOrder(previous == null ? updated.copyWith(id: orderId) : updated);
  }

  /// Null when the detail endpoint doesn't serve this order — the caller
  /// then falls back to the slim track payload.
  Future<ConsumerOrder?> _fetchFullOrder(String orderId) async {
    try {
      return await _repository.getOrderById(orderId);
    } catch (_) {
      return null;
    }
  }

  void _upsertOrder(ConsumerOrder order) {
    final current = state;
    if (current is OrdersLoaded && current.orders.any((o) => o.id == order.id)) {
      _replaceOrder(order);
      return;
    }
    _standalone[order.id] = order;
    emit(state);
  }

  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    required String paymentMethod,
    String? phone,
    String? mobileMoneyProvider,
  }) =>
      _repository.payOrder(
        orderId,
        paymentMethod: paymentMethod,
        phone: phone,
        mobileMoneyProvider: mobileMoneyProvider,
      );

  /// Verifies a gateway charge by [reference]. A confirmed payment updates
  /// every screen immediately, then re-syncs the order from the server in
  /// the background. Throws on request failure.
  Future<OrderPaymentVerification> verifyPayment(
    String orderId, {
    required String reference,
  }) async {
    final result = await _repository.verifyPayment(orderId, reference: reference);
    if (result.isPaid) {
      _confirmedPayments.add(orderId);
      _awaitingPayment.remove(orderId);
      emit(state);
      unawaited(trackOrder(orderId).catchError((Object _) {}));
    } else if (result.isFailed) {
      _awaitingPayment.remove(orderId);
    }
    return result;
  }

  /// Asks the server where a payment stands — by [reference] when known,
  /// otherwise from the order's own payment status. Never throws: a definitive
  /// rejection (422) is reported as failed with the server's wording, and any
  /// other problem leaves the charge unknown (still pending) rather than
  /// inviting a second payment.
  Future<OrderPaymentVerification> checkPayment(
    String orderId, {
    String? reference,
  }) async {
    try {
      if (reference != null && reference.isNotEmpty) {
        return await verifyPayment(orderId, reference: reference);
      }
      await trackOrder(orderId);
      final status = orderById(orderId)?.paymentStatus;
      return OrderPaymentVerification(
        isPaid: status == PaymentStatus.paid,
        isFailed: status == PaymentStatus.failed,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 422) return const OrderPaymentVerification();
      return OrderPaymentVerification(
        isFailed: true,
        message: NetworkUtils.handleDioException(e).value.message,
      );
    } catch (_) {
      return const OrderPaymentVerification();
    }
  }

  /// See [_awaitingPayment].
  void markAwaitingPaymentConfirmation(String orderId) {
    _awaitingPayment[orderId] = DateTime.now();
    emit(state);
  }

  /// True while [orderId]'s payment is being confirmed — "Pay Now" must be
  /// disabled. Clears itself once the order reports a final payment status
  /// or the confirmation window lapses.
  bool isAwaitingPaymentConfirmation(String orderId) {
    final since = _awaitingPayment[orderId];
    if (since == null) return false;
    final status = orderById(orderId)?.paymentStatus;
    final settled = status != null && status != PaymentStatus.pending;
    final expired = DateTime.now().difference(since) > paymentConfirmationWindow;
    if (settled || expired) {
      _awaitingPayment.remove(orderId);
      return false;
    }
    return true;
  }

  /// Returns a single order by ID, or null if not found / still loading.
  ConsumerOrder? orderById(String orderId) {
    final order = _findOrder(orderId);
    if (order == null || !_confirmedPayments.contains(orderId)) return order;
    return order.copyWith(
      paymentStatus: PaymentStatus.paid,
      requiresPayment: false,
    );
  }

  ConsumerOrder? _findOrder(String orderId) {
    final s = state;
    if (s is OrdersLoaded) {
      for (final o in s.orders) {
        if (o.id == orderId) return o;
      }
    }
    return _standalone[orderId];
  }

  /// Applies a realtime `order.status` event onto the cached order, if any
  /// — a no-op if this order isn't cached yet (e.g. no screen has fetched
  /// it this session). Reuses the same status-string parser the REST path
  /// uses, so socket-driven and REST-driven status stay consistent.
  void applyOrderStatusEvent(OrderStatusEvent event) {
    final current = orderById(event.orderId);
    if (current == null) return;
    _replaceOrder(current.copyWith(
      status: orderStatusFromString(event.status),
      estimatedDelivery: event.estimatedDeliveryAt,
    ));
  }

  /// Applies a realtime `rider.location` event for [orderId] onto the
  /// cached order, if any — the position, plus the rider profile the event
  /// carries (photo, vehicle, plate). The REST name wins when both exist.
  void applyRiderLocation(String orderId, RiderLocationEvent event) {
    final current = orderById(orderId);
    if (current == null) return;
    final eventName = event.name.trim();
    _replaceOrder(current.copyWith(
      riderLocation: RiderLocation.fromEvent(event),
      driverName: current.driverName ?? (eventName.isEmpty ? null : eventName),
      driverPhotoUrl: event.photoUrl,
      driverVehicleType: event.vehicleType,
      driverPlateNumber: event.plateNumber,
    ));
  }

  /// `riderLocationEvents` is a single stream shared by both the
  /// `private-order.{id}` and `private-admin.riders` feeds — [sourceOrderId]
  /// is null for the latter, which isn't order-scoped and is dropped here.
  void _applyRiderLocationEvent(RiderLocationEvent event) {
    final orderId = event.sourceOrderId;
    if (orderId == null) return;
    applyRiderLocation(orderId, event);
  }

  @override
  void dispose() {
    _orderStatusSub?.cancel();
    _riderLocationSub?.cancel();
    super.dispose();
  }
}
