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
    appLogger.d('AuthViewmodel.login → phone=$phoneNumber');
    emit(const AuthLoading());

    final result = await _repository.login(
      phoneNumber: phoneNumber.trim(),
      password: password.trim(),
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
    appLogger.d('AuthViewmodel.signup → email=$email phone=$phone');
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

  Future<void> sendOtp(String phone) async {
    appLogger.d('AuthViewmodel.sendOtp → phone=$phone');
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
    appLogger.d('AuthViewmodel.verifyOtp → phone=$phone');
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
  /// storage (warmed into [Cache] by AppInitializer), re-fetches the full
  /// user profile so the app can resume without requiring a new login.
  Future<void> restoreSession() async {
    final token  = Cache.instance.sessionToken;
    final userId = Cache.instance.userId;

    if (token == null || userId == null) {
      appLogger.i('AuthViewmodel.restoreSession → no cached session, LoggedOut');
      emit(const LoggedOut());
      return;
    }

    appLogger.d('AuthViewmodel.restoreSession → restoring session for userId=$userId');
    await getUserDetails(userId);
  }

  /// Resets state to [AuthInitial] after a one-shot action has been handled.
  void resetState() => emit(const AuthInitial());

  Future<void> logout() async {
    appLogger.d('AuthViewmodel.logout');
    emit(const AuthLoading());

    final result = await _repository.logout();

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.logout → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (_) {
        appLogger.i('AuthViewmodel.logout → LoggedOut');
        _currentUserProvider.clearUser();
        _otpResponse = null;
        _pendingSignupData = null;
        emit(const LoggedOut());
      },
    );
  }
}
