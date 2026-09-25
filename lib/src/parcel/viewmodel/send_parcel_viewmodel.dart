import 'dart:io';
import 'dart:math' show cos, sqrt, asin;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/delivery_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';

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
  /// Users may add up to [SendParcelViewModel.maxStops] stops.
  final List<DeliveryStop> deliveryStops;

  /// Total route distance: pickup → stop1 → stop2 → … → stopN (km).
  final double distanceKm;

  /// Whether the package contains fragile items — shown to the rider.
  /// Matches the booking-level toggle used by Lalamove and GrabExpress.
  final bool fragile;

  /// Backend size category (e.g. 'envelope', 'small', 'medium', 'large',
  /// 'heavy') selected in [PackageDetailsStep] — sent as `size` on every
  /// stop in the create/quote requests.
  final String packageSize;

  // ── Backend quote (authoritative price + matched rider) ────────────────────
  final bool isFetchingQuote;

  /// Set only when the request never reached the server (timeout, no
  /// internet) — drives the "Couldn't reach the server" error state.
  final String? quoteError;

  /// Set when the server responded but couldn't match a rider (e.g. "No
  /// riders are available near that pickup point right now") — a normal
  /// business outcome, not a connectivity error, so it drives the muted
  /// "no riders nearby" state instead of an error screen.
  final String? noRidersMessage;
  final double? quotedPrice;
  final String? quoteCurrency;
  final int? quotedEtaMinutes;

  /// The rider the backend matched to the current quote. Null while
  /// fetching, on error, or when no rider is available nearby.
  final RiderModel? assignedRider;

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
    this.distanceKm = 0.0,
    this.fragile = false,
    this.packageSize = '',
    this.isFetchingQuote = false,
    this.quoteError,
    this.noRidersMessage,
    this.quotedPrice,
    this.quoteCurrency,
    this.quotedEtaMinutes,
    this.assignedRider,
    this.selectedPaymentMethod,
    this.isSubmitting = false,
    this.submitError,
    this.createdParcel,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

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
        return !isFetchingQuote && assignedRider != null;
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
    double? distanceKm,
    bool? fragile,
    String? packageSize,
    bool? isFetchingQuote,
    Object? quoteError = _unset,
    Object? noRidersMessage = _unset,
    Object? quotedPrice = _unset,
    Object? quoteCurrency = _unset,
    Object? quotedEtaMinutes = _unset,
    Object? assignedRider = _unset,
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
        distanceKm: distanceKm ?? this.distanceKm,
        fragile: fragile ?? this.fragile,
        packageSize: packageSize ?? this.packageSize,
        isFetchingQuote: isFetchingQuote ?? this.isFetchingQuote,
        quoteError:
            identical(quoteError, _unset) ? this.quoteError : quoteError as String?,
        noRidersMessage: identical(noRidersMessage, _unset)
            ? this.noRidersMessage
            : noRidersMessage as String?,
        quotedPrice: identical(quotedPrice, _unset)
            ? this.quotedPrice
            : quotedPrice as double?,
        quoteCurrency: identical(quoteCurrency, _unset)
            ? this.quoteCurrency
            : quoteCurrency as String?,
        quotedEtaMinutes: identical(quotedEtaMinutes, _unset)
            ? this.quotedEtaMinutes
            : quotedEtaMinutes as int?,
        assignedRider: identical(assignedRider, _unset)
            ? this.assignedRider
            : assignedRider as RiderModel?,
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

// ── ViewModel ────────────────────────────────────────────────────────────────

class SendParcelViewModel extends ViewModel<SendParcelState> {
  SendParcelViewModel(this._repository) : super(const SendParcelState());

  final ParcelRepository _repository;

  /// Maximum number of delivery stops a user may add.
  static const int maxStops = 5;

  static const int maxImages = 5;

  /// Monotonically increasing counter — ensures stop IDs are never recycled
  /// after a remove+add cycle, preventing stale `_StopCardState` reuse.
  int _stopCounter = 1;

  /// Backend photo id for each already-uploaded image, keyed by its index
  /// in [SendParcelState.packageImages]. Avoids re-uploading the same
  /// image if the user retries submission after a failure.
  final Map<int, int> _uploadedPhotoIds = {};

  // ── Step navigation ──────────────────────────────────────────────────────

  void advance() {
    if (!state.canProceed) return;
    final steps = ParcelStep.values;
    final next = state.currentStep.index + 1;
    if (next >= steps.length) return;

    final nextStep = steps[next];

    // When entering the riders step, compute the client-side route distance
    // for immediate display, then fetch the real backend quote — which is
    // what actually matches and returns the assigned rider.
    if (nextStep == ParcelStep.availableRiders) {
      final dist = _calculateTotalRouteDistance();
      emit(state.copyWith(currentStep: nextStep, distanceKm: dist));
      fetchQuote();
      return;
    }

    // When entering the summary step, re-fetch the quote so the price and
    // assigned rider shown are fresh right before paying.
    if (nextStep == ParcelStep.summary) {
      emit(state.copyWith(currentStep: nextStep));
      fetchQuote();
      return;
    }

    emit(state.copyWith(currentStep: nextStep));
  }

