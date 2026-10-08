import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/core/widgets/inline_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/order_payment_launcher.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';
import '../widgets/available_riders_step.dart';
import '../widgets/delivery_stops_step.dart';
import '../widgets/location_picker_step.dart';
import '../widgets/package_details_step.dart';
import '../widgets/package_type_step.dart';
import '../widgets/parcel_bottom_bar.dart';
import '../widgets/parcel_step_indicator.dart';
import '../widgets/parcel_summary_step.dart';
import '../widgets/sender_contact_card.dart';

class SendParcelView extends StatefulWidget {
  final ParcelDirection direction;

  const SendParcelView({super.key, this.direction = ParcelDirection.send});

  @override
  State<SendParcelView> createState() => _SendParcelViewState();
}

class _SendParcelViewState extends State<SendParcelView> {
  /// One fresh instance per visit — mirrors the original
  /// `StateNotifierProvider.autoDispose` (a new blank wizard every time this
  /// screen is entered, not shared/persisted across visits). Owned and
  /// disposed directly by this State, then exposed to the subtree (e.g.
  /// [ParcelSummaryStep]) via `ChangeNotifierProvider.value`.
  late final SendParcelViewModel _vm;
  late SendParcelState _previousState;

  /// True from parcel creation until the Paystack checkout closes.
  bool _isLaunchingPayment = false;

