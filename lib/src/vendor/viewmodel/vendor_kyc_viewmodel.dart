import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../../vendor_registration/repositories/vendor_repository.dart';
import '../model/vendor_profile.dart';
import '../repository/vendor_dashboard_repository.dart';
import '../../../core/common/app/current_user_provider.dart';

enum VendorKycStatus { initial, loading, uploading, saving, success, error }

const kAllOperatingDays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

class VendorKycState extends Equatable {
  final VendorKycStatus status;
  final String idNumber;
  final String idType;
  final String? businessCertPath;
  final String? foodSafetyLicensePath;
  final String? ownerIdFrontPath;
  final String? ownerIdBackPath;
  final String? selfiePath;
  final String? selfieUrl;

  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final int estimatedPrepTimeMinutes;
  final String? errorMessage;
  final String? uploadProgressMessage;

  const VendorKycState({
    this.status = VendorKycStatus.initial,
    this.idNumber = '',
    this.idType = 'Ghana Card',
    this.businessCertPath,
    this.foodSafetyLicensePath,
    this.ownerIdFrontPath,
    this.ownerIdBackPath,
    this.selfiePath,
    this.selfieUrl,
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.operatingDays = kAllOperatingDays,
    this.estimatedPrepTimeMinutes = 30,
    this.errorMessage,
    this.uploadProgressMessage,
  });

  VendorKycState copyWith({
    VendorKycStatus? status,
    String? idNumber,
    String? idType,
    String? businessCertPath,
    bool clearBusinessCertPath = false,
    String? foodSafetyLicensePath,
    bool clearFoodSafetyLicensePath = false,
    String? ownerIdFrontPath,
    bool clearOwnerIdFrontPath = false,
    String? ownerIdBackPath,
    bool clearOwnerIdBackPath = false,
    String? selfiePath,
    String? selfieUrl,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    int? estimatedPrepTimeMinutes,
    String? errorMessage,
    String? uploadProgressMessage,
  }) {
    return VendorKycState(
      status: status ?? this.status,
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      businessCertPath:
          clearBusinessCertPath ? null : (businessCertPath ?? this.businessCertPath),
      foodSafetyLicensePath: clearFoodSafetyLicensePath
          ? null
          : (foodSafetyLicensePath ?? this.foodSafetyLicensePath),
      ownerIdFrontPath:
          clearOwnerIdFrontPath ? null : (ownerIdFrontPath ?? this.ownerIdFrontPath),
      ownerIdBackPath:
          clearOwnerIdBackPath ? null : (ownerIdBackPath ?? this.ownerIdBackPath),
      selfiePath: selfiePath ?? this.selfiePath,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      estimatedPrepTimeMinutes: estimatedPrepTimeMinutes ?? this.estimatedPrepTimeMinutes,
      errorMessage: errorMessage,
      uploadProgressMessage: uploadProgressMessage ?? this.uploadProgressMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        idNumber,
        idType,
        businessCertPath,
        foodSafetyLicensePath,
        ownerIdFrontPath,
        ownerIdBackPath,
        selfiePath,
        selfieUrl,
        openingTime,
        closingTime,
        operatingDays,
        estimatedPrepTimeMinutes,
        errorMessage,
        uploadProgressMessage,
      ];
}

class VendorKycViewModel extends ViewModel<VendorKycState> {
  final VendorRepository _registrationRepository;
  final VendorDashboardRepository _dashboardRepository;
  final CurrentUserProvider _currentUserProvider;

  VendorKycViewModel({
    required VendorRepository registrationRepository,
    required VendorDashboardRepository dashboardRepository,
    required CurrentUserProvider currentUserProvider,
  })  : _registrationRepository = registrationRepository,
        _dashboardRepository = dashboardRepository,
        _currentUserProvider = currentUserProvider,
        super(const VendorKycState());

  void setIdNumber(String val) => emit(state.copyWith(idNumber: val));
  void setIdType(String val) => emit(state.copyWith(idType: val));

  void setBusinessCertPath(String? path) => emit(state.copyWith(
        businessCertPath: path,
        clearBusinessCertPath: path == null,
      ));
  void setFoodSafetyLicensePath(String? path) => emit(state.copyWith(
        foodSafetyLicensePath: path,
        clearFoodSafetyLicensePath: path == null,
      ));
  void setOwnerIdFrontPath(String? path) => emit(state.copyWith(
        ownerIdFrontPath: path,
        clearOwnerIdFrontPath: path == null,
      ));
  void setOwnerIdBackPath(String? path) => emit(state.copyWith(
        ownerIdBackPath: path,
        clearOwnerIdBackPath: path == null,
      ));
  void setSelfiePath(String? path) => emit(state.copyWith(selfiePath: path));

  void setOpeningTime(String time) => emit(state.copyWith(openingTime: time));
  void setClosingTime(String time) => emit(state.copyWith(closingTime: time));
  void setEstimatedPrepTimeMinutes(int minutes) =>
      emit(state.copyWith(estimatedPrepTimeMinutes: minutes));

