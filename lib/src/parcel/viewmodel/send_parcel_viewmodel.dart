import 'dart:async';
import 'dart:io';
import 'dart:math' show cos, sqrt, asin;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';
import 'package:bagyesrushappusernew/core/utils/phone_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/wallet_split.dart';
import 'package:bagyesrushappusernew/src/parcel/model/delivery_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_direction.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_quote.dart';
import 'package:bagyesrushappusernew/src/parcel/model/parcel_stop.dart';
import 'package:bagyesrushappusernew/src/parcel/model/rider_model.dart';
import 'package:bagyesrushappusernew/src/parcel/repository/parcel_repository.dart';

/// Sentinel used by [SendParcelState.copyWith] to distinguish "leave
/// unchanged" from "explicitly set to null" for nullable fields.
const _unset = Object();

ParcelQuote? _quoteForRider(List<ParcelQuote> quotes, String? riderId) {
  if (riderId == null) return null;
  for (final quote in quotes) {
    if (quote.rider?.id == riderId) return quote;
  }
  return null;
}

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
  /// Fixed for the lifetime of the wizard — chosen on the entry sheet.
  final ParcelDirection direction;
  final ParcelStep currentStep;
  final String? packageType; // 'document' | 'parcel'
  final List<File> packageImages;
  final List<String> imageBase64List;
  final String weightText;
  final LatLng? pickupLatLng;
  final String pickupAddress;

  /// Receive only: the person the rider collects from (`pickup_contact_*`).
  final String senderName;
  final String senderPhone;
  final String pickupInstructions;

  /// One or more delivery destinations. Always has at least one entry.
  /// Send allows up to [SendParcelViewModel.maxStops]; receive exactly one.
  final List<DeliveryStop> deliveryStops;

  /// Total route distance: pickup → stop1 → stop2 → … → stopN (km).
  final double distanceKm;

  /// Whether the package contains fragile items — shown to the rider.
  /// Matches the booking-level toggle used by Lalamove and GrabExpress.
  final bool fragile;

  /// Backend size category (e.g. 'small', 'medium', 'large',
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

  /// Why "Continue" from the delivery step did not open the rider list: the
  /// server's own message (an unserviceable address, a bad field, no riders,
  /// no connection). The customer stays on that step until it's fixed.
  final String? quoteBlockedMessage;

  /// One quote per available rider, each priced from that rider's position.
  final List<ParcelQuote> riderQuotes;

  /// Rider id of the quote the customer picked. Keyed by rider rather than
  /// quote id because every re-fetch issues fresh quote ids.
  final String? selectedRiderId;

  // ── Payment + submission ────────────────────────────────────────────────

  /// Pay from wallet first; any remainder is paid through Paystack.
  final bool useWallet;

  /// Last known wallet balance, synced from `CustomerWalletViewmodel`.
  final double walletBalance;
  final bool isSubmitting;
  final String? submitError;
  final Parcel? createdParcel;

  const SendParcelState({
    this.direction = ParcelDirection.send,
    this.currentStep = ParcelStep.packageType,
    this.packageType,
    this.packageImages = const [],
    this.imageBase64List = const [],
    this.weightText = '',
    this.pickupLatLng,
    this.pickupAddress = '',
    this.senderName = '',
    this.senderPhone = '',
    this.pickupInstructions = '',
    this.deliveryStops = const [DeliveryStop(id: 'stop_0')],
    this.distanceKm = 0.0,
    this.fragile = false,
    this.packageSize = '',
    this.isFetchingQuote = false,
    this.quoteError,
    this.noRidersMessage,
    this.quoteBlockedMessage,
    this.riderQuotes = const [],
    this.selectedRiderId,
    this.useWallet = false,
    this.walletBalance = 0,
    this.isSubmitting = false,
    this.submitError,
    this.createdParcel,
  });

  /// Receive drop-off defaults to the already-cached location, so the
  /// customer usually only has to confirm it ([SendParcelViewModel] fetches
  /// one when none is cached).
  factory SendParcelState.initial(ParcelDirection direction) {
    if (!direction.isReceive) return const SendParcelState();
    final cached = LocationHelper.cachedResult;
    final position = cached?.position;
    final stop = cached != null && cached.isSuccess && position != null
        ? DeliveryStop(
            id: 'stop_0',
            latLng: LatLng(position.latitude, position.longitude),
            address: cached.address,
          )
        : const DeliveryStop(id: 'stop_0');
    return SendParcelState(direction: direction, deliveryStops: [stop]);
  }

  // ── Computed ───────────────────────────────────────────────────────────────

  ParcelQuote? get selectedQuote =>
      _quoteForRider(riderQuotes, selectedRiderId);

  RiderModel? get assignedRider => selectedQuote?.rider;
  double? get quotedPrice => selectedQuote?.price;
  double? get quotedDeliveryFee => selectedQuote?.deliveryFee;
  double? get quotedServiceFee => selectedQuote?.serviceFee;
  String? get quoteCurrency => selectedQuote?.currency;
  int? get quotedEtaMinutes => selectedQuote?.etaMinutes;

  WalletSplit get walletSplit => WalletSplit.from(
        balance: walletBalance,
        total: quotedPrice,
        useWallet: useWallet,
      );

  /// Wallet balance left once this booking's wallet share is deducted.
  double get walletBalanceAfter =>
      (WalletSplit.toMinorUnits(walletBalance) -
          WalletSplit.toMinorUnits(walletSplit.walletAmount)) /
      100;

  bool get hasValidSenderContact =>
      senderName.trim().isNotEmpty && PhoneUtils.isValidGhanaPhone(senderPhone);

  bool get _stopsComplete =>
      deliveryStops.isNotEmpty &&
      (!direction.isReceive || deliveryStops.length == 1) &&
      deliveryStops.every((s) => s.isCompleteFor(direction));

  bool get canProceed {
    switch (currentStep) {
      case ParcelStep.packageType:
        return packageType != null;
      case ParcelStep.packageDetails:
        return weightText.isNotEmpty;
      case ParcelStep.pickupLocation:
        final hasPickup = pickupLatLng != null && pickupAddress.isNotEmpty;
        return direction.isReceive
            ? hasPickup && hasValidSenderContact
            : hasPickup;
      case ParcelStep.deliveryLocation:
        // The quote check runs on Continue; don't allow a second one.
        return _stopsComplete && !isFetchingQuote;
      case ParcelStep.availableRiders:
        return !isFetchingQuote && assignedRider != null;
      case ParcelStep.summary:
        // Never book a price the customer hasn't seen.
        return !isSubmitting &&
            !isFetchingQuote &&
            quotedPrice != null;
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
    String? senderName,
    String? senderPhone,
    String? pickupInstructions,
    List<DeliveryStop>? deliveryStops,
    double? distanceKm,
    bool? fragile,
    String? packageSize,
    bool? isFetchingQuote,
    Object? quoteError = _unset,
    Object? noRidersMessage = _unset,
    Object? quoteBlockedMessage = _unset,
    List<ParcelQuote>? riderQuotes,
    Object? selectedRiderId = _unset,
    bool? useWallet,
    double? walletBalance,
    bool? isSubmitting,
    Object? submitError = _unset,
    Object? createdParcel = _unset,
  }) =>
      SendParcelState(
        direction: direction,
        currentStep: currentStep ?? this.currentStep,
        packageType: packageType ?? this.packageType,
        packageImages: packageImages ?? this.packageImages,
        imageBase64List: imageBase64List ?? this.imageBase64List,
        weightText: weightText ?? this.weightText,
        pickupLatLng: pickupLatLng ?? this.pickupLatLng,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        senderName: senderName ?? this.senderName,
        senderPhone: senderPhone ?? this.senderPhone,
        pickupInstructions: pickupInstructions ?? this.pickupInstructions,
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
        quoteBlockedMessage: identical(quoteBlockedMessage, _unset)
            ? this.quoteBlockedMessage
            : quoteBlockedMessage as String?,
        riderQuotes: riderQuotes ?? this.riderQuotes,
        selectedRiderId: identical(selectedRiderId, _unset)
            ? this.selectedRiderId
            : selectedRiderId as String?,
        useWallet: useWallet ?? this.useWallet,
        walletBalance: walletBalance ?? this.walletBalance,
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
  SendParcelViewModel(
    this._repository, {
    ParcelDirection direction = ParcelDirection.send,
  }) : super(SendParcelState.initial(direction)) {
    if (direction.isReceive && !state.deliveryStops.first.hasLocation) {
      unawaited(_prefillDropOff());
    }
  }

  /// Receive drop-off defaults to where the customer is — acquired now when
  /// no fix was cached yet. Skipped if they've already picked a stop.
  Future<void> _prefillDropOff() async {
    final result = await LocationHelper.current();
    final position = result.position;
    if (isDisposed || !result.isSuccess || position == null) return;
    final stops = state.deliveryStops;
    if (stops.length != 1 || stops.first.hasLocation) return;
    updateDeliveryStop(
      stops.first.id,
      LatLng(position.latitude, position.longitude),
      result.address,
    );
  }

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

  Future<void> advance() async {
    if (!state.canProceed) return;
    final steps = ParcelStep.values;
    final from = state.currentStep;
    final next = from.index + 1;
    if (next >= steps.length) return;

    final nextStep = steps[next];

    // The rider list opens only once the backend has quoted the trip: its
    // own refusal (unserviceable address, invalid field, no riders…) is
    // shown on the step the customer can fix, not behind a rider screen
    // they can't act on.
    if (nextStep == ParcelStep.availableRiders) {
      emit(state.copyWith(
        distanceKm: _calculateTotalRouteDistance(),
        quoteBlockedMessage: null,
      ));
      final problem = await fetchQuote();
      // They went back while the quote was loading — leave them where they are.
      if (state.currentStep != from) return;
      if (problem != null) {
        emit(state.copyWith(quoteBlockedMessage: problem));
        return;
      }
      emit(state.copyWith(currentStep: nextStep));
      return;
    }

    // When entering the summary step, re-fetch so the selected rider's
    // price and ETA are fresh right before paying.
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
    emit(state.copyWith(
      currentStep: ParcelStep.values[prev],
      quoteBlockedMessage: null,
    ));
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

  // ── Sender contact (receive) ──────────────────────────────────────────────

  void setSenderContact({required String name, required String phone}) =>
      emit(state.copyWith(senderName: name, senderPhone: phone));

  void setPickupInstructions(String instructions) =>
      emit(state.copyWith(pickupInstructions: instructions));

  // ── Delivery stops ────────────────────────────────────────────────────────

  /// Updates the location of an existing stop identified by [id].
  void updateDeliveryStop(String id, LatLng latLng, String address) {
    final stops = state.deliveryStops
        .map((s) => s.id == id ? s.copyWith(latLng: latLng, address: address) : s)
        .toList();
    emit(state.copyWith(deliveryStops: stops, quoteBlockedMessage: null));
  }

  /// Appends a blank stop. No-op when [maxStops] is already reached OR
  /// when the current last stop is not yet complete (prevents orphaned stops).
  void addDeliveryStop() {
    if (state.direction.isReceive) return;
    if (state.deliveryStops.length >= maxStops) return;
    if (state.deliveryStops.isNotEmpty && !state.deliveryStops.last.isComplete) {
      return;
    }
    final newId = 'stop_${_stopCounter++}';
    final stops = [...state.deliveryStops, DeliveryStop(id: newId)];
    emit(state.copyWith(deliveryStops: stops, quoteBlockedMessage: null));
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
    emit(state.copyWith(deliveryStops: stops, quoteBlockedMessage: null));
  }

  /// Removes the stop with [id]. No-op when only one stop remains.
  void removeDeliveryStop(String id) {
    if (state.deliveryStops.length <= 1) return;
    final stops = state.deliveryStops.where((s) => s.id != id).toList();
    emit(state.copyWith(deliveryStops: stops, quoteBlockedMessage: null));
  }

  // ── Payment ───────────────────────────────────────────────────────────────

  void setUseWallet(bool value) =>
      emit(state.copyWith(useWallet: value, submitError: null));

  void syncWalletBalance(double balance) {
    if (balance == state.walletBalance) return;
    emit(state.copyWith(walletBalance: balance));
  }

  // ── Backend quote ────────────────────────────────────────────────────────

  /// Fetches one quote per available rider. [submitParcel] books the
  /// selected one while it's valid and re-quotes only once it has expired.
  ///
  /// Returns null when at least one rider was quoted, otherwise the message
  /// explaining why not — the server's own words when it refused.
  Future<String?> fetchQuote() async {
    if (state.pickupLatLng == null || state.deliveryStops.isEmpty) {
      return 'Choose a pickup and delivery location first.';
    }

    emit(state.copyWith(
      isFetchingQuote: true,
      quoteError: null,
      noRidersMessage: null,
    ));

    final result = await _repository.getParcelQuotes(
      pickupAddress: state.pickupAddress,
      pickupLatitude: state.pickupLatLng!.latitude,
      pickupLongitude: state.pickupLatLng!.longitude,
      stops: _quoteStops(),
    );

    return result.fold(
      // A connectivity failure (timeout/no internet) never reached the
      // backend, so it's a true error state. Anything else is the server
      // responding that it couldn't match a rider — a normal "try again
      // shortly" outcome, not something to alarm the user about.
      (failure) {
        emit(state.copyWith(
          isFetchingQuote: false,
          quoteError: failure.isConnectivityFailure ? failure.message : null,
          noRidersMessage: failure.isConnectivityFailure ? null : failure.message,
          riderQuotes: const [],
          selectedRiderId: null,
        ));
        return failure.message;
      },
      (quotes) {
        emit(state.copyWith(
          isFetchingQuote: false,
          noRidersMessage: quotes.isEmpty ? _noRidersFallback : null,
          riderQuotes: quotes,
          selectedRiderId: _resolveSelection(quotes),
        ));
        return quotes.isEmpty ? _noRidersBlocked : null;
      },
    );
  }

  void selectRider(String riderId) {
    if (riderId == state.selectedRiderId) return;
    emit(state.copyWith(selectedRiderId: riderId));
  }

  static const _noRidersFallback = 'Please try again in a moment.';
  static const _noRidersBlocked =
      'No riders are available for this route right now. Please try again in a moment.';

  /// Keeps the customer's pick when that rider is still available,
  /// otherwise defaults to the first quote the backend returned.
  String? _resolveSelection(List<ParcelQuote> quotes) {
    final current = state.selectedRiderId;
    if (_quoteForRider(quotes, current) != null) return current;
    return quotes.isEmpty ? null : quotes.first.rider?.id;
  }

  // ── Submission ───────────────────────────────────────────────────────────

  /// Uploads any tagged photos, then creates the parcel against the quote
  /// the customer reviewed (see [_quoteToBook]) — so the total and wallet
  /// split on the summary are exactly what gets charged. The price itself
  /// always comes from the backend, never from a client-side estimate.
  Future<bool> submitParcel() async {
    // Already booked (payment is what's left): never create a second parcel.
    if (state.createdParcel != null) return true;
    if (state.pickupLatLng == null || !state._stopsComplete) return false;
    if (state.direction.isReceive && !state.hasValidSenderContact) return false;
    final riderId = state.selectedRiderId;
    if (riderId == null) {
      emit(state.copyWith(submitError: 'Please select a rider.'));
      return false;
    }
    emit(state.copyWith(isSubmitting: true, submitError: null));

    try {
      final quote = await _quoteToBook(riderId);
      if (quote == null) return false;

      final stops = await _buildStopsWithPhotos();
      // Re-derived from the quote actually being booked (it may be a fresh,
      // equal-or-cheaper one) so the wallet flag matches what's charged.
      final split = WalletSplit.from(
        balance: state.walletBalance,
        total: quote.price,
        useWallet: state.useWallet,
      );

      final createResult = await _repository.createParcel(
        deliveryQuoteId: quote.id,
        // Paystack's page is where the customer picks how to pay (no saved
        // method id is sent); the backend enum is `card` | `mobile_money`.
        paymentMethod: 'mobile_money',
        useWallet: split.usesWallet,
        direction: state.direction,
        stops: stops,
        pickupAddress: state.pickupAddress,
        pickupContactName: _nonEmpty(state.senderName),
        pickupContactPhone: _nonEmpty(state.senderPhone),
        pickupInstructions: _nonEmpty(state.pickupInstructions),
      );

      return createResult.fold<bool>(
        (failure) {
          emit(state.copyWith(isSubmitting: false, submitError: failure.message));
          // A rejected quote (e.g. it just expired) shouldn't be retried
          // as-is — refresh so the next attempt books a live price.
          fetchQuote();
          return false;
        },
        (parcel) {
          emit(state.copyWith(isSubmitting: false, createdParcel: parcel));
          return true;
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

  /// The quote to book for [riderId]: the one on screen while it's still
  /// valid, so the reviewed total is what's charged. An expired quote is
  /// replaced by a fresh one for the same rider — but if that rider has
  /// gone, or the fresh price is higher, nothing is booked: the new quotes
  /// are shown (updating the total and wallet split) and the customer
  /// confirms again. Returns null in those cases.
  Future<ParcelQuote?> _quoteToBook(String riderId) async {
    final shown = state.selectedQuote;
    if (shown != null && shown.isBookableAt(DateTime.now())) return shown;

    final result = await _repository.getParcelQuotes(
      pickupAddress: state.pickupAddress,
      pickupLatitude: state.pickupLatLng!.latitude,
      pickupLongitude: state.pickupLatLng!.longitude,
      stops: _quoteStops(),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, submitError: failure.message));
        return null;
      },
      (quotes) {
        final fresh = _quoteForRider(quotes, riderId);
        if (fresh == null) {
          emit(state.copyWith(
            isSubmitting: false,
            riderQuotes: quotes,
            selectedRiderId: _resolveSelection(quotes),
            submitError: quotes.isEmpty
                ? 'No riders are available right now. Please try again.'
                : 'Your selected rider is no longer available. '
                    'Please review the updated rider and price.',
          ));
          return null;
        }
        if (shown != null &&
            WalletSplit.toMinorUnits(fresh.price) >
                WalletSplit.toMinorUnits(shown.price)) {
          emit(state.copyWith(
            isSubmitting: false,
            riderQuotes: quotes,
            submitError: 'The delivery price has gone up to '
                '${formatMoney(fresh.price, currency: fresh.currency)}. '
                'Review the new total and confirm again.',
          ));
          return null;
        }
        return fresh;
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

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