  /// Why the payment for the already-booked parcel didn't start; the
  /// customer stays on the summary to try again or pay later.
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    _vm = sl<SendParcelViewModel>(param1: widget.direction);
    _previousState = _vm.state;
    _vm.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onStateChanged);
    _vm.dispose();
    super.dispose();
  }

  /// React to a successful backend submission or a submission failure.
  void _onStateChanged() {
    if (!mounted) return;
    final previous = _previousState;
    final next = _vm.state;
    _previousState = next;

    if (next.createdParcel != null &&
        next.createdParcel != previous.createdParcel) {
      _payThenTrack(next.createdParcel!, next);
    } else if (next.submitError != null &&
        next.submitError != previous.submitError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.submitError!)));
    }
    setState(() {});
  }

  /// Opens Paystack for the freshly created parcel — same flow as food
  /// orders — then replaces this wizard with tracking whatever the outcome
  /// (an unpaid parcel keeps its "Pay Now" button there). Skipped entirely
  /// when the wallet already settled the full charge.
  Future<void> _payThenTrack(Parcel parcel, SendParcelState state) async {
    if (parcel.needsPayment == false) {
      await _confirmPaidInFull(parcel);
      return;
    }
    // The created parcel's own payment state wins; the reviewed split is
    // only the fallback when the response doesn't say.
    final requiresPayment =
        parcel.needsPayment ?? !state.walletSplit.coversFully;
    final walletVm = context.read<CustomerWalletViewmodel>();
    final ordersVm = context.read<OrdersViewModel>();

    setState(() {
      _isLaunchingPayment = true;
      _paymentError = null;
    });
    final failure = await OrderPaymentLauncher.payThenTrack(
      context,
      orderId: parcel.id,
      requiresPayment: requiresPayment,
      useWallet: state.walletSplit.usesWallet,
      stayOnFailure: true,
      settledMessage: state.walletSplit.usesWallet
          ? 'Paid with your wallet — finding you a rider.'
          : 'Parcel confirmed — finding you a rider.',
    );
    // Both lists should now include the new parcel and its charge.
    walletVm.fetchWallet();
    ordersVm.refresh();
    if (mounted) {
      setState(() {
        _isLaunchingPayment = false;
        _paymentError = failure;
      });
    }
  }

  /// The create response says nothing is left to pay (the wallet covered it
  /// all): no gateway call, no "Pay Now" afterwards — confirm, then track.
  Future<void> _confirmPaidInFull(Parcel parcel) async {
    final walletVm = context.read<CustomerWalletViewmodel>();
    final ordersVm = context.read<OrdersViewModel>();
    ordersVm.markPaid(parcel.id);
    walletVm.fetchWallet();
    ordersVm.refresh();

    await CustomDialog.showSuccess(
      context: context,
      title: 'Payment complete',
      subtitle:
          'Your wallet covered the full amount. We\'re finding you a rider.',
      confirmText: 'Track parcel',
    );
    if (!mounted) return;
    AppNavigator.goToOrderTracking(context, parcel.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = _vm.state;
    final isSummary = state.currentStep == ParcelStep.summary;

    return ChangeNotifierProvider<SendParcelViewModel>.value(
      value: _vm,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.scaffold,
          appBar: _buildAppBar(context, state, _vm),
          body: Column(
            children: [
              // Step indicator is hidden on summary (map takes over)
              if (!isSummary)
                ParcelStepIndicator(
                  currentStep: state.currentStep,
                  direction: state.direction,
                ),

              // ── Step body ──────────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(state.currentStep),
                    child: _buildStep(context, state, _vm),
                  ),
                ),
              ),

              // The backend's reason the rider list didn't open.
              if (state.currentStep == ParcelStep.deliveryLocation &&
                  state.quoteBlockedMessage != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.sizeOf(context).width * 0.05,
                    0,
                    MediaQuery.sizeOf(context).width * 0.05,
                    MediaQuery.sizeOf(context).width * 0.03,
                  ),
                  child: InlineMessage(message: state.quoteBlockedMessage!),
                ),

              // The parcel is booked but its payment didn't start: say why and
              // offer to retry (the button below) or pay later from tracking.
              if (isSummary &&
                  state.createdParcel != null &&
                  _paymentError != null)
                _PaymentFailedBanner(
                  message: _paymentError!,
                  onPayLater: () => AppNavigator.goToOrderTracking(
                    context,
                    state.createdParcel!.id,
                  ),
                ),

              // ── Bottom action bar ──────────────────────────────────────────
              ParcelBottomBar(
                currentStep: state.currentStep,
                canProceed: state.canProceed,
                // On the delivery step Continue first checks the quote.
                isLoading:
                    state.isSubmitting ||
                    _isLaunchingPayment ||
                    (state.currentStep == ParcelStep.deliveryLocation &&
                        state.isFetchingQuote),
                showBack: state.createdParcel == null,
                confirmLabel: _confirmLabel(state),
                confirmIsFree: state.walletSplit.coversFully,
                onBack: _vm.goBack,
                onContinue: () => _handleContinue(context, state, _vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SendParcelState state,
    SendParcelViewModel vm,
  ) {
    final w = MediaQuery.sizeOf(context).width;

    return AppBar(
      backgroundColor: AppColors.scaffold,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () {
          // Once booked there is nothing to edit; leaving keeps the unpaid
          // parcel (with "Pay Now") in the customer's orders.
          if (state.currentStep == ParcelStep.packageType ||
              state.createdParcel != null) {
            Navigator.pop(context);
          } else {
            vm.goBack();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(w * 0.03),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.025),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: w * 0.045,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      title: Text(
        _stepTitle(state.currentStep, state.direction),
        style: TextStyle(
          fontSize: w * 0.042,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamily: 'Mukta',
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Step builder ──────────────────────────────────────────────────────────

  Widget _buildStep(
    BuildContext context,
    SendParcelState state,
    SendParcelViewModel vm,
  ) {
    switch (state.currentStep) {
      case ParcelStep.packageType:
        return PackageTypeStep(
          selectedType: state.packageType,
          onTypeSelected: vm.selectPackageType,
          direction: state.direction,
        );

      case ParcelStep.packageDetails:
        return PackageDetailsStep(
          images: state.packageImages,
          weightText: state.weightText,
          onImagesAdded: vm.addPackageImages,
          onImageRemoved: vm.removePackageImage,
          onWeightChanged: vm.setWeight,
          maxImages: SendParcelViewModel.maxImages,
          fragile: state.fragile,
          onFragileChanged: vm.setFragile,
          selectedSize: state.packageSize,
          onSizeChanged: vm.setPackageSize,
        );

      case ParcelStep.pickupLocation:
        final isReceive = state.direction.isReceive;
        return LocationPickerStep(
          title: isReceive ? "Sender's Location" : 'Pickup Location',
          subtitle: isReceive
              ? 'Where should the rider collect the package from?'
              : 'Where should the rider collect your package?',
          selectedLatLng: state.pickupLatLng,
          selectedAddress: state.pickupAddress,
          onLocationSelected: vm.setPickupLocation,
          footer: isReceive
              ? SenderContactCard(
                  name: state.senderName,
                  phone: state.senderPhone,
                  instructions: state.pickupInstructions,
                  onContactChanged: vm.setSenderContact,
                  onInstructionsChanged: vm.setPickupInstructions,
                )
              : null,
        );

      case ParcelStep.deliveryLocation:
        return DeliveryStopsStep(
          direction: state.direction,
          stops: state.deliveryStops,
          packageImages: state.packageImages,
          onStopUpdated: vm.updateDeliveryStop,
          onAddStop: vm.addDeliveryStop,
          onStopRemoved: vm.removeDeliveryStop,
          onStopDetailsChanged:
              (
                id, {
                required itemDescription,
                required quantity,
                required recipientName,
                required recipientPhone,
                required specialInstructions,
                required selectedImageIndices,
              }) => vm.updateDeliveryStopDetails(
                id,
                itemDescription: itemDescription,
                quantity: quantity,
                recipientName: recipientName,
                recipientPhone: recipientPhone,
                specialInstructions: specialInstructions,
                selectedImageIndices: selectedImageIndices,
              ),
          maxStops: SendParcelViewModel.maxStops,
        );

      case ParcelStep.availableRiders:
        return AvailableRidersStep(
          riderQuotes: state.riderQuotes,
          selectedRiderId: state.selectedRiderId,
          onSelectRider: vm.selectRider,
          distanceKm: state.distanceKm,
          etaMinutes: state.quotedEtaMinutes,
          quotedPrice: state.quotedPrice,
          quoteCurrency: state.quoteCurrency,
          isFetchingQuote: state.isFetchingQuote,
          quoteError: state.quoteError,
          noRidersMessage: state.noRidersMessage,
          onRetry: vm.fetchQuote,
          pickupLatLng: state.pickupLatLng,
          deliveryStops: state.deliveryStops,
        );

      case ParcelStep.summary:
        return ParcelSummaryStep(
          packageType: state.packageType ?? 'parcel',
          weightText: state.weightText,
          pickupAddress: state.pickupAddress,
          deliveryStops: state.deliveryStops,
          distanceKm: state.distanceKm,
          assignedRider: state.assignedRider,
          fragile: state.fragile,
          packageImages: state.packageImages,
        );
    }
  }

  /// "Pay GHS 18.05" — what goes to mobile money after the wallet — or
  /// "Confirm booking" when the wallet covers it all and nothing is paid.
  String _confirmLabel(SendParcelState state) {
    if (state.createdParcel != null) return 'Try payment again';
    if (state.quotedPrice == null) return 'Confirm & Pay';
    final split = state.walletSplit;
    if (split.coversFully) return 'Confirm';
    return 'Pay ${formatMoney(split.remaining, currency: state.quoteCurrency ?? 'GHS')}';
  }

  // ── Continue handler ──────────────────────────────────────────────────────

  void _handleContinue(
    BuildContext context,
    SendParcelState state,
    SendParcelViewModel vm,
  ) {
    if (state.currentStep == ParcelStep.summary) {
      final booked = state.createdParcel;
      if (booked != null) {
        _payThenTrack(booked, state);
      } else {
        vm.submitParcel();
      }
      return;
    }
    vm.advance();
  }

  // ── Step title ────────────────────────────────────────────────────────────

  String _stepTitle(ParcelStep step, ParcelDirection direction) {
    final isReceive = direction.isReceive;
    switch (step) {
      case ParcelStep.packageType:
        return isReceive ? 'Receive a Package' : 'Send a Package';
      case ParcelStep.packageDetails:
        return 'Package Details';
      case ParcelStep.pickupLocation:
        return isReceive ? "Sender's Location" : 'Pickup Location';
      case ParcelStep.deliveryLocation:
        return isReceive ? 'Deliver To' : 'Delivery Location';
      case ParcelStep.availableRiders:
        return 'Choose a Rider';
      case ParcelStep.summary:
        return 'Delivery Summary';
    }
  }
}

/// Shown on the summary when the booked parcel's payment couldn't start.
class _PaymentFailedBanner extends StatelessWidget {
  const _PaymentFailedBanner({required this.message, required this.onPayLater});

  final String message;
  final VoidCallback onPayLater;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InlineMessage(message: message),
          SizedBox(height: w * 0.01),
          TextButton(
            onPressed: onPayLater,
            child: const Text('Pay later from tracking'),
          ),
        ],
      ),
    );
  }
}
