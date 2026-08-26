import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/services/fcm_service.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/device_info_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

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

  // Phone number used in the last sendOtp call — read by OTPView when the
  // user arrives from a flow where CurrentUserProvider has no user yet
  // (e.g. login → "phone not verified" → Proceed to Verify).
  String? _pendingPhone;
  String? get pendingPhone => _pendingPhone;

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
    required String businessType,
    required String businessTypeID,
    required String contactPersonName,
    required String businessAddress,
    required String city,
    required String description,
    required String taxIdentificationNumber,
    required List<String> cuisineTypes,
    required double deliveryRadiusKm,
  }) async {
    appLogger.d('AuthViewmodel.vendorRegister → initiated');
    emit(const AuthLoading());

    final result = await _repository.vendorRegister(
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      businessName: businessName,
      businessType: businessType,
      businessTypeId: businessTypeID,
      contactPersonName: contactPersonName,
      businessAddress: businessAddress,
      city: city,
      description: description,
      taxIdentificationNumber: taxIdentificationNumber,
      cuisineTypes: cuisineTypes,
      deliveryRadiusKm: deliveryRadiusKm,
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
  

  Future<void> fetchBusinessTypes() async {
    appLogger.d('AuthViewmodel.fetchBusinessTypes → initiated');
    emit(const AuthLoading());

    final result = await _repository.fetchBusinessTypes();

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.fetchBusinessTypes → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (businessTypes) {
        appLogger.i('AuthViewmodel.fetchBusinessTypes → BusinessTypesFetched');
        emit(BusinessTypesFetched(businessTypes));
      },
    );
  }
  
  Future<void> sendOtp(String phone) async {
    _pendingPhone = phone.trim();
    appLogger.d('AuthViewmodel.sendOtp → initiated');
    emit(const RequestingOTP());

    final result = await _repository.sendOtp(phone: phone.trim());

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.sendOtp → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (response) {
        _otpResponse = response;
        appLogger.i('AuthViewmodel.sendOtp → OTPSent');
        emit(const OTPSent());
      },
    );
  }

  /// Starts the "forgot password" flow (login screen, signed-out user) by
  /// requesting an OTP through the dedicated `/password/forgot` endpoint.
  /// Emits the same [RequestingOTP]/[OTPSent]/[AuthError] states as [sendOtp]
  /// so OTPView's listener handles both without change — only the endpoint
  /// hit differs.
  Future<void> sendForgotPasswordOtp(String phone) async {
    _pendingPhone = phone.trim();
    appLogger.d('AuthViewmodel.sendForgotPasswordOtp → initiated');
    emit(const RequestingOTP());

    final result = await _repository.sendForgotPasswordOtp(phone: phone.trim());

    result.fold(
      (failure) {
        appLogger.w(
          'AuthViewmodel.sendForgotPasswordOtp → error: ${failure.message}',
        );
        emit(AuthError.fromFailure(failure));
      },
      (response) {
        _otpResponse = response;
        appLogger.i('AuthViewmodel.sendForgotPasswordOtp → OTPSent');
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
    final role   = await _repository.getCachedUserRole();

    if (token == null || userId == null) {
      appLogger.i('AuthViewmodel.restoreSession → no cached session, LoggedOut');
      emit(const LoggedOut());
      return;
    }

    // If we have a role, set a minimal user so routing works immediately
    if (role != null) {
      _currentUserProvider.setUser(User(
        id: userId,
        role: role,
        email: '',
        phone: '',
        status: '',
        phoneVerified: true, // Assume verified until profile says otherwise
        profile: null,
      ));
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
  ///
  /// **Vendor profile gap:** `/auth/me` returns only base user fields — it does
  /// NOT embed the vendor profile (business name, status, isProfileComplete,
  /// etc.). For vendor accounts we make a second call to `GET /vendors/profile`
  /// and merge the result so [VendorHome] has the data it needs on cold start.
  ///
  /// **Role preservation:** `/auth/me` may omit the `role` field for vendor
  /// accounts. We capture the authoritative role before the async gap and
  /// restore it if the response comes back empty.
  Future<void> _fetchProfileInBackground(String userId) async {
    appLogger.d('AuthViewmodel._fetchProfileInBackground → userId=$userId');

    // Capture role BEFORE the async gap so we can restore it if needed.
    final knownRole = _currentUserProvider.user?.role ?? '';

    final result = await _repository.getUserDetails(userId);

    await result.fold(
      (failure) async {
        appLogger.w(
          'AuthViewmodel._fetchProfileInBackground → '
          'profile fetch failed (non-fatal): ${failure.message}',
        );
      },
      (user) async {
        // Restore role if the base endpoint didn't include it.
        final resolvedUser =
            user.role.isNotEmpty ? user : user.copyWith(role: knownRole);

        // For vendor accounts, /auth/me does not embed the vendor profile.
        // Fetch it separately and merge before updating the provider so the
        // vendor home screen has all the data it needs on the first render.
        if (resolvedUser.role == 'vendor' && resolvedUser.profile == null) {
          final vendorResult = await _repository.fetchVendorProfile();
          vendorResult.fold(
            (failure) {
              appLogger.w(
                'AuthViewmodel._fetchProfileInBackground → '
                'vendor profile fetch failed (non-fatal): ${failure.message}',
              );
              // Still update with base user data — better than nothing.
              _currentUserProvider.setUser(resolvedUser);
            },
            (vendorProfile) {
              appLogger.i(
                'AuthViewmodel._fetchProfileInBackground → '
                'vendor profile merged for id=${resolvedUser.id}',
              );
              _currentUserProvider.setUser(
                resolvedUser.copyWith(profile: vendorProfile),
              );
            },
          );
        } else {
          _currentUserProvider.setUser(resolvedUser);
        }

        appLogger.i(
          'AuthViewmodel._fetchProfileInBackground → '
          'profile loaded id=${resolvedUser.id} role=${resolvedUser.role}',
        );

        // Keep secure storage in sync so the next cold-start restores the
        // correct role even if the profile endpoint is temporarily unavailable.
        if (resolvedUser.role.isNotEmpty) {
          _repository.syncUserRole(resolvedUser.role);
        }
      },
    );
  }

  /// Registers this device's FCM token with the backend so it can receive
  /// push notifications for the current user.
  ///
  /// Called once the user lands on the home screen after a successful login
  /// or registration (both customer and vendor). Safe to call on every app
  /// open — skips the network call when the token hasn't changed since the
  /// last successful registration, and always re-registers after a fresh
  /// login since [CacheHelper.resetSession] clears the cached token on
  /// logout, correctly re-associating the device with whichever account
  /// signs in next.
  Future<void> registerDeviceToken() async {
    try {
      final token = await FcmService.getToken();
      if (token == null) {
        appLogger.w('AuthViewmodel.registerDeviceToken → no FCM token available');
        return;
      }

      final lastRegisteredToken = await _repository.getCachedDeviceToken();
      if (lastRegisteredToken == token) {
        appLogger.d('AuthViewmodel.registerDeviceToken → token already registered');
        return;
      }

      final device = await DeviceInfoUtils.getDetails();
      final result = await _repository.sendDeviceToken(
        deviceToken: token,
        platform: device.platform,
        deviceName: device.deviceName,
      );

      await result.fold(
        (failure) async {
          appLogger.w(
            'AuthViewmodel.registerDeviceToken → error: ${failure.message}',
          );
        },
        (_) async {
          await _repository.cacheDeviceToken(token);
          appLogger.i('AuthViewmodel.registerDeviceToken → device token registered');
        },
      );
    } catch (e, s) {
      appLogger.e(
        'AuthViewmodel.registerDeviceToken → unexpected error',
        error: e,
        stackTrace: s,
      );
    }
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

  Future<void> resetPassword({
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    appLogger.d('AuthViewmodel.resetPassword → initiated');
    emit(const AuthLoading());

    final result = await _repository.resetPassword(
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.resetPassword → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (_) {
        appLogger.i('AuthViewmodel.resetPassword → success');
        emit(const PasswordResetSuccess());
      },
    );
  }

  /// Uploads a new profile picture for the current customer.
  ///
  /// Emits [AvatarUploading] while the request is in flight, updates
  /// [CurrentUserProvider] with the returned user on success (so the new
  /// avatar shows up everywhere it's displayed), then emits [AvatarUploaded].
  Future<void> uploadAvatar(String filePath) async {
    appLogger.d('AuthViewmodel.uploadAvatar → path=$filePath');
    emit(const AvatarUploading());

    final result = await _repository.uploadAvatar(filePath);

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.uploadAvatar → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (user) {
        appLogger.i('AuthViewmodel.uploadAvatar → success id=${user.id}');
        _currentUserProvider.setUser(user);
        emit(AvatarUploaded(user));
      },
    );
  }

  /// Changes the current user's password while they remain signed in
  /// (distinct from [resetPassword], which goes through the OTP-based
  /// forgot-password flow). Shared by both customer and vendor screens
  /// since password auth is role-agnostic.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    appLogger.d('AuthViewmodel.changePassword → initiated');
    emit(const PasswordChanging());

    final result = await _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) {
        appLogger.w('AuthViewmodel.changePassword → error: ${failure.message}');
        emit(AuthError.fromFailure(failure));
      },
      (_) {
        appLogger.i('AuthViewmodel.changePassword → success');
        emit(const PasswordChanged());
      },
    );
  }

  Future<void> logout() async {
    appLogger.d('AuthViewmodel.logout');
    emit(const AuthLoading());

    final result = await _repository.logout();

    // Always clear local state — the repository already wipes secure storage
    // and the in-memory Cache regardless of the server response.
    _currentUserProvider.clearUser();
    _otpResponse = null;
    _pendingSignupData = null;
    _pendingPhone = null;

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
