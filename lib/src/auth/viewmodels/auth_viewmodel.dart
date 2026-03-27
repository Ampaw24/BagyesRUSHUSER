import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
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
    emit(const AuthLoading());

    final result = await _repository.login(
      phoneNumber: phoneNumber,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (user) {
        _currentUserProvider.setUser(user);
        emit(const LoggedIn());
      },
    );
  }

  Future<void> signup(DataMap data) async {
    emit(const AuthLoading());

    final result = await _repository.signup(data);

    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (user) {
        _currentUserProvider.setUser(user);
        emit(const Registered());
      },
    );
  }

  Future<void> sendOtp(String phone) async {
    emit(const RequestingOTP());

    final result = await _repository.sendOtp({'phone': phone});

    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (response) {
        _otpResponse = response;
        emit(const OTPSent());
      },
    );
  }

  Future<void> getUserDetails(String id) async {
    emit(const AuthLoading());

    final result = await _repository.getUserDetails(id);

    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (user) {
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
      emit(const LoggedOut());
      return;
    }

    await getUserDetails(userId);
  }

  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _repository.logout();

    result.fold(
      (failure) => emit(AuthError.fromFailure(failure)),
      (_) {
        _currentUserProvider.clearUser();
        _otpResponse = null;
        _pendingSignupData = null;
        emit(const LoggedOut());
      },
    );
  }
}
