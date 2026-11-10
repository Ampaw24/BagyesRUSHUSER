import 'package:flutter/foundation.dart';

/// Drives GoRouter's `refreshListenable`, firing only when re-running the auth
/// redirect can change something.
///
/// `GoRouter.refresh()` rebuilds the whole stack from an encoded snapshot, and
/// in go_router 14.x every pushed page comes back with a fresh completer: the
/// pending `push<T>()` future never resolves and a later `pop()` is undone.
/// [source] (CurrentUserProvider) notifies on every profile merge and on
/// login — right before LoginView pops back to the screen that asked for
/// sign-in — so an unconditional refresh left users on the login screen after
/// a successful sign-in.
///
/// Sign-out always refreshes, so an expired or cleared session can never skip
/// its redirect to login.
class AuthRedirectRefresh extends ChangeNotifier {
  AuthRedirectRefresh({
    required Listenable source,
    required bool Function() isAuthenticated,
    required bool Function() wouldRedirect,
  })  : _source = source,
        _isAuthenticated = isAuthenticated,
        _wouldRedirect = wouldRedirect,
        _wasAuthenticated = isAuthenticated() {
    _source.addListener(_onSourceChanged);
  }

  final Listenable _source;
  final bool Function() _isAuthenticated;
  final bool Function() _wouldRedirect;
  bool _wasAuthenticated;

  void _onSourceChanged() {
    final authenticated = _isAuthenticated();
    final signedOut = _wasAuthenticated && !authenticated;
    _wasAuthenticated = authenticated;
    if (signedOut || _wouldRedirect()) notifyListeners();
  }

  @override
  void dispose() {
    _source.removeListener(_onSourceChanged);
    super.dispose();
  }
}
