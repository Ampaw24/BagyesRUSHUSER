import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_profile.dart';
import '../repository/vendor_dashboard_repository.dart';

enum SettingsStatus { initial, loading, loaded, saving, uploadingDocument, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final VendorProfile? profile;
  final String? errorMessage;
  final String? uploadingDocumentType;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.profile,
    this.errorMessage,
    this.uploadingDocumentType,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    VendorProfile? profile,
    String? errorMessage,
    String? uploadingDocumentType,
  }) {
    return SettingsState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      uploadingDocumentType: uploadingDocumentType,
    );
  }

  @override
  List<Object?> get props =>
      [status, profile, errorMessage, uploadingDocumentType];
}

class SettingsViewModel extends ViewModel<SettingsState> {
  final VendorDashboardRepository _repository;

  SettingsViewModel(this._repository) : super(const SettingsState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: SettingsStatus.loading));

    final result = await _repository.fetchVendorProfile();
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        profile: profile,
      )),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    emit(state.copyWith(status: SettingsStatus.saving));

    final result = await _repository.updateVendorProfile(data);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        profile: profile,
      )),
    );
  }

  /// Uploads a single vendor document (`logo`, `owner_id`,
  /// `business_registration_certificate`, `food_safety_license`, etc.) and
  /// refreshes [SettingsState.profile] with the server's response.
  Future<bool> uploadDocument(String type, String filePath) async {
    emit(state.copyWith(
      status: SettingsStatus.uploadingDocument,
      uploadingDocumentType: type,
    ));

    final result = await _repository.uploadVendorDocument(type, filePath);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          uploadingDocumentType: null,
        ));
        return false;
      },
      (profile) {
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          profile: profile,
          uploadingDocumentType: null,
        ));
        return true;
      },
    );
  }
}
