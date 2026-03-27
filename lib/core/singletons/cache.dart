class Cache {
  Cache._internal();
  static final Cache instance = Cache._internal();

  String? _sessionToken;
  String? _passwordResetToken;
  String? _userId;

  String? get sessionToken => _sessionToken;
  String? get passwordResetToken => _passwordResetToken;
  String? get userId => _userId;

  void setSessionToken(String? token) {
    if (_sessionToken != token) _sessionToken = token;
  }

  void setPasswordResetToken(String? token) {
    if (_passwordResetToken != token) _passwordResetToken = token;
  }

  void setUserId(String? id) {
    if (_userId != id) _userId = id;
  }

  void resetSession() {
    _sessionToken = null;
    _userId = null;
  }
}
