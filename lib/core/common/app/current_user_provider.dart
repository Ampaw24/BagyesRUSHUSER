import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/src/auth/models/user.dart';

class CurrentUserProvider extends ChangeNotifier {
  User? _user;
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(User user) {
    if (_user != user) {
      _user = user;
      isLoggedInNotifier.value = true;
      appLogger.i('CurrentUserProvider: user set → id=${user.id} role=${user.role} phoneVerified=${user.phoneVerified}');
      notifyListeners();
    }
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
