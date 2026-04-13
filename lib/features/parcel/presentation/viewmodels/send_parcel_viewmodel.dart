import 'dart:io';
import 'dart:math' show cos, sqrt, asin, max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/delivery_stop.dart';
import '../../data/models/rider_model.dart';

// ── Step enum ────────────────────────────────────────────────────────────────

enum ParcelStep {
  packageType,
  packageDetails,
  pickupLocation,
  deliveryLocation,
  availableRiders,
  summary,
}

// ── State ────────────────────────────────────────────────────────────────────

class SendParcelState {
  final ParcelStep currentStep;
  final String? packageType; // 'document' | 'parcel'
  final List<File> packageImages;
  final List<String> imageBase64List;
  final String weightText;
  final LatLng? pickupLatLng;
  final String pickupAddress;

  /// One or more delivery destinations. Always has at least one entry.
  /// Users may add up to [SendParcelNotifier.maxStops] stops.
  final List<DeliveryStop> deliveryStops;

  final List<RiderModel> availableRiders;
  final String? selectedRiderId;

  /// Total route distance: pickup → stop1 → stop2 → … → stopN (km).
  final double distanceKm;
  final bool isLoadingRiders;

  /// Whether the package contains fragile items — shown to the rider.
  /// Matches the booking-level toggle used by Lalamove and GrabExpress.
  final bool fragile;

