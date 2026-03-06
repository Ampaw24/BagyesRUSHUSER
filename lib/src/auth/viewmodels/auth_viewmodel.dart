import 'package:equatable/equatable.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../../../core/services/user_session_manager.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final Map<String, dynamic>? signupData;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.signupData,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    Map<String, dynamic>? signupData,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      signupData: signupData ?? this.signupData,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, signupData];
}

class AuthViewModel extends ViewModel<AuthState> {
  final AuthRepository _authRepository;
  final UserSessionManager _sessionManager;

  AuthViewModel(this._authRepository, this._sessionManager)
    : super(const AuthState());

  Future<void> login(String phone, String password) async {
    // This is just a placeholder, existing app seems to use OTP
  }

  Future<void> signup(Map<String, dynamic> data) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.signup(data);
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (user) async {
        await _sessionManager.login(user.token ?? '', '', user.toJson());
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      },
    );
  }

  Future<void> sendOtp(String phone) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _authRepository.sendOtp({'phone': phone});
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (data) => emit(
        state.copyWith(
          status: AuthStatus.initial,
          user: UserModel(id: '', phone: phone), // Store phone temporarily
        ),
      ),
    );
  }

  /// Store signup data temporarily for OTP verification flow
  void storeSignupData(Map<String, dynamic> data) {
    emit(state.copyWith(signupData: data));
  }

  void logout() async {
    await _sessionManager.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
  }
}
