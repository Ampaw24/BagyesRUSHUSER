import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/transaction/models/transaction_model.dart';
import 'package:bagyesrushappusernew/src/transaction/repositories/transaction_repository.dart';

sealed class PaymentReceiptState {
  const PaymentReceiptState();
}

/// Asking the server where the payment stands.
class ReceiptVerifying extends PaymentReceiptState {
  const ReceiptVerifying();
}

class ReceiptReady extends PaymentReceiptState {
  const ReceiptReady(this.receipt);

  final PaymentReceipt receipt;
}

/// The payment's status is known but the order behind it couldn't be loaded,
/// so there's nothing to itemise.
class ReceiptUnavailable extends PaymentReceiptState {
  const ReceiptUnavailable(this.status, {this.message});

  final ReceiptStatus status;
  final String? message;
}

/// Works out where a payment stands and builds its receipt: verifies, fills
/// in payment details from the transaction record when the verify response
/// left them out, and keeps re-checking while the charge is still being
/// confirmed so the receipt flips to paid in place.
class PaymentReceiptViewModel extends ChangeNotifier {
  PaymentReceiptViewModel(
    this._args,
    this._orders,
    this._transactions, {
    this.pollInterval = defaultPollInterval,
  });

  final PaymentReceiptArgs _args;
  final OrdersViewModel _orders;
  final TransactionRepository _transactions;

  static const defaultPollInterval = Duration(seconds: 5);
  final Duration pollInterval;
  static const _transactionLookupLimit = 10;

  PaymentReceiptState _state = const ReceiptVerifying();
  PaymentReceiptState get state => _state;

  ReceiptStatus? get status => switch (_state) {
    ReceiptReady(:final receipt) => receipt.status,
    ReceiptUnavailable(:final status) => status,
    ReceiptVerifying() => null,
  };

  Timer? _poll;
  DateTime? _startedAt;
  bool _checking = false;
  bool _disposed = false;
  TransactionModel? _transaction;

  Future<void> start() async {
    _startedAt = DateTime.now();
    final check =
        _args.initialCheck ??
        (_args.knownPaid
            ? const OrderPaymentVerification(isPaid: true)
            : await _orders.checkPayment(
                _args.orderId,
                reference: _args.reference,
              ));
    await _settle(check);
    if (!_disposed && status == ReceiptStatus.processing) {
      _poll = Timer.periodic(pollInterval, (_) => _recheck());
    }
  }

  Future<void> _recheck() async {
    final started = _startedAt;
    final expired =
        started != null &&
        DateTime.now().difference(started) >
            OrdersViewModel.paymentConfirmationWindow;
    if (expired) return _stopPolling();
    if (_checking) return;
    _checking = true;
    try {
      final check = await _orders.checkPayment(
        _args.orderId,
        reference: _args.reference,
      );
      if (_disposed || check.isPending) return;
      _stopPolling();
      await _settle(check);
    } finally {
      _checking = false;
    }
  }

  Future<void> _settle(OrderPaymentVerification check) async {
    final status = check.isPaid
        ? ReceiptStatus.paid
        : check.isFailed
        ? ReceiptStatus.failed
        : ReceiptStatus.processing;

    final order = await _loadOrder();
    if (_disposed) return;
    if (order == null) {
      _emit(ReceiptUnavailable(status, message: check.message));
      return;
    }

    var receipt = _buildReceipt(order, status, check);
    _emit(ReceiptReady(receipt));

    if (status == ReceiptStatus.paid && receipt.hasPaymentDetailGaps) {
      _transaction ??= await _findTransaction(order.id, receipt.reference);
      if (_disposed || _transaction == null) return;
      receipt = _buildReceipt(order, status, check);
      _emit(ReceiptReady(receipt));
    }
  }

  PaymentReceipt _buildReceipt(
    ConsumerOrder order,
    ReceiptStatus status,
    OrderPaymentVerification check,
  ) => PaymentReceipt.build(
    order: order,
    status: status,
    reference: _args.reference,
    verification: check,
    transaction: _transaction,
    failureMessage: check.message,
  );

  /// Cached copy first (verification refreshes it); one fetch if absent.
  Future<ConsumerOrder?> _loadOrder() async {
    final cached = _orders.orderById(_args.orderId);
    if (cached != null) return cached;
    try {
      await _orders.trackOrder(_args.orderId);
    } catch (_) {
      return null;
    }
    return _orders.orderById(_args.orderId);
  }

  /// Best effort: the most recent transactions, matched by order or
  /// reference. Anything that goes wrong just leaves the receipt as it is.
  Future<TransactionModel?> _findTransaction(
    String orderId,
    String? reference,
  ) async {
    try {
      final result = await _transactions.getCustomerTransactions(
        limit: _transactionLookupLimit,
      );
      final list = result.fold(
        (_) => const <TransactionModel>[],
        (data) => data.transactions,
      );
      for (final transaction in list) {
        final matchesOrder = transaction.order?.id.toString() == orderId;
        final matchesReference =
            reference != null && transaction.reference == reference;
        if (matchesOrder || matchesReference) return transaction;
      }
    } catch (_) {
      // Receipt stays as-is.
    }
    return null;
  }

  void _emit(PaymentReceiptState next) {
    _state = next;
    if (!_disposed) notifyListeners();
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}
