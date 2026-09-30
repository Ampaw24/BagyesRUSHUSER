import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

class CurrentUserProvider extends ChangeNotifier {
  User? _user;
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);

  User? get user => _user;

  /// False for a guest browsing without an account. Needs both the profile
  /// and a session token: a token wiped by an expired-session 401 means
  /// account API calls can no longer succeed, even if the profile is still
  /// held in memory.
  bool get isAuthenticated => _user != null && Cache.instance.sessionToken != null;

  /// Calls [onChange] only when the user signs in or out — not on every
  /// profile update. Returns a callback that stops listening.
  VoidCallback addSignInListener(ValueChanged<bool> onChange) {
    var wasSignedIn = isAuthenticated;
    void listener() {
      final signedIn = isAuthenticated;
      if (signedIn == wasSignedIn) return;
      wasSignedIn = signedIn;
      onChange(signedIn);
    }

    addListener(listener);
    return () => removeListener(listener);
  }

  void setUser(User user) {
    _user = user;
    isLoggedInNotifier.value = true;
    appLogger.i('CurrentUserProvider: user set → id=${user.id} role=${user.role} phoneVerified=${user.phoneVerified}');
    notifyListeners();
  }

  void clearUser() {
    appLogger.i('CurrentUserProvider: user cleared');
    _user = null;
    isLoggedInNotifier.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    isLoggedInNotifier.dispose();
    super.dispose();
  }
}
