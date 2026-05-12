import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';

/// All sensitive data (token, refresh token, user id) is stored exclusively
/// in FlutterSecureStorage (iOS Keychain / Android Keystore).
class CacheHelper {
  CacheHelper({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const _sessionTokenKey  = 'session_token';
  static const _refreshTokenKey  = 'refresh_token';
  static const _userIdKey        = 'user_id';
  static const _userRoleKey      = 'user_role';

  // ── Session token ──────────────────────────────────────────────────────────

  Future<void> cacheSessionToken(String token) async {
    await _secureStorage.write(key: _sessionTokenKey, value: token);
    Cache.instance.setSessionToken(token);
    appLogger.d('CacheHelper: session token cached');
  }

  Future<String?> getSessionToken() async {
    final token = await _secureStorage.read(key: _sessionTokenKey);
    if (token != null) {
      Cache.instance.setSessionToken(token);
      appLogger.d('CacheHelper: session token restored from storage');
    }
    return token;
  }

  // ── Refresh token ──────────────────────────────────────────────────────────

  Future<void> cacheRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
    appLogger.d('CacheHelper: refresh token cached');
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  // ── User ID ────────────────────────────────────────────────────────────────

  Future<void> cacheUserId(String id) async {
    await _secureStorage.write(key: _userIdKey, value: id);
    Cache.instance.setUserId(id);
    appLogger.d('CacheHelper: userId cached');
  }

  Future<String?> getUserId() async {
    final id = await _secureStorage.read(key: _userIdKey);
    if (id != null) {
      Cache.instance.setUserId(id);
      appLogger.d('CacheHelper: userId restored from storage');
    }
    return id;
  }

  // ── User Role ──────────────────────────────────────────────────────────────

  Future<void> cacheUserRole(String role) async {
    await _secureStorage.write(key: _userRoleKey, value: role);
    appLogger.d('CacheHelper: userRole cached');
  }

  Future<String?> getUserRole() async {
    return _secureStorage.read(key: _userRoleKey);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> resetSession() async {
    await _secureStorage.delete(key: _sessionTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userRoleKey);
    Cache.instance.resetSession();
    appLogger.i('CacheHelper: session cleared');
  }
}
