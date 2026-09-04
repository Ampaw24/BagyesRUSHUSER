import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_navigator.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';
import '../widgets/available_riders_step.dart';
import '../widgets/delivery_stops_step.dart';
import '../widgets/location_picker_step.dart';
import '../widgets/package_details_step.dart';
import '../widgets/package_type_step.dart';
import '../widgets/parcel_bottom_bar.dart';
import '../widgets/parcel_step_indicator.dart';
import '../widgets/parcel_summary_step.dart';

class SendParcelView extends StatefulWidget {
  const SendParcelView({super.key});

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
  SendParcelState _previousState = const SendParcelState();

  @override
  void initState() {
    super.initState();
    _vm = sl<SendParcelViewModel>();
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
      AppNavigator.toOrderTracking(context, next.createdParcel!.id);
    } else if (next.submitError != null &&
        next.submitError != previous.submitError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.submitError!)),
      );
    }
    setState(() {});
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
                ParcelStepIndicator(currentStep: state.currentStep),

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

              // ── Bottom action bar ──────────────────────────────────────────
              ParcelBottomBar(
                currentStep: state.currentStep,
                canProceed: state.canProceed,
                isLoading: state.isSubmitting,
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
          if (state.currentStep == ParcelStep.packageType) {
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
        _stepTitle(state.currentStep),
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
        return LocationPickerStep(
          title: 'Pickup Location',
          subtitle: 'Where should the rider collect your package?',
          selectedLatLng: state.pickupLatLng,
          selectedAddress: state.pickupAddress,
          onLocationSelected: vm.setPickupLocation,
        );

      case ParcelStep.deliveryLocation:
        return DeliveryStopsStep(
          stops: state.deliveryStops,
          packageImages: state.packageImages,
          onStopUpdated: vm.updateDeliveryStop,
          onAddStop: vm.addDeliveryStop,
          onStopRemoved: vm.removeDeliveryStop,
          onStopDetailsChanged: (
            id, {
            required itemDescription,
            required quantity,
            required recipientName,
            required recipientPhone,
            required specialInstructions,
            required selectedImageIndices,
          }) =>
              vm.updateDeliveryStopDetails(
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
          riders: state.availableRiders,
          selectedRiderId: state.selectedRiderId,
          distanceKm: state.distanceKm,
          extraStopSurchargeGhs: state.extraStopSurchargeGhs,
          onRiderSelected: vm.selectRider,
        );

      case ParcelStep.summary:
        return ParcelSummaryStep(
          packageType: state.packageType ?? 'parcel',
          weightText: state.weightText,
          pickupAddress: state.pickupAddress,
          deliveryStops: state.deliveryStops,
          distanceKm: state.distanceKm,
          extraStopSurchargeGhs: state.extraStopSurchargeGhs,
          selectedRider: state.selectedRider,
          totalCostGhs: state.totalCostGhs,
          fragile: state.fragile,
          packageImages: state.packageImages,
        );
    }
  }

  // ── Continue handler ──────────────────────────────────────────────────────

  void _handleContinue(
    BuildContext context,
    SendParcelState state,
    SendParcelViewModel vm,
  ) {
    if (state.currentStep == ParcelStep.summary) {
      vm.submitParcel();
      return;
    }
    vm.advance();
  }

  // ── Step title ────────────────────────────────────────────────────────────

  String _stepTitle(ParcelStep step) {
    switch (step) {
      case ParcelStep.packageType:
        return 'Send a Package';
      case ParcelStep.packageDetails:
        return 'Package Details';
      case ParcelStep.pickupLocation:
        return 'Pickup Location';
      case ParcelStep.deliveryLocation:
        return 'Delivery Location';
      case ParcelStep.availableRiders:
        return 'Choose a Rider';
      case ParcelStep.summary:
        return 'Delivery Summary';
    }
  }
}
