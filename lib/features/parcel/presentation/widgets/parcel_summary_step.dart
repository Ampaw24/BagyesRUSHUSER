import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/widgets/animated_money.dart';
import 'package:bagyesrushappusernew/core/widgets/network_avatar.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/wallet_split.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_state.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/views/widgets/use_wallet_tile.dart';
import 'package:bagyesrushappusernew/src/payment/views/screens/add_payment_method_screen.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_state.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/views/widgets/payout_provider_visuals.dart';

import '../../../../constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/parcel/model/delivery_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

class ParcelSummaryStep extends StatefulWidget {
  final String packageType;
  final String weightText;
  final String pickupAddress;
  final List<DeliveryStop> deliveryStops;
  final double distanceKm;
  final RiderModel? assignedRider;
  final bool fragile;
  final List<File> packageImages;

  const ParcelSummaryStep({
    super.key,
    required this.packageType,
    required this.weightText,
    required this.pickupAddress,
    required this.deliveryStops,
    required this.distanceKm,
    required this.assignedRider,
    required this.fragile,
    required this.packageImages,
  });

  @override
  State<ParcelSummaryStep> createState() => _ParcelSummaryStepState();
}

class _ParcelSummaryStepState extends State<ParcelSummaryStep> {
  late final PaymentViewModel _paymentVm;
  late final CustomerWalletViewmodel _walletVm;

  @override
  void initState() {
    super.initState();
    _paymentVm = sl<PaymentViewModel>(param1: false);
    _paymentVm.addListener(_onPaymentStateChanged);
    _paymentVm.loadPaymentMethods();

    // Fresh balance every time — the wallet split must never be previewed
    // against a balance another screen cached earlier.
    _walletVm = context.read<CustomerWalletViewmodel>();
    _walletVm.addListener(_onWalletChanged);
    _walletVm.fetchWallet();
  }

  @override
  void dispose() {
    _paymentVm.removeListener(_onPaymentStateChanged);
    _paymentVm.dispose();
    _walletVm.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    final wallet = _walletVm.wallet;
    if (!mounted || wallet == null) return;
    context.read<SendParcelViewModel>().syncWalletBalance(wallet.balance);
  }

  /// Auto-selects the customer's default (or first) saved payment method
  /// once the list loads, so they aren't forced to tap it explicitly.
  void _onPaymentStateChanged() {
    if (!mounted) return;
    final state = _paymentVm.state;
    if (state is PaymentMethodsLoaded && state.methods.isNotEmpty) {
      final sendVm = context.read<SendParcelViewModel>();
      if (sendVm.state.selectedPaymentMethod == null) {
        final defaultMethod = state.methods
            .firstWhere((m) => m.isDefault, orElse: () => state.methods.first);
        sendVm.selectPaymentMethod(defaultMethod);
      }
    }
    setState(() {});
  }

