import 'package:bagyesrushappusernew/src/auth/models/business_type_model.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/helpers/cache_helper.dart';
import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/auth/models/otp_purpose.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_profile.dart';

/// `PUT customer/me` answered 200 but kept its previous address — every
/// other field in the request was saved. Carries the returned [user] so the
/// caller can still apply those.
class AddressNotSavedFailure extends Failure {
  const AddressNotSavedFailure(this.user)
      : super(
          title: 'Address Not Saved',
          message: "Your other details were saved, but we couldn't update "
              'your address. Please try again.',
          statusCode: 422,
        );

  final User user;
}

class AuthRepository {
  const AuthRepository({required Dio client, required CacheHelper cacheHelper})
    : _client = client,
      _cacheHelper = cacheHelper;

  final Dio _client;
  final CacheHelper _cacheHelper;

  /// Account roles this app can sign in.
  static const _appRoles = {'customer', 'vendor'};

  static const _invalidCredentials = ServerFailure(
    title: 'Login Failed',
    message: 'Incorrect phone number or password. Please try again.',
    statusCode: 401,
  );

  Future<void> _cacheTokens(DataMap payload) async {
    final token =
        payload['token'] as String? ?? payload['access_token'] as String?;
    final refreshToken = payload['refresh_token'] as String?;
    if (token != null) await _cacheHelper.cacheSessionToken(token);
    if (refreshToken != null) {
      await _cacheHelper.cacheRefreshToken(refreshToken);
    }
  }

