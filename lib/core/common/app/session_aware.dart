import 'package:flutter/foundation.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';

/// For app-wide view models holding per-account data (cart, orders, …):
/// calls [onSignedIn] / [onSignedOut] when the session starts or ends, so a
/// logout drops the previous account's data instead of showing it to a
/// guest or to the next account that signs in.
///
/// Call [bindSession] from the constructor.
mixin SessionAware on ChangeNotifier {
  VoidCallback? _stopListening;

  void bindSession(CurrentUserProvider session) {
    _stopListening = session.addSignInListener((signedIn) {
      if (signedIn) {
        onSignedIn();
      } else {
        onSignedOut();
      }
    });
  }

  /// A session just started (login, signup).
  @protected
  void onSignedIn() {}

  /// The session just ended (logout, account deletion, expired token).
  @protected
  void onSignedOut() {}

  @override
  void dispose() {
    _stopListening?.call();
    super.dispose();
  }
}
