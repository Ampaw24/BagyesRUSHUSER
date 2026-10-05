import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/widget_capture.dart';
import 'package:bagyesrushappusernew/core/widgets/app_toast.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/payment_receipt_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/receipt_actions.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/receipt_status_header.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/receipt/receipt_ticket.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_card.dart';

/// Where a payment stands, as a receipt. Checks the payment on open, then
/// shows a paid / processing / failed receipt. Pops an [OrderPaymentResult]
/// saying where the customer wants to go next — the caller does the
/// navigating. Back and close mean "track".
class PaymentReceiptView extends StatefulWidget {
  const PaymentReceiptView({super.key, required this.args, this.viewModel});

  final PaymentReceiptArgs args;

  /// Injected by tests; normally resolved from the service locator.
  @visibleForTesting
  final PaymentReceiptViewModel? viewModel;

  static Future<OrderPaymentResult> open(
    BuildContext context,
    PaymentReceiptArgs args,
  ) async {
    final result = await Navigator.of(context).push<OrderPaymentResult>(
      MaterialPageRoute(builder: (_) => PaymentReceiptView(args: args)),
    );
    return result ?? const OrderPaymentResult(OrderPaymentOutcome.dismissed);
  }

  @override
  State<PaymentReceiptView> createState() => _PaymentReceiptViewState();
}

class _PaymentReceiptViewState extends State<PaymentReceiptView> {
  /// Widest the receipt grows on tablets / landscape.
  static const _maxContentWidth = 560.0;

  late final PaymentReceiptViewModel _vm =
      widget.viewModel ?? sl<PaymentReceiptViewModel>(param1: widget.args);
  final _ticketKey = GlobalKey();
  ReceiptStatus? _lastStatus;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.start();
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    if (widget.viewModel == null) _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    final status = _vm.status;
    if (status == ReceiptStatus.paid && _lastStatus != ReceiptStatus.paid) {
      HapticFeedback.mediumImpact();
    }
    _lastStatus = status;
  }

  void _exit(PaymentExit exit) {
    final status = _vm.status;
    if (status == null) return;
    Navigator.of(context).pop(OrderPaymentResult(status.outcome, exit));
  }

  Future<void> _copyReference(String reference) async {
    await Clipboard.setData(ClipboardData(text: reference));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    AppToast.show(
      context,
      isSuccess: true,
      title: 'Copied',
      subtitle: 'Payment reference copied to your clipboard.',
    );
  }

  Future<void> _share(PaymentReceipt receipt) async {
    if (_isSharing) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final pixelRatio = math.max(3.0, MediaQuery.devicePixelRatioOf(context));
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSharing = true);
    try {
      final bytes = await captureAsPng(_ticketKey, pixelRatio: pixelRatio);
      if (bytes == null) throw StateError('Receipt not rendered');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: ['bagyesrush-receipt-${receipt.orderNumber}.png'],
          text: 'My bagyesRUSH payment receipt',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Couldn\'t share the receipt. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit(PaymentExit.track);
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceVariant,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(
                constraints.maxWidth,
                _maxContentWidth,
              );
              // Everything below sizes itself off the width it's given. Capped
              // by the height too, so the pinned top bar and actions can't
              // crowd out the receipt in a short window (portrait phones
              // are taller than wide, so they're unaffected).
              final scale = math.min(contentWidth, constraints.maxHeight);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(scale, mediaQuery.size.height),
                ),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: ListenableBuilder(
                      listenable: _vm,
                      builder: (context, _) => _buildContent(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = _vm.state;
    final status = _vm.status;
    final isParcel = switch (state) {
      ReceiptReady(:final receipt) => receipt.isParcel,
      _ => false,
    };

    return Column(
      children: [
        _TopBar(
          onClose: status == null ? null : () => _exit(PaymentExit.track),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            child: switch (state) {
              ReceiptVerifying() => const _VerifyingPane(
                key: ValueKey('verifying'),
              ),
              ReceiptReady(:final receipt) => _ScrollPane(
                key: const ValueKey('receipt'),
                child: RepaintBoundary(
                  key: _ticketKey,
                  child: ColoredBox(
                    color: AppColors.surfaceVariant,
                    child: Padding(
                      padding: EdgeInsets.all(w * 0.02),
                      child: ReceiptTicket(
                        receipt: receipt,
                        onCopyReference: () =>
                            _copyReference(receipt.reference ?? ''),
                      ),
                    ),
                  ),
                ),
              ),
              ReceiptUnavailable(:final status, :final message) => _ScrollPane(
                key: const ValueKey('unavailable'),
                child: TrackingCard(
                  padding: EdgeInsets.all(w * 0.06),
                  child: ReceiptStatusHeader(
                    status: status,
                    message: message ?? _unavailableMessage(status),
                  ),
                ),
              ),
            },
          ),
        ),
        if (status != null)
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
            child: ReceiptActions(
              status: status,
              isParcel: isParcel,
              isSharing: _isSharing,
              onTrack: () => _exit(PaymentExit.track),
              onHome: () => _exit(PaymentExit.home),
              onRetry: () => _exit(PaymentExit.retry),
              onShare: () {
                if (state is ReceiptReady) _share(state.receipt);
              },
            ),
          ),
      ],
    );
  }

  static String _unavailableMessage(ReceiptStatus status) => switch (status) {
    ReceiptStatus.paid =>
      'Your payment is confirmed. We couldn\'t load the receipt details '
          'right now — you can find your order in tracking.',
    ReceiptStatus.processing => ReceiptTicket.processingMessage,
    ReceiptStatus.failed => ReceiptTicket.failedMessage,
  };
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final onClose = this.onClose;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.02),
      child: Row(
        children: [
          // Same footprint while checking, so the title doesn't jump.
          if (onClose == null)
            SizedBox(width: w * 0.11, height: w * 0.11)
          else
            TrackingCircleButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onTap: onClose,
            ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              'Payment receipt',
              style: TextStyle(
                fontSize: w * 0.052,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollPane extends StatelessWidget {
  const _ScrollPane({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.02),
      child: child,
    );
  }
}

class _VerifyingPane extends StatelessWidget {
  const _VerifyingPane({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: w * 0.14,
              height: w * 0.14,
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: w * 0.06),
            Text(
              'Confirming your payment…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.05,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              'This only takes a moment. Please don\'t close the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.035,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