  void goBack() {
    final prev = state.currentStep.index - 1;
    if (prev < 0) return;
    emit(state.copyWith(currentStep: ParcelStep.values[prev]));
  }

  // ── Package type ─────────────────────────────────────────────────────────

  void selectPackageType(String type) =>
      emit(state.copyWith(packageType: type));

  // ── Package details ──────────────────────────────────────────────────────

  void addPackageImages(List<File> newFiles, List<String> newBase64List) {
    final updatedFiles = [...state.packageImages, ...newFiles];
    final updatedBase64 = [...state.imageBase64List, ...newBase64List];
    emit(state.copyWith(
      packageImages: updatedFiles,
      imageBase64List: updatedBase64,
    ));
  }

  void removePackageImage(int index) {
    final files = [...state.packageImages]..removeAt(index);
    final base64s = [...state.imageBase64List]..removeAt(index);
    emit(state.copyWith(packageImages: files, imageBase64List: base64s));
  }

  void setWeight(String weight) => emit(state.copyWith(weightText: weight));

  void setFragile(bool value) => emit(state.copyWith(fragile: value));

  /// Sets the backend size category (e.g. 'small', 'medium') selected in
  /// the package-size picker. Sent as `size` on every stop.
  void setPackageSize(String size) =>
      emit(state.copyWith(packageSize: size));

  // ── Pickup location ───────────────────────────────────────────────────────

  void setPickupLocation(LatLng latLng, String address) =>
      emit(state.copyWith(pickupLatLng: latLng, pickupAddress: address));

  // ── Delivery stops ────────────────────────────────────────────────────────

  /// Updates the location of an existing stop identified by [id].
  void updateDeliveryStop(String id, LatLng latLng, String address) {
    final stops = state.deliveryStops
        .map((s) => s.id == id ? s.copyWith(latLng: latLng, address: address) : s)
        .toList();
    emit(state.copyWith(deliveryStops: stops));
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
    emit(state.copyWith(deliveryStops: stops));
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
    emit(state.copyWith(deliveryStops: stops));
  }

  /// Removes the stop with [id]. No-op when only one stop remains.
  void removeDeliveryStop(String id) {
    if (state.deliveryStops.length <= 1) return;
    final stops = state.deliveryStops.where((s) => s.id != id).toList();
    emit(state.copyWith(deliveryStops: stops));
  }

  // ── Payment method ────────────────────────────────────────────────────────

  void selectPaymentMethod(PaymentMethod method) =>
      emit(state.copyWith(selectedPaymentMethod: method, submitError: null));

  // ── Backend quote ────────────────────────────────────────────────────────

  /// Fetches the authoritative delivery quote from the backend — this is
  /// also how a rider gets matched, since the backend embeds the nearest
  /// available rider on the quote response. This is a display-only fetch —
  /// [submitParcel] always requests a fresh quote of its own right before
  /// creating the parcel, so a stale price/rider shown here can never be
  /// what actually gets charged/assigned.
  Future<void> fetchQuote() async {
    if (state.pickupLatLng == null || state.deliveryStops.isEmpty) return;

    emit(state.copyWith(
      isFetchingQuote: true,
      quoteError: null,
      noRidersMessage: null,
    ));

    final result = await _repository.getParcelQuote(
      pickupAddress: state.pickupAddress,
      pickupLatitude: state.pickupLatLng!.latitude,
      pickupLongitude: state.pickupLatLng!.longitude,
      stops: _quoteStops(),
    );

    result.fold(
      // A connectivity failure (timeout/no internet) never reached the
      // backend, so it's a true error state. Anything else is the server
      // responding that it couldn't match a rider — a normal "try again
      // shortly" outcome, not something to alarm the user about.
      (failure) => emit(state.copyWith(
        isFetchingQuote: false,
        quoteError: failure.isConnectivityFailure ? failure.message : null,
        noRidersMessage: failure.isConnectivityFailure ? null : failure.message,
        assignedRider: null,
      )),
      (quote) => emit(state.copyWith(
        isFetchingQuote: false,
        quotedPrice: quote.price,
        quoteCurrency: quote.currency,
        quotedEtaMinutes: quote.etaMinutes,
        assignedRider: quote.rider,
      )),
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
      emit(state.copyWith(submitError: 'Please select a payment method.'));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, submitError: null));

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
          emit(state.copyWith(isSubmitting: false, submitError: failure.message));
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
              emit(state.copyWith(
                  isSubmitting: false, submitError: failure.message));
              return false;
            },
            (parcel) {
              emit(state.copyWith(isSubmitting: false, createdParcel: parcel));
              return true;
            },
          );
        },
      );
    } catch (_) {
      emit(state.copyWith(
        isSubmitting: false,
        submitError: 'Something went wrong. Please try again.',
      ));
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
}