  const SendParcelState({
    this.currentStep = ParcelStep.packageType,
    this.packageType,
    this.packageImages = const [],
    this.imageBase64List = const [],
    this.weightText = '',
    this.pickupLatLng,
    this.pickupAddress = '',
    this.deliveryStops = const [DeliveryStop(id: 'stop_0')],
    this.availableRiders = const [],
    this.selectedRiderId,
    this.distanceKm = 0.0,
    this.isLoadingRiders = false,
    this.fragile = false,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  RiderModel? get selectedRider =>
      availableRiders.where((r) => r.id == selectedRiderId).firstOrNull;

  /// Additional fee for every stop beyond the first.
  double get extraStopSurchargeGhs {
    final extra = (deliveryStops.length - 1).clamp(0, 99);
    return extra * SendParcelNotifier.perStopFeeGhs;
  }

  /// Full cost including base fee, distance charge, and per-stop surcharge.
  double get totalCostGhs {
    final rider = selectedRider;
    if (rider == null) return 0.0;
    return rider.totalCost(distanceKm) + extraStopSurchargeGhs;
  }

  bool get canProceed {
    switch (currentStep) {
      case ParcelStep.packageType:
        return packageType != null;
      case ParcelStep.packageDetails:
        return weightText.isNotEmpty;
      case ParcelStep.pickupLocation:
        return pickupLatLng != null && pickupAddress.isNotEmpty;
      case ParcelStep.deliveryLocation:
        // All stops must be complete; at least one must exist.
        return deliveryStops.isNotEmpty &&
            deliveryStops.every((s) => s.isComplete);
      case ParcelStep.availableRiders:
        return selectedRiderId != null;
      case ParcelStep.summary:
        return true;
    }
  }

  SendParcelState copyWith({
    ParcelStep? currentStep,
    String? packageType,
    List<File>? packageImages,
    List<String>? imageBase64List,
    String? weightText,
    LatLng? pickupLatLng,
    String? pickupAddress,
    List<DeliveryStop>? deliveryStops,
    List<RiderModel>? availableRiders,
    String? selectedRiderId,
    double? distanceKm,
    bool? isLoadingRiders,
    bool? fragile,
  }) =>
      SendParcelState(
        currentStep: currentStep ?? this.currentStep,
        packageType: packageType ?? this.packageType,
        packageImages: packageImages ?? this.packageImages,
        imageBase64List: imageBase64List ?? this.imageBase64List,
        weightText: weightText ?? this.weightText,
        pickupLatLng: pickupLatLng ?? this.pickupLatLng,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        deliveryStops: deliveryStops ?? this.deliveryStops,
        availableRiders: availableRiders ?? this.availableRiders,
        selectedRiderId: selectedRiderId ?? this.selectedRiderId,
        distanceKm: distanceKm ?? this.distanceKm,
        isLoadingRiders: isLoadingRiders ?? this.isLoadingRiders,
        fragile: fragile ?? this.fragile,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SendParcelNotifier extends StateNotifier<SendParcelState> {
  SendParcelNotifier() : super(const SendParcelState());

  /// Maximum number of delivery stops a user may add.
  static const int maxStops = 5;

  static const int maxImages = 5;

  /// Extra fee charged per stop beyond the first, in GHS.
  static const double perStopFeeGhs = 2.0;

  /// Monotonically increasing counter — ensures stop IDs are never recycled
  /// after a remove+add cycle, preventing stale `_StopCardState` reuse.
  int _stopCounter = 1;

  // ── Step navigation ──────────────────────────────────────────────────────

  void advance() {
    if (!state.canProceed) return;
    final steps = ParcelStep.values;
    final next = state.currentStep.index + 1;
    if (next >= steps.length) return;

    final nextStep = steps[next];

    // When entering the riders step, compute the total route distance and
    // generate mock riders sized for that distance.
    if (nextStep == ParcelStep.availableRiders) {
      final dist = _calculateTotalRouteDistance();
      final riders = _generateRiders(dist);
      state = state.copyWith(
        currentStep: nextStep,
        distanceKm: dist,
        availableRiders: riders,
      );
      return;
    }

    state = state.copyWith(currentStep: nextStep);
  }

  void goBack() {
    final prev = state.currentStep.index - 1;
    if (prev < 0) return;
    state = state.copyWith(currentStep: ParcelStep.values[prev]);
  }

  // ── Package type ─────────────────────────────────────────────────────────

  void selectPackageType(String type) =>
      state = state.copyWith(packageType: type);

  // ── Package details ──────────────────────────────────────────────────────

  void addPackageImages(List<File> newFiles, List<String> newBase64List) {
    final updatedFiles = [...state.packageImages, ...newFiles];
    final updatedBase64 = [...state.imageBase64List, ...newBase64List];
    state = state.copyWith(
      packageImages: updatedFiles,
      imageBase64List: updatedBase64,
    );
  }

  void removePackageImage(int index) {
    final files = [...state.packageImages]..removeAt(index);
    final base64s = [...state.imageBase64List]..removeAt(index);
    state = state.copyWith(packageImages: files, imageBase64List: base64s);
  }

  void setWeight(String weight) => state = state.copyWith(weightText: weight);

  void setFragile(bool value) => state = state.copyWith(fragile: value);

  // ── Pickup location ───────────────────────────────────────────────────────

  void setPickupLocation(LatLng latLng, String address) =>
      state = state.copyWith(pickupLatLng: latLng, pickupAddress: address);

  // ── Delivery stops ────────────────────────────────────────────────────────

  /// Updates the location of an existing stop identified by [id].
  void updateDeliveryStop(String id, LatLng latLng, String address) {
    final stops = state.deliveryStops
        .map((s) => s.id == id ? s.copyWith(latLng: latLng, address: address) : s)
        .toList();
    state = state.copyWith(deliveryStops: stops);
  }

  /// Appends a blank stop. No-op when [maxStops] is already reached OR
  /// when the current last stop is not yet complete (prevents orphaned stops).
  void addDeliveryStop() {
    if (state.deliveryStops.length >= maxStops) return;
    if (state.deliveryStops.isNotEmpty && !state.deliveryStops.last.isComplete) {
      return;
    }
    final newId = 'stop_${_stopCounter++}';
    final stops = [...state.deliveryStops, DeliveryStop(id: newId)];
    state = state.copyWith(deliveryStops: stops);
  }

  /// Updates the optional item details for the stop identified by [id].
  /// Called on every keystroke / qty tap — no explicit "save" needed.
  void updateDeliveryStopDetails(
    String id, {
    required String itemDescription,
    required int quantity,
    required String recipientName,
    required String recipientPhone,
    required String specialInstructions,
    required List<int> selectedImageIndices,
  }) {
    final stops = state.deliveryStops
        .map(
          (s) => s.id == id
              ? s.copyWith(
                  itemDescription: itemDescription,
                  quantity: quantity,
                  recipientName: recipientName,
                  recipientPhone: recipientPhone,
                  specialInstructions: specialInstructions,
                  selectedImageIndices: selectedImageIndices,
                )
              : s,
        )
        .toList();
    state = state.copyWith(deliveryStops: stops);
  }

  /// Removes the stop with [id]. No-op when only one stop remains.
  void removeDeliveryStop(String id) {
    if (state.deliveryStops.length <= 1) return;
    final stops = state.deliveryStops.where((s) => s.id != id).toList();
    state = state.copyWith(deliveryStops: stops);
  }

  // ── Rider selection ──────────────────────────────────────────────────────

  void selectRider(String riderId) =>
      state = state.copyWith(selectedRiderId: riderId);

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Calculates the total route distance:
  /// pickup → stop[0] → stop[1] → … → stop[n-1]
  double _calculateTotalRouteDistance() {
    final stops = state.deliveryStops;
    if (stops.isEmpty || state.pickupLatLng == null) return 0.0;

    double total = _haversine(state.pickupLatLng!, stops.first.latLng!);
    for (int i = 0; i < stops.length - 1; i++) {
      total += _haversine(stops[i].latLng!, stops[i + 1].latLng!);
    }
    return total;
  }

  double _haversine(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final c = cos;
    final val = 0.5 -
        c((b.latitude - a.latitude) * p) / 2 +
        c(a.latitude * p) *
            c(b.latitude * p) *
            (1 - c((b.longitude - a.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(val));
  }

  List<RiderModel> _generateRiders(double distanceKm) => [
        RiderModel(
          id: 'r1',
          name: 'Kwame Asante',
          vehicle: VehicleType.motorbike,
          rating: 4.8,
          reviewCount: 142,
          baseFeeGhs: 5.0,
          perKmFeeGhs: 2.5,
          etaMinutes: max(6, (distanceKm * 2.2).round()),
          initials: 'KA',
        ),
        RiderModel(
          id: 'r2',
          name: 'Abena Mensah',
          vehicle: VehicleType.bicycle,
          rating: 4.6,
          reviewCount: 89,
          baseFeeGhs: 3.0,
          perKmFeeGhs: 1.5,
          etaMinutes: max(10, (distanceKm * 4.5).round()),
          initials: 'AM',
        ),
        RiderModel(
          id: 'r3',
          name: 'Yaw Boateng',
          vehicle: VehicleType.car,
          rating: 4.9,
          reviewCount: 214,
          baseFeeGhs: 10.0,
          perKmFeeGhs: 4.0,
          etaMinutes: max(4, (distanceKm * 1.6).round()),
          initials: 'YB',
        ),
        RiderModel(
          id: 'r4',
          name: 'Ama Darko',
          vehicle: VehicleType.motorbike,
          rating: 4.7,
          reviewCount: 97,
          baseFeeGhs: 5.0,
          perKmFeeGhs: 2.8,
          etaMinutes: max(5, (distanceKm * 2.0).round()),
          initials: 'AD',
        ),
      ];
}

// ── Provider ─────────────────────────────────────────────────────────────────

final sendParcelProvider =
    StateNotifierProvider.autoDispose<SendParcelNotifier, SendParcelState>(
  (ref) => SendParcelNotifier(),
);
