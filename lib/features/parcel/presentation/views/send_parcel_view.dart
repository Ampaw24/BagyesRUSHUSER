import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/router/app_navigator.dart';
import '../viewmodels/send_parcel_viewmodel.dart';
import '../widgets/available_riders_step.dart';
import '../widgets/delivery_stops_step.dart';
import '../widgets/location_picker_step.dart';
import '../widgets/package_details_step.dart';
import '../widgets/package_type_step.dart';
import '../widgets/parcel_bottom_bar.dart';
import '../widgets/parcel_step_indicator.dart';
import '../widgets/parcel_summary_step.dart';

class SendParcelView extends ConsumerWidget {
  const SendParcelView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sendParcelProvider);
    final notifier = ref.read(sendParcelProvider.notifier);
    final isSummary = state.currentStep == ParcelStep.summary;

    // React to a successful backend submission or a submission failure.
    ref.listen<SendParcelState>(sendParcelProvider, (previous, next) {
      if (next.createdParcel != null &&
          next.createdParcel != previous?.createdParcel) {
        AppNavigator.toOrderTracking(context, next.createdParcel!.id);
      } else if (next.submitError != null &&
          next.submitError != previous?.submitError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.submitError!)),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: _buildAppBar(context, state, notifier),
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
                  child: _buildStep(context, state, notifier),
                ),
              ),
            ),

            // ── Bottom action bar ──────────────────────────────────────────
            ParcelBottomBar(
              currentStep: state.currentStep,
              canProceed: state.canProceed,
              isLoading: state.isSubmitting,
              onBack: notifier.goBack,
              onContinue: () => _handleContinue(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SendParcelState state,
    SendParcelNotifier notifier,
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
            notifier.goBack();
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
    SendParcelNotifier notifier,
  ) {
    switch (state.currentStep) {
      case ParcelStep.packageType:
        return PackageTypeStep(
          selectedType: state.packageType,
          onTypeSelected: notifier.selectPackageType,
        );

      case ParcelStep.packageDetails:
        return PackageDetailsStep(
          images: state.packageImages,
          weightText: state.weightText,
          onImagesAdded: notifier.addPackageImages,
          onImageRemoved: notifier.removePackageImage,
          onWeightChanged: notifier.setWeight,
          maxImages: SendParcelNotifier.maxImages,
          fragile: state.fragile,
          onFragileChanged: notifier.setFragile,
          selectedSize: state.packageSize,
          onSizeChanged: notifier.setPackageSize,
        );

      case ParcelStep.pickupLocation:
        return LocationPickerStep(
          title: 'Pickup Location',
          subtitle: 'Where should the rider collect your package?',
          selectedLatLng: state.pickupLatLng,
          selectedAddress: state.pickupAddress,
          onLocationSelected: notifier.setPickupLocation,
        );

      case ParcelStep.deliveryLocation:
        return DeliveryStopsStep(
          stops: state.deliveryStops,
          packageImages: state.packageImages,
          onStopUpdated: notifier.updateDeliveryStop,
          onAddStop: notifier.addDeliveryStop,
          onStopRemoved: notifier.removeDeliveryStop,
          onStopDetailsChanged: (
            id, {
            required itemDescription,
            required quantity,
            required recipientName,
            required recipientPhone,
            required specialInstructions,
            required selectedImageIndices,
          }) =>
              notifier.updateDeliveryStopDetails(
            id,
            itemDescription: itemDescription,
            quantity: quantity,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            specialInstructions: specialInstructions,
            selectedImageIndices: selectedImageIndices,
          ),
          maxStops: SendParcelNotifier.maxStops,
        );

      case ParcelStep.availableRiders:
        return AvailableRidersStep(
          riders: state.availableRiders,
          selectedRiderId: state.selectedRiderId,
          distanceKm: state.distanceKm,
          extraStopSurchargeGhs: state.extraStopSurchargeGhs,
          onRiderSelected: notifier.selectRider,
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
    SendParcelNotifier notifier,
  ) {
    if (state.currentStep == ParcelStep.summary) {
      notifier.submitParcel();
      return;
    }
    notifier.advance();
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
        return 'Order Summary';
    }
  }
}
