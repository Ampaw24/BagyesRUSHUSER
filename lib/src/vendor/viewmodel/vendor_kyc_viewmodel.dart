import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../../payment/model/payout_provider_model.dart';
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
  final String? businessCertPath;
  final String? foodSafetyLicensePath;

  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final int estimatedPrepTimeMinutes;
  final String? errorMessage;
  final String? uploadProgressMessage;

  // ── Payout (step 3) ──
  final PayoutProviderModel? selectedBank;
  final String bankAccountNumber;
  final String bankAccountName;
  final String branchCode;
  final PayoutProviderModel? selectedMomoProvider;
  final String momoNumber;

  const VendorKycState({
    this.status = VendorKycStatus.initial,
    this.businessCertPath,
    this.foodSafetyLicensePath,
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.operatingDays = kAllOperatingDays,
    this.estimatedPrepTimeMinutes = 30,
    this.errorMessage,
    this.uploadProgressMessage,
    this.selectedBank,
    this.bankAccountNumber = '',
    this.bankAccountName = '',
    this.branchCode = '',
    this.selectedMomoProvider,
    this.momoNumber = '',
  });

  VendorKycState copyWith({
    VendorKycStatus? status,
    String? businessCertPath,
    bool clearBusinessCertPath = false,
    String? foodSafetyLicensePath,
    bool clearFoodSafetyLicensePath = false,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    int? estimatedPrepTimeMinutes,
    String? errorMessage,
    String? uploadProgressMessage,
    PayoutProviderModel? selectedBank,
    bool clearSelectedBank = false,
    String? bankAccountNumber,
    String? bankAccountName,
    String? branchCode,
    PayoutProviderModel? selectedMomoProvider,
    bool clearSelectedMomoProvider = false,
    String? momoNumber,
  }) {
    return VendorKycState(
      status: status ?? this.status,
      businessCertPath:
          clearBusinessCertPath ? null : (businessCertPath ?? this.businessCertPath),
      foodSafetyLicensePath: clearFoodSafetyLicensePath
          ? null
          : (foodSafetyLicensePath ?? this.foodSafetyLicensePath),
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      estimatedPrepTimeMinutes: estimatedPrepTimeMinutes ?? this.estimatedPrepTimeMinutes,
      errorMessage: errorMessage,
      uploadProgressMessage: uploadProgressMessage ?? this.uploadProgressMessage,
      selectedBank: clearSelectedBank ? null : (selectedBank ?? this.selectedBank),
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      branchCode: branchCode ?? this.branchCode,
      selectedMomoProvider: clearSelectedMomoProvider
          ? null
          : (selectedMomoProvider ?? this.selectedMomoProvider),
      momoNumber: momoNumber ?? this.momoNumber,
    );
  }

  @override
  List<Object?> get props => [
        status,
        businessCertPath,
        foodSafetyLicensePath,
        openingTime,
        closingTime,
        operatingDays,
        estimatedPrepTimeMinutes,
        errorMessage,
        uploadProgressMessage,
        selectedBank,
        bankAccountNumber,
        bankAccountName,
        branchCode,
        selectedMomoProvider,
        momoNumber,
      ];
}

class VendorKycViewModel extends ViewModel<VendorKycState> {
  final VendorDashboardRepository _dashboardRepository;
  final CurrentUserProvider _currentUserProvider;

  VendorKycViewModel({
    required VendorDashboardRepository dashboardRepository,
    required CurrentUserProvider currentUserProvider,
  })  : _dashboardRepository = dashboardRepository,
        _currentUserProvider = currentUserProvider,
        super(const VendorKycState());

  void setBusinessCertPath(String? path) => emit(state.copyWith(
        businessCertPath: path,
        clearBusinessCertPath: path == null,
      ));
  void setFoodSafetyLicensePath(String? path) => emit(state.copyWith(
        foodSafetyLicensePath: path,
        clearFoodSafetyLicensePath: path == null,
      ));

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

  // ── Payout (step 3) ──

