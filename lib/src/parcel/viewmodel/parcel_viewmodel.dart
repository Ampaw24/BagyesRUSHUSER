import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../model/parcel.dart';
import '../model/parcel_photo.dart';
import '../model/parcel_quote.dart';
import '../model/parcel_stop.dart';
import '../repository/parcel_repository.dart';
import 'parcel_state.dart';

class ParcelViewModel extends ViewModel<ParcelState> {
  ParcelViewModel({required ParcelRepository repository})
      : _repository = repository,
        super(const ParcelInitial());

  final ParcelRepository _repository;

  Future<void> getParcels() async {
    appLogger.d('ParcelViewModel.getParcels → initiated');
    emit(const ParcelLoading());

    final result = await _repository.getParcels();

    result.fold(
      (failure) {
        appLogger.w('ParcelViewModel.getParcels → error: ${failure.message}');
        emit(ParcelError.fromFailure(failure));
      },
      (parcels) {
        appLogger.i(
          'ParcelViewModel.getParcels → loaded ${parcels.length} parcels',
        );
        emit(ParcelsLoaded(parcels));
      },
    );
  }

  Future<void> getParcelById(String id) async {
    appLogger.d('ParcelViewModel.getParcelById → id=$id');
    emit(const ParcelLoading());

    final result = await _repository.getParcelById(id: id);

    result.fold(
      (failure) {
        appLogger.w(
          'ParcelViewModel.getParcelById → error: ${failure.message}',
        );
        emit(ParcelError.fromFailure(failure));
      },
      (parcel) {
        appLogger.i('ParcelViewModel.getParcelById → success');
        emit(ParcelDetailsLoaded(parcel));
      },
    );
  }

  Future<Parcel?> createParcel({
    required int deliveryQuoteId,
    required String paymentMethod,
    int? paymentMethodId,
    required List<ParcelStop> stops,
    required String pickupAddress,
    String? pickupContactName,
    String? pickupContactPhone,
    String? pickupInstructions,
  }) async {
    appLogger.d('ParcelViewModel.createParcel → initiated');
    emit(const ParcelLoading());

    final result = await _repository.createParcel(
      deliveryQuoteId: deliveryQuoteId,
      paymentMethod: paymentMethod,
      paymentMethodId: paymentMethodId,
      stops: stops,
      pickupAddress: pickupAddress,
      pickupContactName: pickupContactName,
      pickupContactPhone: pickupContactPhone,
      pickupInstructions: pickupInstructions,
    );

    return result.fold(
      (failure) {
        appLogger.w(
          'ParcelViewModel.createParcel → error: ${failure.message}',
        );
        emit(ParcelError.fromFailure(failure));
        return null;
      },
      (parcel) {
        appLogger.i(
          'ParcelViewModel.createParcel → success, id=${parcel.id}',
        );
        emit(ParcelCreated(parcel));
        return parcel;
      },
    );
  }

  Future<bool> cancelParcel({required String id, required String reason}) async {
    appLogger.d('ParcelViewModel.cancelParcel → id=$id');
    emit(const ParcelLoading());

    final result = await _repository.cancelParcel(id: id, reason: reason);

    return result.fold(
      (failure) {
        appLogger.w(
          'ParcelViewModel.cancelParcel → error: ${failure.message}',
        );
        emit(ParcelError.fromFailure(failure));
        return false;
      },
      (parcel) {
        appLogger.i('ParcelViewModel.cancelParcel → success, id=$id');
        emit(ParcelCancelled(parcel));
        return true;
      },
    );
  }

  Future<ParcelQuote?> getQuote({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required List<ParcelStop> stops,
  }) async {
    appLogger.d('ParcelViewModel.getQuote → initiated');
    emit(const ParcelLoading());

    final result = await _repository.getParcelQuote(
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      stops: stops,
    );

    return result.fold(
      (failure) {
        appLogger.w('ParcelViewModel.getQuote → error: ${failure.message}');
        emit(ParcelError.fromFailure(failure));
        return null;
      },
      (quote) {
        appLogger.i('ParcelViewModel.getQuote → success, id=${quote.id}');
        emit(ParcelQuoteLoaded(quote));
        return quote;
      },
    );
  }

  Future<ParcelPhoto?> uploadPhoto(String filePath) async {
    appLogger.d('ParcelViewModel.uploadPhoto → initiated');
    emit(const ParcelLoading());

    final result = await _repository.uploadParcelPhoto(filePath: filePath);

    return result.fold(
      (failure) {
        appLogger.w(
          'ParcelViewModel.uploadPhoto → error: ${failure.message}',
        );
        emit(ParcelError.fromFailure(failure));
        return null;
      },
      (photo) {
        appLogger.i(
          'ParcelViewModel.uploadPhoto → success, id=${photo.id}',
        );
        emit(ParcelPhotoUploaded(photo));
        return photo;
      },
    );
  }

  Future<bool> deletePhoto(String photoId) async {
    appLogger.d('ParcelViewModel.deletePhoto → id=$photoId');
    emit(const ParcelLoading());

    final result = await _repository.deleteParcelPhoto(photoId: photoId);

    return result.fold(
      (failure) {
        appLogger.w(
          'ParcelViewModel.deletePhoto → error: ${failure.message}',
        );
        emit(ParcelError.fromFailure(failure));
        return false;
      },
      (_) {
        appLogger.i('ParcelViewModel.deletePhoto → success, id=$photoId');
        emit(ParcelPhotoDeleted(photoId));
        return true;
      },
    );
  }
}
