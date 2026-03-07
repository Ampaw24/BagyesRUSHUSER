import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_profile.dart';
import '../repository/vendor_dashboard_repository.dart';

enum ShopProfileStatus { initial, loading, loaded, saving, deleting, error }

class ShopProfileState extends Equatable {
  final ShopProfileStatus status;
  final VendorProfile? profile;
  final String? errorMessage;
  final String? successMessage;

  const ShopProfileState({
    this.status = ShopProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.successMessage,
  });

  ShopProfileState copyWith({
    ShopProfileStatus? status,
    VendorProfile? profile,
    String? errorMessage,
    String? successMessage,
  }) {
    return ShopProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, successMessage];
}

class ShopProfileViewModel extends ViewModel<ShopProfileState> {
  final VendorDashboardRepository _repository;

  ShopProfileViewModel(this._repository) : super(const ShopProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ShopProfileStatus.loading));

    final result = await _repository.fetchVendorProfile();
    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: ShopProfileStatus.loaded,
        profile: profile,
      )),
    );
  }

  /// Use dummy data for UI development
  void loadDummy() {
    emit(state.copyWith(
      status: ShopProfileStatus.loaded,
      profile: VendorProfile.dummy,
    ));
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    emit(state.copyWith(status: ShopProfileStatus.saving));

    final result = await _repository.updateVendorProfile(data);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ShopProfileStatus.error,
        errorMessage: failure.message,
      )),
      (profile) => emit(state.copyWith(
        status: ShopProfileStatus.loaded,
        profile: profile,
        successMessage: 'Profile updated successfully',
      )),
    );
  }

  Future<bool> deleteAccount() async {
    emit(state.copyWith(status: ShopProfileStatus.deleting));

    final result = await _repository.deleteVendorAccount();
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: ShopProfileStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) => true,
    );
  }

  void clearMessages() {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
    ));
  }
}
