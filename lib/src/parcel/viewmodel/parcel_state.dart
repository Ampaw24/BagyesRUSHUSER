import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../model/parcel.dart';
import '../model/parcel_photo.dart';
import '../model/parcel_quote.dart';

sealed class ParcelState extends Equatable {
  const ParcelState();
  @override
  List<Object?> get props => [];
}

final class ParcelInitial extends ParcelState {
  const ParcelInitial();
}

final class ParcelLoading extends ParcelState {
  const ParcelLoading();
}

final class ParcelsLoaded extends ParcelState {
  const ParcelsLoaded(this.parcels);
  final List<Parcel> parcels;

  @override
  List<Object?> get props => [parcels];
}

final class ParcelDetailsLoaded extends ParcelState {
  const ParcelDetailsLoaded(this.parcel);
  final Parcel parcel;

  @override
  List<Object?> get props => [parcel];
}

final class ParcelQuoteLoaded extends ParcelState {
  const ParcelQuoteLoaded(this.quote);
  final ParcelQuote quote;

  @override
  List<Object?> get props => [quote];
}

final class ParcelCreated extends ParcelState {
  const ParcelCreated(this.parcel);
  final Parcel parcel;

  @override
  List<Object?> get props => [parcel];
}

final class ParcelCancelled extends ParcelState {
  const ParcelCancelled(this.parcel);
  final Parcel parcel;

  @override
  List<Object?> get props => [parcel];
}

final class ParcelPhotoUploaded extends ParcelState {
  const ParcelPhotoUploaded(this.photo);
  final ParcelPhoto photo;

  @override
  List<Object?> get props => [photo];
}

final class ParcelPhotoDeleted extends ParcelState {
  const ParcelPhotoDeleted(this.photoId);
  final String photoId;

  @override
  List<Object?> get props => [photoId];
}

final class ParcelError extends ParcelState {
  const ParcelError({required this.message, required this.title});

  ParcelError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
