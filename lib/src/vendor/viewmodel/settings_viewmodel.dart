import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_profile.dart';
import '../repository/vendor_dashboard_repository.dart';

enum SettingsStatus { initial, loading, loaded, saving, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final VendorProfile? profile;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.profile,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    VendorProfile? profile,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
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
}
