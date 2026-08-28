import 'dart:io';
import 'dart:math' show cos, sqrt, asin, max;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import '../../data/models/delivery_stop.dart';
import '../../data/models/rider_model.dart';

/// Sentinel used by [SendParcelState.copyWith] to distinguish "leave
/// unchanged" from "explicitly set to null" for nullable fields.
const _unset = Object();

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

  /// Backend size category (e.g. 'envelope', 'small', 'medium', 'large',
  /// 'heavy') selected in [PackageDetailsStep] — sent as `size` on every
  /// stop in the create/quote requests.
  final String packageSize;

  // ── Backend quote (authoritative price) ───────────────────────────────────
  final bool isFetchingQuote;
  final String? quoteError;
  final double? quotedPrice;
  final String? quoteCurrency;

  // ── Payment + submission ────────────────────────────────────────────────
  final PaymentMethod? selectedPaymentMethod;
  final bool isSubmitting;
  final String? submitError;
  final Parcel? createdParcel;

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
    this.packageSize = '',
    this.isFetchingQuote = false,
    this.quoteError,
    this.quotedPrice,
    this.quoteCurrency,
    this.selectedPaymentMethod,
    this.isSubmitting = false,
    this.submitError,
    this.createdParcel,
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
        return selectedPaymentMethod != null && !isSubmitting;
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
    String? packageSize,
    bool? isFetchingQuote,
    Object? quoteError = _unset,
    Object? quotedPrice = _unset,
    Object? quoteCurrency = _unset,
    Object? selectedPaymentMethod = _unset,
    bool? isSubmitting,
    Object? submitError = _unset,
    Object? createdParcel = _unset,
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
        packageSize: packageSize ?? this.packageSize,
        isFetchingQuote: isFetchingQuote ?? this.isFetchingQuote,
        quoteError:
            identical(quoteError, _unset) ? this.quoteError : quoteError as String?,
        quotedPrice: identical(quotedPrice, _unset)
            ? this.quotedPrice
            : quotedPrice as double?,
        quoteCurrency: identical(quoteCurrency, _unset)
            ? this.quoteCurrency
            : quoteCurrency as String?,
        selectedPaymentMethod: identical(selectedPaymentMethod, _unset)
            ? this.selectedPaymentMethod
            : selectedPaymentMethod as PaymentMethod?,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitError: identical(submitError, _unset)
            ? this.submitError
            : submitError as String?,
        createdParcel: identical(createdParcel, _unset)
            ? this.createdParcel
            : createdParcel as Parcel?,
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

  /// Backend photo id for each already-uploaded image, keyed by its index
  /// in [SendParcelState.packageImages]. Avoids re-uploading the same
  /// image if the user retries submission after a failure.
  final Map<int, int> _uploadedPhotoIds = {};

  ParcelRepository get _repository => sl<ParcelRepository>();

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

    // When entering the summary step, fetch the authoritative backend
    // quote up front so the customer sees the real price before paying.
    if (nextStep == ParcelStep.summary) {
      state = state.copyWith(currentStep: nextStep);
      fetchQuote();
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

  /// Sets the backend size category (e.g. 'small', 'medium') selected in
  /// the package-size picker. Sent as `size` on every stop.
  void setPackageSize(String size) =>
      state = state.copyWith(packageSize: size);

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

  // ── Payment method ────────────────────────────────────────────────────────

  void selectPaymentMethod(PaymentMethod method) =>
      state = state.copyWith(selectedPaymentMethod: method, submitError: null);

  // ── Backend quote ────────────────────────────────────────────────────────

  /// Fetches the authoritative delivery quote from the backend so the
  /// customer sees the real price on the summary screen before paying.
  /// This is a display-only fetch — [submitParcel] always requests a fresh
  /// quote of its own right before creating the parcel, so a stale price
  /// shown here can never be what actually gets charged.
  Future<void> fetchQuote() async {
    if (state.pickupLatLng == null || state.deliveryStops.isEmpty) return;

    state = state.copyWith(isFetchingQuote: true, quoteError: null);

    final result = await _repository.getParcelQuote(
      pickupAddress: state.pickupAddress,
      pickupLatitude: state.pickupLatLng!.latitude,
      pickupLongitude: state.pickupLatLng!.longitude,
      stops: _quoteStops(),
    );

    result.fold(
      (failure) => state = state.copyWith(
        isFetchingQuote: false,
        quoteError: failure.message,
      ),
      (quote) => state = state.copyWith(
        isFetchingQuote: false,
        quotedPrice: quote.price,
        quoteCurrency: quote.currency,
      ),
    );
  }

  // ── Submission ───────────────────────────────────────────────────────────

  /// Uploads any tagged photos, requests a fresh backend quote, then
  /// creates the parcel using that quote's id — the price actually charged
  /// always comes from the backend, never from the client-side estimate.
  Future<bool> submitParcel() async {
    if (state.pickupLatLng == null ||
        state.deliveryStops.isEmpty ||
        !state.deliveryStops.every((s) => s.isComplete)) {
      return false;
    }
    final method = state.selectedPaymentMethod;
    if (method == null) {
      state = state.copyWith(submitError: 'Please select a payment method.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, submitError: null);

    try {
      final stops = await _buildStopsWithPhotos();

      final quoteResult = await _repository.getParcelQuote(
        pickupAddress: state.pickupAddress,
        pickupLatitude: state.pickupLatLng!.latitude,
        pickupLongitude: state.pickupLatLng!.longitude,
        stops: stops,
      );

      return await quoteResult.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, submitError: failure.message);
          return false;
        },
        (quote) async {
          final createResult = await _repository.createParcel(
            deliveryQuoteId: quote.id,
            // Customers only ever have saved mobile-money accounts (see
            // getCustomerPaymentMethods) — mirrors the checkout flow, where
            // 'card' is likewise never offered to select from.
            paymentMethod: 'mobile_money',
            paymentMethodId: int.tryParse(method.id),
            stops: stops,
            pickupAddress: state.pickupAddress,
          );

          return createResult.fold(
            (failure) {
              state =
                  state.copyWith(isSubmitting: false, submitError: failure.message);
              return false;
            },
            (parcel) {
              state = state.copyWith(isSubmitting: false, createdParcel: parcel);
              return true;
            },
          );
        },
      );
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _resolvedSize => state.packageSize.isNotEmpty
      ? state.packageSize
      : 'medium';

  double? get _resolvedWeightKg => double.tryParse(state.weightText);

  /// Lightweight stop shape for the quote endpoint — location, size,
  /// fragility and weight only.
  List<ParcelStop> _quoteStops() => state.deliveryStops
      .where((s) => s.latLng != null)
      .map(
        (s) => ParcelStop(
          address: s.address,
          latitude: s.latLng!.latitude,
          longitude: s.latLng!.longitude,
          size: _resolvedSize,
          isFragile: state.fragile,
          weightKg: _resolvedWeightKg,
        ),
      )
      .toList();

  /// Full stop shape for the create endpoint, uploading any tagged photos
  /// that haven't been uploaded yet and reusing cached ids for the rest.
  Future<List<ParcelStop>> _buildStopsWithPhotos() async {
    final stops = <ParcelStop>[];

    for (final stop in state.deliveryStops) {
      final photoIds = <int>[];
      for (final imageIndex in stop.selectedImageIndices) {
        if (imageIndex >= state.packageImages.length) continue;

        final cachedId = _uploadedPhotoIds[imageIndex];
        if (cachedId != null) {
          photoIds.add(cachedId);
          continue;
        }

        final uploadResult = await _repository.uploadParcelPhoto(
          filePath: state.packageImages[imageIndex].path,
        );
        uploadResult.fold(
          (_) {},
          (photo) {
            _uploadedPhotoIds[imageIndex] = photo.id;
            photoIds.add(photo.id);
          },
        );
      }

      stops.add(
        ParcelStop(
          address: stop.address,
          latitude: stop.latLng!.latitude,
          longitude: stop.latLng!.longitude,
          recipientName: stop.recipientName.isEmpty ? null : stop.recipientName,
          recipientPhone:
              stop.recipientPhone.isEmpty ? null : stop.recipientPhone,
          instructions:
              stop.specialInstructions.isEmpty ? null : stop.specialInstructions,
          itemDescription:
              stop.itemDescription.isEmpty ? null : stop.itemDescription,
          size: _resolvedSize,
          quantity: stop.quantity,
          isFragile: state.fragile,
          weightKg: _resolvedWeightKg,
          photoIds: photoIds.isEmpty ? null : photoIds,
        ),
      );
    }

    return stops;
  }

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
