import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/transaction/models/transaction_model.dart';

enum ReceiptStatus {
  paid,
  processing,
  failed;

  OrderPaymentOutcome get outcome => switch (this) {
    ReceiptStatus.paid => OrderPaymentOutcome.paid,
    ReceiptStatus.processing => OrderPaymentOutcome.processing,
    ReceiptStatus.failed => OrderPaymentOutcome.failed,
  };
}

enum ReceiptKind { food, parcelSend, parcelReceive }

/// What the receipt screen needs to find out where a payment stands.
class PaymentReceiptArgs {
  const PaymentReceiptArgs({
    required this.orderId,
    this.reference,
    this.knownPaid = false,
    this.initialCheck,
  });

  final String orderId;

  /// The gateway reference from `POST customer/orders/:id/pay`, when known.
  final String? reference;

  /// The order is already known to be paid (e.g. reopened from tracking), so
  /// no verification round-trip is needed.
  final bool knownPaid;

  /// A verification the caller already ran, so it isn't repeated.
  final OrderPaymentVerification? initialCheck;
}

/// Everything shown on the receipt. Money figures are the backend's own —
/// nothing here is computed — and every payment detail the backend didn't
/// send stays null so the screen can leave it out.
class PaymentReceipt {
  const PaymentReceipt({
    required this.orderId,
    required this.orderNumber,
    required this.kind,
    required this.title,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.deliveryAddress,
    required this.status,
    required this.placedAt,
    this.reference,
    this.paidAt,
    this.channelLabel,
    this.amountPaid,
    this.walletApplied,
    this.failureMessage,
  });

  final String orderId;
  final String orderNumber;
  final ReceiptKind kind;

  /// Vendor name for food, a parcel label otherwise.
  final String title;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final String deliveryAddress;
  final ReceiptStatus status;
  final DateTime placedAt;

  final String? reference;
  final DateTime? paidAt;
  final String? channelLabel;

  /// What the gateway actually charged — differs from [total] when the
  /// wallet covered part of it. Null unless the transaction record is known.
  final double? amountPaid;
  final double? walletApplied;
  final String? failureMessage;

  bool get isParcel => kind != ReceiptKind.food;

  /// The big figure at the top.
  double get headlineAmount => amountPaid ?? total;

  /// "Paid on" only once there's a real payment time; otherwise the order's
  /// own creation time, honestly labelled.
  DateTime get displayDate => paidAt ?? placedAt;
  String get dateLabel => paidAt != null ? 'Paid on' : 'Ordered on';

  factory PaymentReceipt.build({
    required ConsumerOrder order,
    required ReceiptStatus status,
    String? reference,
    OrderPaymentVerification? verification,
    TransactionModel? transaction,
    String? failureMessage,
  }) {
    final isPaid = status == ReceiptStatus.paid;
    final parcelDirection = order.parcelDirection;
    final kind = switch (parcelDirection) {
      null => ReceiptKind.food,
      'receive' => ReceiptKind.parcelReceive,
      _ => ReceiptKind.parcelSend,
    };
    final vendorName = order.restaurantName.trim();
    final transactionChannel = transaction?.methodLabel.trim() ?? '';

    return PaymentReceipt(
      orderId: order.id,
      orderNumber: order.id.split('-').last,
      kind: kind,
      title: switch (kind) {
        ReceiptKind.food => vendorName.isEmpty ? 'Food order' : vendorName,
        ReceiptKind.parcelSend => 'Parcel delivery · Send',
        ReceiptKind.parcelReceive => 'Parcel delivery · Receive',
      },
      items: order.items,
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      serviceFee: order.serviceFee,
      discount: order.discount,
      total: order.total,
      deliveryAddress: order.deliveryAddress,
      status: status,
      placedAt: order.placedAt,
      reference: _firstNonEmpty([
        reference,
        verification?.reference,
        transaction?.reference,
      ]),
      paidAt: isPaid ? (verification?.paidAt ?? transaction?.paidAt) : null,
      channelLabel: _firstNonEmpty([
        verification?.channelLabel,
        transactionChannel,
        isPaid ? order.paymentMethod : null,
      ]),
      amountPaid: isPaid ? transaction?.amount.toDouble() : null,
      walletApplied: isPaid ? verification?.walletApplied : null,
      failureMessage: failureMessage,
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Whether a transaction lookup could still add something to the receipt.
  bool get hasPaymentDetailGaps =>
      reference == null || paidAt == null || amountPaid == null;
}
