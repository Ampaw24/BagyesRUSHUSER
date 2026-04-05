import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

class AuthViewmodel extends ViewModel<AuthState> {
  AuthViewmodel({
    required AuthRepository repository,
    required CurrentUserProvider currentUserProvider,
  })  : _repository = repository,
        _currentUserProvider = currentUserProvider,
        super(const AuthInitial());

  final AuthRepository _repository;
  final CurrentUserProvider _currentUserProvider;

  // Cached OTP response (needed across signup/OTP screens)
  DataMap? _otpResponse;
  DataMap? get otpResponse => _otpResponse;

  // Temporary signup data stored across OTP flow
  DataMap? _pendingSignupData;

  void storeSignupData(DataMap data) {
    _pendingSignupData = data;
  }

  DataMap? get pendingSignupData => _pendingSignupData;

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    appLogger.d('AuthViewmodel.login → phone=***${phoneNumber.length > 4 ? phoneNumber.substring(phoneNumber.length - 4) : ""}');
    emit(const AuthLoading());

    final result = await _repository.login(
      phoneNumber: phoneNumber.trim(),
      password: password,
    );

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.login → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (user) {
        appLogger.i('AuthViewmodel.login → LoggedIn id=${user.id}');
        _currentUserProvider.setUser(user);
        emit(const LoggedIn());
      },
    );
  }

  Future<void> signup({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String role,
    required String firstName,
    required String lastName,
    String? address,
    String? referralCode,
  }) async {
    appLogger.d('AuthViewmodel.signup → initiated');
    emit(const AuthLoading());

    final result = await _repository.signup(
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
      firstName: firstName,
      lastName: lastName,
      address: address,
      referralCode: referralCode,
    );

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.signup → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (user) {
        appLogger.i('AuthViewmodel.signup → Registered id=${user.id}');
        _currentUserProvider.setUser(user);
        emit(const Registered());
      },
    );
  }

  Future<void> vendorRegister({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String businessName,
    required String businessTypeID,
    required String contactPersonName,
    required String businessAddress,
    required String city,
    required String description,
    required String taxIdentificationNumber,
    required List<String> cuisineTypes,
    required double deliveryRadiusKm,
    required String openingTime,
    required String closingTime,
    required List<String> operatingDays,
    required int estimatedPrepTimeMinutes,
  
  }) async {
    appLogger.d('AuthViewmodel.vendorRegister → initiated');
    emit(const AuthLoading());

    final result = await _repository.vendorRegister(
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      businessName: businessName,
      businessTypeId: businessTypeID,
      contactPersonName: contactPersonName,
      businessAddress: businessAddress,
      city: city,
      description: description,
      taxIdentificationNumber: taxIdentificationNumber,
      cuisineTypes: cuisineTypes,
      deliveryRadiusKm: deliveryRadiusKm,
      openingTime: openingTime,
      closingTime: closingTime,
      operatingDays: operatingDays,
      estimatedPrepTimeMinutes: estimatedPrepTimeMinutes,
    );

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.vendorRegister → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (user) {
        appLogger.i('AuthViewmodel.vendorRegister → VendorRegistered id=${user.id}');
        _currentUserProvider.setUser(user);
        emit(const VendorRegistered());
      },
    );
  }

  Future<void> sendOtp(String phone) async {
    appLogger.d('AuthViewmodel.sendOtp → initiated');
    emit(const RequestingOTP());

    final result = await _repository.sendOtp(phone: phone.trim());

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.sendOtp → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (response) {
        appLogger.i('AuthViewmodel.sendOtp → OTPSent');
        _otpResponse = response;
        emit(const OTPSent());
      },
    );
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    appLogger.d('AuthViewmodel.verifyOtp → initiated');
    emit(const AuthLoading());

    final result = await _repository.verifyOtp(phone: phone, otp: otp);

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.verifyOtp → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (_) {
        final user = _currentUserProvider.user;
        if (user != null) {
          _currentUserProvider.setUser(user.copyWith(phoneVerified: true));
        }
        appLogger.i('AuthViewmodel.verifyOtp → OTPVerified');
        emit(const OTPVerified());
      },
    );
  }

  Future<void> getUserDetails(String id) async {
    appLogger.d('AuthViewmodel.getUserDetails → id=$id');
    emit(const AuthLoading());

    final result = await _repository.getUserDetails(id);

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.getUserDetails → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (user) {
        appLogger.i('AuthViewmodel.getUserDetails → LoggedIn id=${user.id}');
        _currentUserProvider.setUser(user);
        emit(const LoggedIn());
      },
    );
  }

  /// Called on app launch. If a valid token + userId are found in secure
  /// storage (warmed into [Cache] by AppInitializer), marks the user as
  /// [LoggedIn] immediately and fetches the profile in the background.
  ///
  /// This decouples "auth state" from "profile data" — a network failure
  /// during profile fetch no longer forces the user back to the login screen
  /// when they have a valid token.
  Future<void> restoreSession() async {
    final token  = Cache.instance.sessionToken;
    final userId = Cache.instance.userId;

    if (token == null || userId == null) {
      appLogger.i('AuthViewmodel.restoreSession → no cached session, LoggedOut');
      emit(const LoggedOut());
      return;
    }

    // Mark as logged in immediately based on token presence
    appLogger.d('AuthViewmodel.restoreSession → token found, marking LoggedIn');
    emit(const LoggedIn());

    // Fetch profile in background — failures are non-fatal
    _fetchProfileInBackground(userId);
  }

  /// Fetches user profile without changing auth state on failure.
  /// If the fetch succeeds, updates [CurrentUserProvider].
  /// If it fails (e.g. poor connectivity), the user stays logged in
  /// and the profile will be retried on next relevant screen.
  Future<void> _fetchProfileInBackground(String userId) async {
    appLogger.d('AuthViewmodel._fetchProfileInBackground → userId=$userId');
    final result = await _repository.getUserDetails(userId);

    result.fold(
      (failure) {
        appLogger.w(
          'AuthViewmodel._fetchProfileInBackground → '
          'profile fetch failed (non-fatal): ${failure.message}',
        );
      },
      (user) {
        appLogger.i(
          'AuthViewmodel._fetchProfileInBackground → '
          'profile loaded id=${user.id}',
        );
        _currentUserProvider.setUser(user);
      },
    );
  }

  /// Explicitly refreshes the access token using the stored refresh token.
  ///
  /// Emits [AuthLoading] → [LoggedIn] on success.
  /// Emits [LoggedOut] on failure so the routing guard redirects to login.
  Future<void> refreshToken() async {
    appLogger.d('AuthViewmodel.refreshToken → initiated');
    emit(const AuthLoading());

    final result = await _repository.refreshToken();

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.refreshToken → failed: ${failure.message}');
        // Refresh failed — clear user and force re-login
        _currentUserProvider.clearUser();
        emit(const LoggedOut());
      },
      (_) {
        appLogger.i('AuthViewmodel.refreshToken → success, session continues');
        emit(const LoggedIn());
      },
    );
  }

  /// Resets state to [AuthInitial] after a one-shot action has been handled.
  void resetState() => emit(const AuthInitial());

  Future<void> logout() async {
    appLogger.d('AuthViewmodel.logout');
    emit(const AuthLoading());

    final result = await _repository.logout();

    // Always clear local state — the repository already wipes secure storage
    // and the in-memory Cache regardless of the server response.
    _currentUserProvider.clearUser();
    _otpResponse = null;
    _pendingSignupData = null;

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.logout → server error (session cleared locally): ${failure.message}');
        emit(const LoggedOut());
      },
      (_) {
        appLogger.i('AuthViewmodel.logout → LoggedOut');
        emit(const LoggedOut());
      },
    );
  }
}
