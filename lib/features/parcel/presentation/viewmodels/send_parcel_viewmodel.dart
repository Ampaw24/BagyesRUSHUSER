import 'dart:io';
import 'dart:math' show cos, sqrt, asin, max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final LatLng? deliveryLatLng;
  final String deliveryAddress;
  final List<RiderModel> availableRiders;
  final String? selectedRiderId;
  final double distanceKm;
  final bool isLoadingRiders;

  const SendParcelState({
    this.currentStep = ParcelStep.packageType,
    this.packageType,
    this.packageImages = const [],
    this.imageBase64List = const [],
    this.weightText = '',
    this.pickupLatLng,
    this.pickupAddress = '',
    this.deliveryLatLng,
    this.deliveryAddress = '',
    this.availableRiders = const [],
    this.selectedRiderId,
    this.distanceKm = 0.0,
    this.isLoadingRiders = false,
  });

  RiderModel? get selectedRider =>
      availableRiders.where((r) => r.id == selectedRiderId).firstOrNull;

  double get totalCostGhs => selectedRider?.totalCost(distanceKm) ?? 0.0;

  bool get canProceed {
    switch (currentStep) {
      case ParcelStep.packageType:
        return packageType != null;
      case ParcelStep.packageDetails:
        return weightText.isNotEmpty && packageImages.isNotEmpty;
      case ParcelStep.pickupLocation:
        return pickupLatLng != null && pickupAddress.isNotEmpty;
      case ParcelStep.deliveryLocation:
        return deliveryLatLng != null && deliveryAddress.isNotEmpty;
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
    LatLng? deliveryLatLng,
    String? deliveryAddress,
    List<RiderModel>? availableRiders,
    String? selectedRiderId,
    double? distanceKm,
    bool? isLoadingRiders,
  }) =>
      SendParcelState(
        currentStep: currentStep ?? this.currentStep,
        packageType: packageType ?? this.packageType,
        packageImages: packageImages ?? this.packageImages,
        imageBase64List: imageBase64List ?? this.imageBase64List,
        weightText: weightText ?? this.weightText,
        pickupLatLng: pickupLatLng ?? this.pickupLatLng,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        deliveryLatLng: deliveryLatLng ?? this.deliveryLatLng,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        availableRiders: availableRiders ?? this.availableRiders,
        selectedRiderId: selectedRiderId ?? this.selectedRiderId,
        distanceKm: distanceKm ?? this.distanceKm,
        isLoadingRiders: isLoadingRiders ?? this.isLoadingRiders,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SendParcelNotifier extends StateNotifier<SendParcelState> {
  SendParcelNotifier() : super(const SendParcelState());

  // ── Step navigation ──────────────────────────────────────────────────────

  void advance() {
    if (!state.canProceed) return;
    final steps = ParcelStep.values;
    final next = state.currentStep.index + 1;
    if (next >= steps.length) return;

    final nextStep = steps[next];

    // When moving to riders step, compute distance and generate mock riders.
    if (nextStep == ParcelStep.availableRiders) {
      final dist = _haversine(state.pickupLatLng!, state.deliveryLatLng!);
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

  static const int maxImages = 5;

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

  // ── Locations ────────────────────────────────────────────────────────────

  void setPickupLocation(LatLng latLng, String address) =>
      state = state.copyWith(pickupLatLng: latLng, pickupAddress: address);

  void setDeliveryLocation(LatLng latLng, String address) =>
      state = state.copyWith(deliveryLatLng: latLng, deliveryAddress: address);

  // ── Rider selection ──────────────────────────────────────────────────────

  void selectRider(String riderId) =>
      state = state.copyWith(selectedRiderId: riderId);

  // ── Helpers ──────────────────────────────────────────────────────────────

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