  void setSelectedBank(PayoutProviderModel? bank) => emit(state.copyWith(
        selectedBank: bank,
        clearSelectedBank: bank == null,
      ));
  void setBankAccountNumber(String value) =>
      emit(state.copyWith(bankAccountNumber: value));
  void setBankAccountName(String value) =>
      emit(state.copyWith(bankAccountName: value));
  void setBranchCode(String value) => emit(state.copyWith(branchCode: value));
  void setSelectedMomoProvider(PayoutProviderModel? provider) => emit(state.copyWith(
        selectedMomoProvider: provider,
        clearSelectedMomoProvider: provider == null,
      ));
  void setMomoNumber(String value) => emit(state.copyWith(momoNumber: value));

  /// Validates and submits the payout step via the same `PUT /vendor/me/payout`
  /// endpoint used by the standalone Payout Settings screen. Required: at
  /// least one of a complete bank set or a complete mobile-money set.
  Future<bool> submitPayoutDetails() async {
    final bank = state.selectedBank;
    final accountNumber = state.bankAccountNumber.trim();
    final accountName = state.bankAccountName.trim();
    final momo = state.selectedMomoProvider;
    final momoNumber = state.momoNumber.trim();

    final hasAnyBankField = bank != null || accountNumber.isNotEmpty || accountName.isNotEmpty;
    final bankComplete = bank != null && accountNumber.isNotEmpty && accountName.isNotEmpty;
    final momoComplete = momo != null && momoNumber.isNotEmpty;

    if (hasAnyBankField && !bankComplete) {
      emit(state.copyWith(
        status: VendorKycStatus.error,
        errorMessage: 'Bank, account number, and account name are all required together',
      ));
      return false;
    }
    if ((momo != null) != momoNumber.isNotEmpty) {
      emit(state.copyWith(
        status: VendorKycStatus.error,
        errorMessage: momo == null
            ? 'Select a mobile money provider'
            : 'Enter a mobile money number',
      ));
      return false;
    }
    if (!bankComplete && !momoComplete) {
      emit(state.copyWith(
        status: VendorKycStatus.error,
        errorMessage: 'Add a bank account or mobile money number to receive payouts',
      ));
      return false;
    }

    emit(state.copyWith(
      status: VendorKycStatus.saving,
      uploadProgressMessage: 'Saving payout details...',
    ));

    final data = <String, dynamic>{
      if (bankComplete) 'bank_name': bank.name,
      if (bankComplete) 'account_number': accountNumber,
      if (bankComplete) 'account_name': accountName,
      if (bankComplete && state.branchCode.trim().isNotEmpty)
        'branch_code': state.branchCode.trim(),
      if (momoComplete) 'mobile_money_number': momoNumber,
      if (momoComplete) 'mobile_money_provider': momo.shortName.toLowerCase(),
    };

    final result = await _dashboardRepository.updateVendorPayout(data);
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: VendorKycStatus.error,
          errorMessage: 'Failed to save payout details: ${failure.message}',
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

  /// Confirms the required documents are uploaded, then submits the profile
  /// for admin review via `POST /vendor/me/submit-review`. Business
  /// registration certificate and food safety license are already uploaded
  /// via [uploadDocument] as soon as the vendor confirms each one — no
  /// identity/ID-card step, no redundant profile PATCH.
  Future<bool> submitKyc() async {
    final profile = _currentUserProvider.user?.profile as VendorProfile?;
    final documents = profile?.documents;
    if (!(documents?.businessRegistrationCertificate.uploaded ?? false) ||
        !(documents?.foodSafetyLicense.uploaded ?? false)) {
      emit(state.copyWith(
        status: VendorKycStatus.error,
        errorMessage: 'Please upload all required documents',
      ));
      return false;
    }

    emit(state.copyWith(
      status: VendorKycStatus.saving,
      uploadProgressMessage: 'Submitting for review...',
    ));
    final result = await _dashboardRepository.submitVendorForReview();
    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: VendorKycStatus.error,
          errorMessage: 'Submission failed: ${failure.message}',
        ));
        return false;
      },
      (profile) {
        _syncProfile(profile);
        emit(state.copyWith(status: VendorKycStatus.success));
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
