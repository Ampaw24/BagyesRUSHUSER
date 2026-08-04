import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../../vendor_registration/repositories/vendor_repository.dart';
import '../repository/vendor_dashboard_repository.dart';
import '../../../core/common/app/current_user_provider.dart';

enum VendorKycStatus { initial, loading, uploading, saving, success, error }

class VendorKycState extends Equatable {
  final VendorKycStatus status;
  final String tinNumber;
  final String idNumber;
  final String idType;
  final String? businessCertPath;
  final String? foodSafetyLicensePath;
  final String? ownerIdPath;
  final String? selfiePath;
  final String? businessCertUrl;
  final String? foodSafetyLicenseUrl;
  final String? ownerIdUrl;
  final String? selfieUrl;
  final String? errorMessage;
  final String? uploadProgressMessage;

  const VendorKycState({
    this.status = VendorKycStatus.initial,
    this.tinNumber = '',
    this.idNumber = '',
    this.idType = 'Ghana Card',
    this.businessCertPath,
    this.foodSafetyLicensePath,
    this.ownerIdPath,
    this.selfiePath,
    this.businessCertUrl,
    this.foodSafetyLicenseUrl,
    this.ownerIdUrl,
    this.selfieUrl,
    this.errorMessage,
    this.uploadProgressMessage,
  });

  VendorKycState copyWith({
    VendorKycStatus? status,
    String? tinNumber,
    String? idNumber,
    String? idType,
    String? businessCertPath,
    String? foodSafetyLicensePath,
    String? ownerIdPath,
    String? selfiePath,
    String? businessCertUrl,
    String? foodSafetyLicenseUrl,
    String? ownerIdUrl,
    String? selfieUrl,
    String? errorMessage,
    String? uploadProgressMessage,
  }) {
    return VendorKycState(
      status: status ?? this.status,
      tinNumber: tinNumber ?? this.tinNumber,
      idNumber: idNumber ?? this.idNumber,
      idType: idType ?? this.idType,
      businessCertPath: businessCertPath ?? this.businessCertPath,
      foodSafetyLicensePath: foodSafetyLicensePath ?? this.foodSafetyLicensePath,
      ownerIdPath: ownerIdPath ?? this.ownerIdPath,
      selfiePath: selfiePath ?? this.selfiePath,
      businessCertUrl: businessCertUrl ?? this.businessCertUrl,
      foodSafetyLicenseUrl: foodSafetyLicenseUrl ?? this.foodSafetyLicenseUrl,
      ownerIdUrl: ownerIdUrl ?? this.ownerIdUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      errorMessage: errorMessage,
      uploadProgressMessage: uploadProgressMessage ?? this.uploadProgressMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tinNumber,
        idNumber,
        idType,
        businessCertPath,
        foodSafetyLicensePath,
        ownerIdPath,
        selfiePath,
        businessCertUrl,
        foodSafetyLicenseUrl,
        ownerIdUrl,
        selfieUrl,
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

  void setTinNumber(String val) => emit(state.copyWith(tinNumber: val));
  void setIdNumber(String val) => emit(state.copyWith(idNumber: val));
  void setIdType(String val) => emit(state.copyWith(idType: val));

  void setBusinessCertPath(String? path) => emit(state.copyWith(businessCertPath: path));
  void setFoodSafetyLicensePath(String? path) => emit(state.copyWith(foodSafetyLicensePath: path));
  void setOwnerIdPath(String? path) => emit(state.copyWith(ownerIdPath: path));
  void setSelfiePath(String? path) => emit(state.copyWith(selfiePath: path));

  void clearError() => emit(state.copyWith(errorMessage: null));

  Future<bool> submitKyc() async {
    if (state.tinNumber.trim().isEmpty) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Tax ID (TIN) is required'));
      return false;
    }
    if (state.idNumber.trim().isEmpty) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'ID card number is required'));
      return false;
    }
    if (state.ownerIdPath == null) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Owner/Manager ID card image is required'));
      return false;
    }
    if (state.selfiePath == null) {
      emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Vendor manager selfie/profile image is required'));
      return false;
    }

    emit(state.copyWith(
      status: VendorKycStatus.uploading,
      uploadProgressMessage: 'Uploading Manager ID card...',
    ));

    // Upload Owner ID
    String ownerIdUrl = '';
    final ownerIdRes = await _registrationRepository.uploadDocument(state.ownerIdPath!, 'owner_id');
    bool uploadSuccess = ownerIdRes.fold(
      (failure) {
        emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'ID Upload Failed: ${failure.message}'));
        return false;
      },
      (url) {
        ownerIdUrl = url;
        return true;
      },
    );
    if (!uploadSuccess) return false;

    // Upload Selfie
    emit(state.copyWith(
      status: VendorKycStatus.uploading,
      uploadProgressMessage: 'Uploading Manager Selfie...',
    ));
    String selfieUrl = '';
    final selfieRes = await _registrationRepository.uploadDocument(state.selfiePath!, 'selfie');
    uploadSuccess = selfieRes.fold(
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

    // Upload Business Registration Certificate (optional)
    String businessCertUrl = '';
    if (state.businessCertPath != null) {
      emit(state.copyWith(
        status: VendorKycStatus.uploading,
        uploadProgressMessage: 'Uploading Business Certificate...',
      ));
      final certRes = await _registrationRepository.uploadDocument(state.businessCertPath!, 'business_registration');
      uploadSuccess = certRes.fold(
        (failure) {
          emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Certificate Upload Failed: ${failure.message}'));
          return false;
        },
        (url) {
          businessCertUrl = url;
          return true;
        },
      );
      if (!uploadSuccess) return false;
    }

    // Upload Food Safety License (optional)
    String foodSafetyLicenseUrl = '';
    if (state.foodSafetyLicensePath != null) {
      emit(state.copyWith(
        status: VendorKycStatus.uploading,
        uploadProgressMessage: 'Uploading Vending Permit...',
      ));
      final permitRes = await _registrationRepository.uploadDocument(state.foodSafetyLicensePath!, 'food_safety_license');
      uploadSuccess = permitRes.fold(
        (failure) {
          emit(state.copyWith(status: VendorKycStatus.error, errorMessage: 'Vending Permit Upload Failed: ${failure.message}'));
          return false;
        },
        (url) {
          foodSafetyLicenseUrl = url;
          return true;
        },
      );
      if (!uploadSuccess) return false;
    }

    emit(state.copyWith(
      status: VendorKycStatus.saving,
      uploadProgressMessage: 'Saving KYC details...',
    ));

    // Save details to Vendor Profile
    final updatePayload = {
      'tax_identification_number': state.tinNumber,
      'is_profile_complete': true,
      'status': 'pending_review',
      'owner_id_url': ownerIdUrl,
      'selfie_url': selfieUrl,
      if (businessCertUrl.isNotEmpty) 'business_registration_cert_url': businessCertUrl,
      if (foodSafetyLicenseUrl.isNotEmpty) 'food_safety_license_url': foodSafetyLicenseUrl,
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
        final currentUser = _currentUserProvider.user;
        if (currentUser != null) {
          _currentUserProvider.setUser(currentUser.copyWith(profile: profile));
        }
        emit(state.copyWith(
          status: VendorKycStatus.success,
          businessCertUrl: businessCertUrl,
          foodSafetyLicenseUrl: foodSafetyLicenseUrl,
          ownerIdUrl: ownerIdUrl,
          selfieUrl: selfieUrl,
        ));
        return true;
      },
    );
  }

  void reset() {
    emit(const VendorKycState());
  }
}
