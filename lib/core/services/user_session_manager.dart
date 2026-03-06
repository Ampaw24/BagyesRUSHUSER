import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

class UserSessionManager extends ChangeNotifier {
  final SecureStorageService _storage;
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  UserSessionManager(this._storage);

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _accessToken != null;

  Future<void> init() async {
    _accessToken = await _storage.read('accessToken');
    _refreshToken = await _storage.read('refreshToken');
    // We could also store user info as JSON string
    notifyListeners();
  }

  Future<void> login(
    String token,
    String refresh,
    Map<String, dynamic> user,
  ) async {
    _accessToken = token;
    _refreshToken = refresh;
    _user = user;
    await _storage.write('accessToken', token);
    await _storage.write('refreshToken', refresh);
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await _storage.delete('accessToken');
    await _storage.delete('refreshToken');
    notifyListeners();
  }
}
