import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/receipt_details.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/receipt_status_header.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/ticket_section.dart';

/// The receipt itself: status header over a tear line, details below. Kept
/// self-contained (no screen chrome) so it can also be captured as an image.
class ReceiptTicket extends StatelessWidget {
  const ReceiptTicket({
    super.key,
    required this.receipt,
    required this.onCopyReference,
  });

  final PaymentReceipt receipt;
  final VoidCallback onCopyReference;

  static const processingMessage =
      'Your provider is still confirming the charge. This updates '
      'automatically — no need to pay again.';
  static const failedMessage = 'Your payment didn\'t go through. Please try again.';

  String? get _message => switch (receipt.status) {
    ReceiptStatus.paid => null,
    ReceiptStatus.processing => processingMessage,
    ReceiptStatus.failed => receipt.failureMessage ?? failedMessage,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TicketSection(
          part: TicketPart.top,
          child: ReceiptStatusHeader(
            status: receipt.status,
            amount: receipt.headlineAmount,
            paidTo: receipt.title,
            message: _message,
          ),
        ),
        TicketSection(
          part: TicketPart.bottom,
          child: ReceiptDetails(
            receipt: receipt,
            onCopyReference: onCopyReference,
          ),
        ),
      ],
    );
  }
}