  void toggleOperatingDay(String day) {
    final days = List<String>.from(state.operatingDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    emit(state.copyWith(operatingDays: days));
  }

  void clearError() => emit(state.copyWith(errorMessage: null));

  /// Submits operating hours, operating days, and estimated prep time via
  /// the dedicated operations-KYC endpoint. Called when the vendor advances
  /// past the store-details step — advancing to the documents step is
  /// gated on this succeeding.
  Future<bool> submitOperationalDetails() async {
    if (state.operatingDays.isEmpty) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Please select at least one operating day'));
      return false;
    }

    emit(state.copyWith(
      status: VendorKycStatus.saving,
      uploadProgressMessage: 'Saving operational details...',
    ));
    final result = await _dashboardRepository.submitOperationalKyc(
      openingTime: state.openingTime,
      closingTime: state.closingTime,
      operatingDays: state.operatingDays,
      estimatedPrepTimeMinutes: state.estimatedPrepTimeMinutes,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Failed to save operational details: ${failure.message}'));
        return false;
      },
      (profile) {
        _syncProfile(profile);
        emit(state.copyWith(status: VendorKycStatus.initial, errorMessage: null));
        return true;
      },
    );
  }

  /// Uploads a single vendor document immediately (the backend only accepts
  /// one document per request). Used by the documents step, where each
  /// document is confirmed and submitted individually rather than bundled
  /// into the final [submitKyc] call.
  Future<bool> uploadDocument({
    required String type,
    required String filePath,
    required String label,
  }) async {
    emit(state.copyWith(
      status: VendorKycStatus.uploading,
      uploadProgressMessage: 'Uploading $label...',
    ));
    final result = await _dashboardRepository.uploadVendorDocument(type, filePath);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: VendorKycStatus.error,
          errorMessage: '$label upload failed: ${failure.message}',
        ));
        return false;
      },
      (profile) {
        _syncProfile(profile);
        emit(state.copyWith(status: VendorKycStatus.initial, errorMessage: null));
        return true;
      },
    );
  }

  /// Submits the front and back of the owner/user ID card together as a
  /// single request, once both sides have been picked and confirmed. Called
  /// automatically as soon as the second side is confirmed — whichever side
  /// that is — since the combined upload can't fire until both are staged.
  Future<bool> uploadOwnerIdCard() async {
    final front = state.ownerIdFrontPath;
    final back = state.ownerIdBackPath;
    if (front == null || back == null) return false;

    emit(state.copyWith(
      status: VendorKycStatus.uploading,
      uploadProgressMessage: 'Uploading ID Card...',
    ));
    final result = await _dashboardRepository.uploadOwnerIdDocument(
      frontPath: front,
      backPath: back,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: VendorKycStatus.error,
          errorMessage: 'ID Card upload failed: ${failure.message}',
        ));
        return false;
      },
      (profile) {
        _syncProfile(profile);
        emit(state.copyWith(status: VendorKycStatus.initial, errorMessage: null));
        return true;
      },
    );
  }

  Future<bool> submitKyc() async {
    if (state.idNumber.trim().isEmpty) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'ID card number is required'));
      return false;
    }
    final profile = _currentUserProvider.user?.profile as VendorProfile?;
    if (!(profile?.documents.ownerId.uploaded ?? false)) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Your ID card (front and back) is required'));
      return false;
    }
    if (state.selfiePath == null) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Vendor manager selfie/profile image is required'));
      return false;
    }

    // Business registration certificate, food safety license, and the ID
    // card (front + back, sent together) are already uploaded via
    // `uploadDocument`/`uploadOwnerIdCard` as soon as the vendor confirms
    // them — nothing left to upload here except the selfie (not one of the
    // tracked vendor document types, so it stays on the registration-document
    // upload path) and the remaining fields.
    emit(state.copyWith(
      status: VendorKycStatus.uploading,
      uploadProgressMessage: 'Uploading Manager Selfie...',
    ));
    String selfieUrl = '';
    final selfieRes = await _registrationRepository.uploadDocument(state.selfiePath!, 'selfie');
    final uploadSuccess = selfieRes.fold(
      (failure) {
        emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Selfie Upload Failed: ${failure.message}'));
        return false;
      },
      (url) {
        selfieUrl = url;
        return true;
      },
    );
    if (!uploadSuccess) return false;

    emit(state.copyWith(
      status: VendorKycStatus.saving,
      uploadProgressMessage: 'Saving KYC details...',
    ));

    // Save the remaining non-document KYC fields. `is_profile_complete` and
    // `status` are no longer force-set here — the backend now derives them
    // from the documents just uploaded above plus payout setup.
    final updatePayload = {
      'id_number': state.idNumber,
      'id_type': state.idType,
      if (selfieUrl.isNotEmpty) 'logo_url': selfieUrl,
    };

    final profileRes = await _dashboardRepository.updateVendorProfile(updatePayload);
    return profileRes.fold(
      (failure) {
        emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Failed to save KYC: ${failure.message}'));
        return false;
      },
      (profile) {
        _syncProfile(profile);
        emit(state.copyWith(
          status: VendorKycStatus.success,
          selfieUrl: selfieUrl,
        ));
        return true;
      },
    );
  }

  void _syncProfile(VendorProfile profile) {
    final currentUser = _currentUserProvider.user;
    if (currentUser != null) {
      _currentUserProvider.setUser(currentUser.copyWith(profile: profile));
    }
  }

  void reset() {
    emit(const VendorKycState());
  }
}