  /// Pushes the shared "Add Payment Method" screen (Profile → Payment
  /// Methods / Checkout use the same one), then selects the newly-created
  /// method and refreshes the saved-methods list.
  Future<void> _addPaymentMethod(BuildContext context) async {
    final result = await Navigator.of(context).push<PaymentMethod>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<PaymentViewModel>(
              create: (_) => sl<PaymentViewModel>(param1: false),
            ),
            ChangeNotifierProvider<PayoutProvidersViewModel>(
              create: (_) => sl<PayoutProvidersViewModel>(),
            ),
          ],
          child: const AddPaymentMethodScreen(),
        ),
      ),
    );
    if (result == null) return;
    _paymentVm.loadPaymentMethods();
    if (!mounted) return;
    this.context.read<SendParcelViewModel>().selectPaymentMethod(result);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final sendVm = context.watch<SendParcelViewModel>();
    final sendState = sendVm.state;
    final walletVm = context.watch<CustomerWalletViewmodel>();
    final walletSplit = sendState.walletSplit;
    final currency = sendState.quoteCurrency ?? 'GHS';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Summary',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.04),

          // ── Route visualization ──────────────────────────────────────────
          _buildRoute(w, sendState),

          SizedBox(height: w * 0.04),
          _Divider(),
          SizedBox(height: w * 0.04),

          // ── Package info chips ───────────────────────────────────────────
          Wrap(
            spacing: w * 0.03,
            runSpacing: w * 0.02,
            children: [
              _InfoChip(
                icon: HugeIcons.strokeRoundedDeliveryBox01,
                label: widget.packageType == 'document' ? 'Document' : 'Parcel',
                w: w,
              ),
              _InfoChip(
                icon: HugeIcons.strokeRoundedInformationCircle,
                label: '${widget.weightText} kg',
                w: w,
              ),
              _InfoChip(
                icon: HugeIcons.strokeRoundedMapsLocation01,
                label: '${widget.distanceKm.toStringAsFixed(1)} km',
                w: w,
              ),
              if (widget.fragile)
                _InfoChip(
                  icon: HugeIcons.strokeRoundedAlert01,
                  label: 'Fragile',
                  w: w,
                  color: AppColors.error,
                ),
            ],
          ),

          // ── Rider summary ────────────────────────────────────────────────
          if (widget.assignedRider != null) ...[
            SizedBox(height: w * 0.04),
            _Divider(),
            SizedBox(height: w * 0.04),
            _RiderSummaryRow(rider: widget.assignedRider!, w: w),
          ],

          SizedBox(height: w * 0.04),
          _Divider(),
          SizedBox(height: w * 0.04),

          // Total box — always driven by the backend quote, the amount
          // that actually gets charged.
          _QuoteTotalBox(
            isFetchingQuote: sendState.isFetchingQuote,
            quoteError: sendState.quoteError,
            noRidersMessage: sendState.noRidersMessage,
            quotedPrice: sendState.quotedPrice,
            quotedDeliveryFee: sendState.quotedDeliveryFee,
            quotedServiceFee: sendState.quotedServiceFee,
            quoteCurrency: sendState.quoteCurrency,
            walletSplit: walletSplit,
            onRetry: () => sendVm.fetchQuote(),
            w: w,
          ),

          SizedBox(height: w * 0.05),
          _Divider(),
          SizedBox(height: w * 0.05),

          // ── Payment method ──────────────────────────────────────────────
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.03),
          UseWalletTile(
            wallet: walletVm.wallet,
            isLoading: walletVm.state is CustomerWalletLoading,
            hasError: walletVm.state is CustomerWalletError,
            useWallet: sendState.useWallet,
            split: walletSplit,
            onChanged: sendVm.setUseWallet,
            onRetry: walletVm.fetchWallet,
          ),
          SizedBox(height: w * 0.03),
          // Wallet covers it all → the mobile-money picker gives way to a
          // confirmation; otherwise it asks only for what's left.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: walletSplit.coversFully
                  ? _WalletCoversCard(
                      key: const ValueKey('wallet-covers'),
                      amount: walletSplit.walletAmount,
                      balanceAfter: sendState.walletBalanceAfter,
                      currency: currency,
                      w: w,
                    )
                  : Column(
                      key: const ValueKey('mobile-money'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (walletSplit.usesWallet)
                          Padding(
                            padding: EdgeInsets.only(bottom: w * 0.025),
                            child: Text.rich(
                              TextSpan(
                                text: 'Pay the remaining ',
                                children: [
                                  TextSpan(
                                    text: formatMoney(
                                      walletSplit.remaining,
                                      currency: currency,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const TextSpan(text: ' with mobile money'),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: w * 0.033,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        _PaymentMethodSection(
                          state: _paymentVm.state,
                          selectedMethod: sendState.selectedPaymentMethod,
                          onSelect: (m) => context
                              .read<SendParcelViewModel>()
                              .selectPaymentMethod(m),
                          onAddNew: () => _addPaymentMethod(context),
                          w: w,
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: w * 0.02),
        ],
      ),
    );
  }

  // ── Route visualization ────────────────────────────────────────────────────
  //
  // Pickup (green)
  //   │
  //   ● Stop 1
  //   │
  //   ● Stop 2 (if exists)
  //   │
  //   🔵 Final stop (primary blue)

  Widget _buildRoute(double w, SendParcelState sendState) {
    final nodes = <Widget>[];
    final isReceive = sendState.direction.isReceive;

    // Pickup node
    nodes.add(
      _AddressRow(
        icon: HugeIcons.strokeRoundedLocation01,
        iconColor: AppColors.success,
        label: isReceive
            ? 'Collect from ${sendState.senderName} · ${sendState.senderPhone}'
            : 'Pickup',
        address: widget.pickupAddress,
        w: w,
      ),
    );

    for (int i = 0; i < widget.deliveryStops.length; i++) {
      final isFinal = i == widget.deliveryStops.length - 1;

      nodes.add(_RouteLine(w: w));
      nodes.add(
        _AddressRow(
          icon: isFinal
              ? HugeIcons.strokeRoundedMapsLocation01
              : HugeIcons.strokeRoundedLocation01,
          iconColor: isFinal ? AppColors.primary : AppColors.textSecondary,
          label: isReceive
              ? 'Deliver to you'
              : widget.deliveryStops.length == 1
                  ? 'Delivery'
                  : 'Stop ${i + 1}${isFinal ? ' (Final)' : ''}',
          address: widget.deliveryStops[i].address,
          w: w,
        ),
      );
      // Show optional item details beneath the address row if filled in.
      if (widget.deliveryStops[i].hasDetails) {
        nodes.add(_StopDetailChips(
          stop: widget.deliveryStops[i],
          packageImages: widget.packageImages,
          w: w,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes,
    );
  }
}

// ── Address row ───────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final String address;
  final double w;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, color: iconColor, size: w * 0.05),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: w * 0.005),
              Text(
                address,
                style: TextStyle(
                  fontSize: w * 0.035,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Route line (dotted connector) ─────────────────────────────────────────────

class _RouteLine extends StatelessWidget {
  final double w;
  const _RouteLine({required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: w * 0.023,
        top: w * 0.01,
        bottom: w * 0.01,
      ),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            width: 2,
            height: w * 0.02,
            margin: EdgeInsets.symmetric(vertical: w * 0.006),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.divider);
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final double w;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.w,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.025,
        vertical: w * 0.015,
      ),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.08)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tint, size: w * 0.035),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.03,
              color: tint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wallet deduction ──────────────────────────────────────────────────────────

/// "Wallet −GHS 12.35" then "Left to pay GHS 18.05", sliding in under the
/// total when the wallet toggle goes on. Amounts count to each new value.
class _WalletDeduction extends StatelessWidget {
  final WalletSplit split;
  final String currency;
  final double w;

  const _WalletDeduction({
    required this.split,
    required this.currency,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final covered = split.coversFully;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * w * 0.03),
          child: child,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: w * 0.02),
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: w * 0.042,
                color: AppColors.success,
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: Text(
                  'Wallet',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              AnimatedMoney(
                amount: split.walletAmount,
                currency: currency,
                prefix: '-',
                style: TextStyle(
                  fontSize: w * 0.036,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.primary.withValues(alpha: 0.15)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Left to pay',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedMoney(
                amount: split.remaining,
                currency: currency,
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w900,
                  color: covered ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            alignment: Alignment.topRight,
            child: covered
                ? Padding(
                    padding: EdgeInsets.only(top: w * 0.015),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _CoveredChip(w: w),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CoveredChip extends StatelessWidget {
  final double w;

  const _CoveredChip({required this.w});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(
        scale: t,
        alignment: Alignment.centerRight,
        child: child,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: w * 0.036, color: AppColors.success),
            SizedBox(width: w * 0.012),
            Text(
              'Covered by your wallet',
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Replaces the mobile-money picker when the wallet pays the whole total.
class _WalletCoversCard extends StatelessWidget {
  final double amount;
  final double balanceAfter;
  final String currency;
  final double w;

  const _WalletCoversCard({
    super.key,
    required this.amount,
    required this.balanceAfter,
    required this.currency,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final badge = w * 0.1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(scale: t, child: child),
            child: Container(
              width: badge,
              height: badge,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: badge * 0.6),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paid in full from your wallet',
                  style: TextStyle(
                    fontSize: w * 0.036,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.008),
                Text(
                  'No mobile money payment needed. '
                  '${formatMoney(amount, currency: currency)} will be deducted '
                  '· Balance after: ${formatMoney(balanceAfter, currency: currency)}',
                  style: TextStyle(
                    fontSize: w * 0.03,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rider summary row ─────────────────────────────────────────────────────────

class _RiderSummaryRow extends StatelessWidget {
  final RiderModel rider;
  final double w;

  const _RiderSummaryRow({required this.rider, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NetworkAvatar(
          name: rider.name,
          photoUrl: rider.photoUrl,
          size: w * 0.13,
        ),
        SizedBox(width: w * 0.035),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.008),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: w * 0.008,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDeliveryTruck01,
                    color: AppColors.textSecondary,
                    size: w * 0.032,
                  ),
                  SizedBox(width: w * 0.01),
                  Text(
                    rider.vehicleTypeLabel ?? 'Rider',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStarCircle,
                    color: AppColors.accent,
                    size: w * 0.032,
                  ),
                  SizedBox(width: w * 0.01),
                  Text(
                    '${rider.rating.toStringAsFixed(1)} (${rider.reviewCount})',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (rider.deliveriesCompleted > 0) ...[
                    SizedBox(width: w * 0.025),
                    Text(
                      '${rider.deliveriesCompleted} deliveries',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.015,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.018,
                height: w * 0.018,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: w * 0.015),
              Text(
                'Available',
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stop detail chips ─────────────────────────────────────────────────────────

class _StopDetailChips extends StatelessWidget {
  final DeliveryStop stop;
  final List<File> packageImages;
  final double w;

  const _StopDetailChips({
    required this.stop,
    required this.packageImages,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final taggedImages = stop.selectedImageIndices
        .where((i) => i < packageImages.length)
        .map((i) => packageImages[i])
        .toList();

    return Padding(
      padding: EdgeInsets.only(left: w * 0.08, top: w * 0.015, bottom: w * 0.005),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tagged photo strip ───────────────────────────────────────────
          if (taggedImages.isNotEmpty) ...[
            SizedBox(
              height: w * 0.16,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: taggedImages.length,
                separatorBuilder: (_, _) => SizedBox(width: w * 0.02),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.022),
                  child: Image.file(
                    taggedImages[i],
                    width: w * 0.14,
                    height: w * 0.14,
                    fit: BoxFit.cover,
                    cacheWidth: (w * 0.14 *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  ),
                ),
              ),
            ),
            SizedBox(height: w * 0.015),
          ],
          // ── Detail chips ─────────────────────────────────────────────────
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.015,
            children: [
              if (stop.itemDescription.isNotEmpty)
                _DetailChip(
                  icon: Icons.inventory_2_outlined,
                  label: '${stop.quantity}× ${stop.itemDescription}',
                  w: w,
                ),
              if (stop.recipientName.isNotEmpty || stop.recipientPhone.isNotEmpty)
                _DetailChip(
                  icon: Icons.person_outline_rounded,
                  label: [
                    if (stop.recipientName.isNotEmpty) stop.recipientName,
                    if (stop.recipientPhone.isNotEmpty) stop.recipientPhone,
                  ].join(' · '),
                  w: w,
                ),
              if (stop.specialInstructions.isNotEmpty)
                _DetailChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: stop.specialInstructions,
                  w: w,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double w;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.025,
        vertical: w * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.02),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.033, color: AppColors.textSecondary),
          SizedBox(width: w * 0.015),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quote total box ─────────────────────────────────────────────────────────
//
// Always reflects the authoritative backend quote — never the client-side
// estimate above — since that is the amount that will actually be charged.

class _QuoteTotalBox extends StatelessWidget {
  final bool isFetchingQuote;
  final String? quoteError;
  final String? noRidersMessage;
  final double? quotedPrice;
  final double? quotedDeliveryFee;
  final double? quotedServiceFee;
  final String? quoteCurrency;
  final WalletSplit walletSplit;
  final VoidCallback onRetry;
  final double w;

  const _QuoteTotalBox({
    required this.isFetchingQuote,
    required this.quoteError,
    required this.noRidersMessage,
    required this.quotedPrice,
    required this.quotedDeliveryFee,
    required this.quotedServiceFee,
    required this.quoteCurrency,
    required this.walletSplit,
    required this.onRetry,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isFetchingQuote) {
      return Row(
        children: [
          SizedBox(
            width: w * 0.045,
            height: w * 0.045,
            child: const CircularProgressIndicator(strokeWidth: 2.2),
          ),
          SizedBox(width: w * 0.03),
          Text(
            'Calculating price…',
            style: TextStyle(
              fontSize: w * 0.038,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (quoteError != null) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: w * 0.05),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              'Couldn\'t get a delivery price. Please retry.',
              style: TextStyle(fontSize: w * 0.034, color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    // Server responded but couldn't match a rider — a normal outcome, not
    // an error, so it's styled neutral rather than red.
    if (noRidersMessage != null) {
      return Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: w * 0.05),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              noRidersMessage!,
              style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );
    }

    final price = quotedPrice;
    final currency = quoteCurrency ?? 'GHS';
    final deliveryFee = quotedDeliveryFee;
    final serviceFee = quotedServiceFee;
    final hasBreakdown = deliveryFee != null || serviceFee != null;
    // With the wallet on, "Left to pay" becomes the headline figure.
    final totalStyle = TextStyle(
      fontSize: walletSplit.usesWallet ? w * 0.04 : w * 0.05,
      fontWeight: FontWeight.w900,
      color: walletSplit.usesWallet ? AppColors.textPrimary : AppColors.primary,
    );

    return Column(
      children: [
        if (deliveryFee != null)
          _splitRow(
            'Delivery fee',
            formatMoney(deliveryFee, currency: currency),
            AppColors.textPrimary,
          ),
        if (serviceFee != null)
          _splitRow(
            'Service fee',
            formatMoney(serviceFee, currency: currency),
            AppColors.textPrimary,
          ),
        if (hasBreakdown)
          Divider(color: AppColors.primary.withValues(alpha: 0.15)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: totalStyle,
              child: price == null
                  ? Text(formatMoney(null, currency: currency))
                  : AnimatedMoney(
                      amount: price,
                      currency: currency,
                      style: const TextStyle(),
                    ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: walletSplit.usesWallet
              ? _WalletDeduction(split: walletSplit, currency: currency, w: w)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _splitRow(String label, String value, Color valueColor) => Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.008),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
}

// ── Payment method section ────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  final PaymentState state;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onSelect;
  final VoidCallback onAddNew;
  final double w;

  const _PaymentMethodSection({
    required this.state,
    required this.selectedMethod,
    required this.onSelect,
    required this.onAddNew,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    if (state is PaymentInitial || state is PaymentLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.04),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state is PaymentError) {
      return Text(
        'Failed to load payment methods.',
        style: TextStyle(fontSize: w * 0.034, color: AppColors.error),
      );
    }

    final methods =
        state is PaymentMethodsLoaded ? (state as PaymentMethodsLoaded).methods : const <PaymentMethod>[];

    return Column(
      children: [
        for (final method in methods) ...[
          _PaymentMethodTile(
            method: method,
            isSelected: selectedMethod?.id == method.id,
            onTap: () => onSelect(method),
            w: w,
          ),
          SizedBox(height: w * 0.025),
        ],
        _AddPaymentMethodTile(onTap: onAddNew, w: w),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;
  final double w;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final provider = method.provider;
    final providerName = provider?.name;
    // `displayTitle` falls back to the provider name when there's no custom
    // label, so only show it as a separate line when it adds information
    // beyond the title (i.e. the title is a custom label like "My MoMo").
    final showProviderLine =
        providerName != null && providerName != method.displayTitle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            provider != null
                ? PayoutProviderAvatar(provider: provider, size: w * 0.09)
                : Icon(
                    Icons.account_balance_wallet_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: w * 0.055,
                  ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayTitle,
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (showProviderLine)
                    Text(
                      providerName,
                      style: TextStyle(
                        fontSize: w * 0.03,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    method.maskedPhone,
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: w * 0.055,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPaymentMethodTile extends StatelessWidget {
  final VoidCallback onTap;
  final double w;

  const _AddPaymentMethodTile({required this.onTap, required this.w});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: w * 0.035, horizontal: w * 0.035),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: w * 0.05),
            SizedBox(width: w * 0.025),
            Text(
              'Add payment method',
              style: TextStyle(
                fontSize: w * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