  ResultFuture<User> signup({
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
    appLogger.d('AuthRepository.signup → role=$role');
    final data = {
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': confirmPassword,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'address': address ?? '',
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
    };
    try {
      final response = await _client.post(ApiEndpoints.signup, data: data);

      appLogger.d(
        'AuthRepository.signup → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);

        await _cacheTokens(payload);
        await _cacheHelper.cacheUserId(user.id);
        await _cacheHelper.cacheUserRole(user.role);

        appLogger.i('AuthRepository.signup → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.signup → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.signup → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'signup',
      );
    }
  }
  //[vendor registration]

  ResultFuture<User> vendorRegister({
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String businessName,
    required String businessType,
    required String businessTypeId,
    required String contactPersonName,
    required String businessAddress,
    required double latitude,
    required double longitude,
    required String city,
    required String description,
    required String taxIdentificationNumber,
    required List<String> cuisineTypes,
    required double deliveryRadiusKm,
  }) async {
    appLogger.d('AuthRepository.vendorRegister → initiated');
    final data = {
      "email": email,
      "phone": phone,
      "password": password,
      "password_confirmation": confirmPassword,
      "role": "vendor",
      "business_name": businessName,
      "business_type_id": businessTypeId,
      "contact_person_name": contactPersonName,
      "business_address": businessAddress,
      "latitude": latitude,
      "longitude": longitude,
      "city": city,
      "description": description,
      "tax_identification_number": taxIdentificationNumber,
      "cuisine_types": cuisineTypes.map((e) => e.trim().toLowerCase()).toList(),
      "delivery_radius_km": deliveryRadiusKm,
      // Store hours/operating days/prep time are collected later, during
      // KYC — the backend accepts registration without them.
    };
    appLogger.d('AuthRepository.vendorRegister → PAYLOAD: $data');
    try {
      final response = await _client.post(
        ApiEndpoints.vendorRegister,
        data: data,
      );

      appLogger.d(
        'AuthRepository.vendorRegister → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      appLogger.d(
        'AuthRepository.vendorRegister → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        final userJson = payload['user'] as DataMap? ?? payload;
        final user = User.fromJson(userJson);

        await _cacheTokens(payload);
        await _cacheHelper.cacheUserId(user.id);
        await _cacheHelper.cacheUserRole(user.role);

        appLogger.i('AuthRepository.vendorRegister → success id=${user.id}');
        return Right(user);
      }

      appLogger.w(
        'AuthRepository.vendorRegister → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.vendorRegister → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'vendorRegister',
      );
    }
  }

  //[/vendor registration end]
  ///Provide business type for vendor registeration
  ResultFuture<List<BusinessTypeModel>> fetchBusinessTypes() async {
    appLogger.d('AuthRepository.fetchBusinessTypes → initiated');
    try {
      final response = await _client.get(ApiEndpoints.businessTypes);

      appLogger.d(
        'AuthRepository.fetchBusinessTypes → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload = _extractBusinessTypesList(response.data);
        final businessTypes = payload
            .map((e) => BusinessTypeModel.fromJson(e as DataMap))
            .toList();
        appLogger.i(
          'AuthRepository.fetchBusinessTypes → loaded ${businessTypes.length} business types',
        );
        return Right(businessTypes);
      }

      appLogger.w(
        'AuthRepository.fetchBusinessTypes → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.fetchBusinessTypes → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'fetchBusinessTypes',
      );
    }
  }

  /// Pulls the business-type list out of [rawData] regardless of whether the
  /// API wraps it as `data: [...]` or nests it one level deeper (e.g. under a
  /// paginated `data: { docs / items / businessTypes: [...] }` envelope).
  ///
  /// Falls back to an empty list — instead of throwing — when the shape is
  /// unrecognised, and logs the unmatched keys so the real shape can be seen
  /// in the console rather than crashing the caller.
  List<dynamic> _extractBusinessTypesList(dynamic rawData) {
    if (rawData is List) return rawData;

    if (rawData is DataMap) {
      final inner = rawData['data'];
      if (inner is List) return inner;

      if (inner is DataMap) {
        for (final key in ['docs', 'items', 'businessTypes', 'results', 'list']) {
          final nested = inner[key];
          if (nested is List) return nested;
        }
        appLogger.w(
          'AuthRepository.fetchBusinessTypes → unrecognised payload shape, '
          'keys: ${inner.keys.toList()}',
        );
      }
    }

    return const [];
  }

  //Business Type fetching ends here

  ResultFuture<User> login({
    required String phoneNumber,
    required String password,
  }) async {
    appLogger.d('AuthRepository.login → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: {'phone': phoneNumber, 'password': password},
      );

      appLogger.d(
        'AuthRepository.login → RAW RESPONSE\n'
        '  status : ${response.statusCode}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        final userJson = payload['user'] as DataMap? ?? payload;
        final parsed = User.fromJson(userJson);
        appLogger.d('AuthRepository.login → user=${parsed.toJson()}');
        appLogger.d('AuthRepository.login → payload=${parsed.id}');

        // This app only serves customers and vendors. Any other account
        // (rider, admin, ...) is turned away *before* its tokens are cached
        // — otherwise the next launch would restore that session anyway —
        // with the same message as bad credentials, so the screen doesn't
        // reveal which roles exist.
        final role = parsed.role.trim().toLowerCase();
        if (!_appRoles.contains(role)) {
          appLogger.w(
            'AuthRepository.login → rejected unsupported role '
            '"${parsed.role}" id=${parsed.id}',
          );
          return const Left(_invalidCredentials);
        }
        // Normalized so role checks elsewhere (`role == 'vendor'`) hold even
        // if the backend's casing drifts.
        final user = parsed.copyWith(role: role);

        await _cacheTokens(payload);
        await _cacheHelper.cacheUserId(user.id);
        await _cacheHelper.cacheUserRole(user.role);

        appLogger.i('AuthRepository.login → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.login → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.login → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'login',
      );
    }
  }

  ResultFuture sendOtp({
    required String phone,
    required OtpPurpose purpose,
  }) async {
    appLogger.d('AuthRepository.sendOtp → purpose=${purpose.value}');
    try {
      // The backend's phone-verification endpoint is purpose-agnostic — it
      // only accepts `phone`. `purpose` stays a client-side concept, used to
      // decide what happens locally once the code is sent/verified.
      final response = await _client.post(
        ApiEndpoints.otpSend,
        data: {'phone': phone},
      );

      appLogger.d(
        'AuthRepository.sendOtp → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.sendOtp → success');
        return Right(response.data as DataMap);
      }

      appLogger.w('AuthRepository.sendOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.sendOtp → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'sendOtp',
      );
    }
  }

  /// `POST /password/forgot` — dedicated, public endpoint for requesting the
  /// OTP that starts the "forgot password" flow (login screen, signed-out
  /// user). Distinct from [sendOtp], which hits the generic phone-verification
  /// endpoint used during signup/KYC.
  ResultFuture sendForgotPasswordOtp({required String phone}) async {
    appLogger.d('AuthRepository.sendForgotPasswordOtp → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.passwordForgot,
        data: {'phone': phone},
      );

      appLogger.d(
        'AuthRepository.sendForgotPasswordOtp → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.sendForgotPasswordOtp → success');
        return Right(response.data as DataMap);
      }

      appLogger.w(
        'AuthRepository.sendForgotPasswordOtp → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.sendForgotPasswordOtp → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'sendForgotPasswordOtp',
      );
    }
  }

  ResultFuture<void> verifyOtp({
    required String phone,
    required String otp,
    required OtpPurpose purpose,
  }) async {
    appLogger.d('AuthRepository.verifyOtp → purpose=${purpose.value}');
    try {
      // Same as sendOtp — the backend's verify endpoint only accepts
      // `phone` + `code`, no `purpose`.
      final response = await _client.post(
        ApiEndpoints.otpVerify,
        data: {'phone': phone, 'code': otp},
      );

      appLogger.d(
        'AuthRepository.verifyOtp → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.verifyOtp → verified');

        // Some backends issue a fresh, fully-scoped token once the phone is
        // verified (the pre-verification token from signup can be limited
        // in scope) — cache it if present so the user isn't silently logged
        // out the next time an authenticated request rejects the old one.
        final data = response.data;
        if (data is DataMap) {
          final payload = data['data'] as DataMap? ?? data;
          await _cacheTokens(payload);
        }

        return const Right(null);
      }

      appLogger.w('AuthRepository.verifyOtp → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.verifyOtp → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'verifyOtp',
      );
    }
  }

  /// [timeout], when provided, overrides the connect/receive timeout for
  /// just this call — used during app-launch session restore so a slow or
  /// unreachable backend fails fast instead of hanging on the shared
  /// 30-second default (see [AuthViewmodel.restoreSession]).
  ResultFuture<User> getUserDetails(String id, {Duration? timeout}) async {
    appLogger.d('AuthRepository.getUserDetails → id=$id');
    try {
      final response = await _client.get(
        ApiEndpoints.profile,
        options: timeout == null
            ? null
            : Options(connectTimeout: timeout, receiveTimeout: timeout),
      );

      if (response.statusCode == 200) {
        final responseData = response.data as DataMap;
        final userJson = responseData['data'] as DataMap? ?? responseData;
        final user = User.fromJson(userJson);
        appLogger.i('AuthRepository.getUserDetails → success id=${user.id}');
        return Right(user);
      }

      appLogger.w(
        'AuthRepository.getUserDetails → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.getUserDetails → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'getUserDetails',
      );
    }
  }

  Future<String?> getUserId() async {
    return _cacheHelper.getUserId();
  }

  /// The device token last successfully registered with the backend for the
  /// current session, or `null` if none has been sent yet.
  Future<String?> getCachedDeviceToken() async {
    return _cacheHelper.getDeviceToken();
  }

  Future<void> cacheDeviceToken(String token) async {
    await _cacheHelper.cacheDeviceToken(token);
  }

  ///["send device token to server push notification setup"]
  ResultFuture<DataMap> sendDeviceToken({
    required String deviceToken,
    required String platform,
    required String deviceName,
  }) async {
    appLogger.d('AuthRepository.sendDeviceToken → deviceToken=$deviceToken');
    try {
      final response = await _client.post(
        ApiEndpoints.deviceToken,
        data: {"token": deviceToken, "platform": platform, "device_name": deviceName},
      );

      appLogger.d(
        'AuthRepository.sendDeviceToken → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.sendDeviceToken → success');
        return Right(response.data as DataMap);
      }

      appLogger.w(
        'AuthRepository.sendDeviceToken → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.sendDeviceToken → DioException\n'
        '  type   : ${e.type}\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'sendDeviceToken',
      );
    }
  }

  /// Fetches the vendor-specific profile from `GET /vendors/profile`.
  ///
  /// Called during session restore when the authenticated user is a vendor,
  /// because the generic `/auth/me` endpoint does not include vendor profile
  /// data (business name, status, isProfileComplete, etc.).
  ResultFuture<VendorProfile> fetchVendorProfile() async {
    appLogger.d('AuthRepository.fetchVendorProfile → initiated');
    try {
      final response = await _client.get(ApiEndpoints.vendorProfile);
      if (response.statusCode == 200) {
        final responseData = response.data as DataMap;
        final profileJson = responseData['data'] as DataMap? ?? responseData;
        final profile = VendorProfile.fromJson(profileJson);
        appLogger.i('AuthRepository.fetchVendorProfile → success');
        return Right(profile);
      }
      appLogger.w(
        'AuthRepository.fetchVendorProfile → HTTP ${response.statusCode}',
      );
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.fetchVendorProfile → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'fetchVendorProfile',
      );
    }
  }

  Future<String?> getCachedUserRole() async {
    return _cacheHelper.getUserRole();
  }

  /// Writes [role] back to secure storage so the next cold-start restores the
  /// correct role even when the profile endpoint omits the field.
  /// Fire-and-forget — callers should not await this.
  Future<void> syncUserRole(String role) async {
    await _cacheHelper.cacheUserRole(role);
    appLogger.d('AuthRepository.syncUserRole → role=$role synced to storage');
  }

  /// Exchanges the stored refresh token for a new access + refresh token pair.
  ///
  /// On success both tokens are persisted via [CacheHelper] and the in-memory
  /// [Cache] singleton is updated so subsequent requests get the new token
  /// immediately — no app restart needed.
  ///
  /// On failure the caller receives a [Left<Failure>]; local session data is
  /// left intact so the UI can decide whether to force a logout.
  ResultFuture<void> refreshToken() async {
    appLogger.d('AuthRepository.refreshToken → attempting token refresh');
    try {
      final storedRefreshToken = await _cacheHelper.getRefreshToken();

      if (storedRefreshToken == null) {
        appLogger.w('AuthRepository.refreshToken → no refresh token stored');
        return Left(
          const ServerFailure(
            message: 'No refresh token available. Please log in again.',
            statusCode: 401,
            title: 'Session Expired',
          ),
        );
      }

      final response = await _client.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': storedRefreshToken},
      );
      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;

        await _cacheTokens(payload);
        appLogger.i('AuthRepository.refreshToken → new tokens cached');
        return const Right(null);
      }
      appLogger.w('AuthRepository.refreshToken → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.refreshToken → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'refreshToken',
      );
    }
  }

  ResultFuture<User> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? address,
  }) async {
    appLogger.d('AuthRepository.updateProfile → initiated');
    try {
      final response = await _client.put(
        ApiEndpoints.customerMe,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          // Right after a cold start the cached user is a placeholder with no
          // phone until the profile fetch lands — never send that blank.
          if (phone.isNotEmpty) 'phone': phone,
          ...?address == null ? null : {'address': address},
        },
      );

      appLogger.d(
        'AuthRepository.updateProfile → RAW RESPONSE\n'
        '  status : ${response.statusCode}\n'
        '  data   : ${response.data}',
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final user = User.fromJson(payload);

        // A 200 doesn't guarantee every field stuck — if the server echoes
        // back a different address than we sent, it ignored ours. Report
        // that instead of a success the next profile refresh would quietly
        // undo.
        final echoed = _echoedAddress(payload);
        if (address != null &&
            echoed != null &&
            _normalizeAddress(echoed) != _normalizeAddress(address)) {
          appLogger.w(
            'AuthRepository.updateProfile → address not saved: '
            'sent "$address", server has "$echoed"',
          );
          return Left(AddressNotSavedFailure(user));
        }

        appLogger.i('AuthRepository.updateProfile → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.updateProfile → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.updateProfile → DioException\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'updateProfile',
      );
    }
  }

  /// The `address` in an update response — on the profile document itself
  /// or nested under `profile` / `user.profile` — or null when the response
  /// doesn't include one (absent, as opposed to empty, says nothing about
  /// whether it was saved).
  String? _echoedAddress(DataMap payload) {
    final user = payload['user'];
    final candidates = [
      payload['profile'],
      if (user is DataMap) user['profile'],
      payload,
    ];
    for (final candidate in candidates) {
      if (candidate is DataMap && candidate.containsKey('address')) {
        return candidate['address']?.toString() ?? '';
      }
    }
    return null;
  }

  static String _normalizeAddress(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// Picked photos can come back with an extension-less temp path, in which
  /// case dio sends no content type and some backends reject the part.
  DioMediaType _imageMediaType(String path) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'heic' => DioMediaType('image', 'heic'),
      _ => DioMediaType('image', 'jpeg'),
    };
  }

  ResultFuture<User> uploadAvatar(String filePath) async {
    appLogger.d('AuthRepository.uploadAvatar → path=$filePath');
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split(RegExp(r'[/\\]')).last,
          contentType: _imageMediaType(filePath),
        ),
      });
      final response = await _client.post(
        ApiEndpoints.customerAvatar,
        data: formData,
      );

      if ([200, 201].contains(response.statusCode)) {
        final payload =
            (response.data as DataMap)['data'] as DataMap? ??
            response.data as DataMap;
        final user = User.fromJson(payload);
        appLogger.i('AuthRepository.uploadAvatar → success id=${user.id}');
        return Right(user);
      }

      appLogger.w('AuthRepository.uploadAvatar → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.uploadAvatar → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'uploadAvatar',
      );
    }
  }

  ResultFuture<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    appLogger.d('AuthRepository.changePassword → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.passwordChange,
        data: {
          'current_password': oldPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.changePassword → success');
        return const Right(null);
      }

      appLogger.w('AuthRepository.changePassword → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e('AuthRepository.changePassword → DioException', error: e);
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'changePassword',
      );
    }
  }

  ResultFuture<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    appLogger.d('AuthRepository.resetPassword → phone=$phone');
    try {
      final response = await _client.post(
        ApiEndpoints.forgotPassword,
        data: {
          "phone": phone,
          "code": code,
          "password": password,
          "password_confirmation": confirmPassword,
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.resetPassword → success');
        return const Right(null);
      }

      appLogger.w('AuthRepository.resetPassword → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.resetPassword → DioException\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'resetPassword',
      );
    }
  }

  /// Logs the user out by deregistering this device and invalidating the
  /// server session (while the token is still valid), then clearing all
  /// local state.
  ResultFuture<void> logout() async {
    appLogger.d('AuthRepository.logout → clearing session');
    try {
      // Device first: once /logout revokes the token, this call would 401
      // and needlessly kick off a token refresh.
      try {
        await _client.delete(ApiEndpoints.deviceToken);
      } catch (_) {
        // Device token deregistration is best-effort
      }
      try {
        await _client.post(ApiEndpoints.logout);
      } catch (_) {
        // Server logout is best-effort too — always clear local session
      }
      await _cacheHelper.resetSession();
      appLogger.i('AuthRepository.logout → session cleared');
      return const Right(null);
    } catch (e, s) {
      // Even on unexpected failure, ensure local session is cleared
      await _cacheHelper.resetSession();
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'logout',
      );
    }
  }

  /// Clears the persisted session locally only — no server round-trip.
  ///
  /// Used when app-launch session restore can't confirm the cached token is
  /// still valid (expired/invalid, or the backend couldn't be reached at
  /// all). Unlike [logout], this never calls the server: if the backend is
  /// the reason validation failed, best-effort "notify the server" calls
  /// would just hang on the same problem.
  Future<void> clearLocalSession() async {
    await _cacheHelper.resetSession();
  }

  /// Permanently deletes the signed-in user's account via `POST
  /// /account/delete`. [password] re-verifies identity (required by the
  /// backend); [reason] is an optional, free-text explanation (max 500
  /// chars) used for churn feedback.
  ///
  /// Unlike [logout], the local session is only cleared on success — a
  /// rejected request (e.g. wrong password) leaves the session intact so the
  /// caller can let the user retry.
  ResultFuture<void> deleteAccount({
    required String password,
    String? reason,
  }) async {
    appLogger.d('AuthRepository.deleteAccount → initiated');
    try {
      final response = await _client.post(
        ApiEndpoints.accountDelete,
        data: {
          'password': password,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

      if ([200, 201].contains(response.statusCode)) {
        appLogger.i('AuthRepository.deleteAccount → success, clearing session');
        await _cacheHelper.resetSession();
        return const Right(null);
      }

      appLogger.w('AuthRepository.deleteAccount → HTTP ${response.statusCode}');
      return NetworkUtils.handleDioResponseError(response);
    } on DioException catch (e) {
      appLogger.e(
        'AuthRepository.deleteAccount → DioException\n'
        '  status : ${e.response?.statusCode}\n'
        '  data   : ${e.response?.data}',
        error: e,
      );
      return NetworkUtils.handleDioException(e);
    } catch (e, s) {
      return NetworkUtils.handleException(
        e,
        s,
        repositoryName: 'AuthRepository',
        methodName: 'deleteAccount',
      );
    }
  }
}
