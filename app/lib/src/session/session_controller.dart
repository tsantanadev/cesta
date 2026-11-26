import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../api/generated/cesta_api.dart';
import '../api/network.dart';
import '../auth/auth_gateway.dart';
import '../db/app_database.dart';

enum SessionStatus {
  /// Waiting for the identity provider to report the stored session.
  starting,
  signedOut,
  signedIn,
}

/// Result of [SessionController.setDisplayName].
enum DisplayNameOutcome { saved, invalid, rateLimited, offline, failed }

/// Why the signed-in User couldn't be loaded when nothing was cached.
enum UserLoadFailure { offline, rateLimited, failed }

/// The identity provider's session and the signed-in User, which the router
/// follows.
///
/// The User (display name and so on) comes from the API and is cached on the
/// device, so a signed-in User reopening the app offline still sees it.
class SessionController extends ChangeNotifier {
  SessionController({required this._auth, required this._api, required this._db});

  final AuthGateway _auth;
  final ApiClient _api;
  final AppDatabase _db;
  StreamSubscription<AuthSession?>? _sessions;

  SessionStatus get status => _status;
  SessionStatus _status = SessionStatus.starting;

  /// The signed-in User, from the server or the device cache; null until known.
  User? get user => _user;
  User? _user;

  /// True while the first load of the User for a session with nothing cached is in flight.
  bool get loadingUser => _loadingUser;
  bool _loadingUser = false;

  /// Why that first load failed; null while it hasn't, or once a User is known.
  /// Without a User the app can't go on, so it offers [retryUserLoad] and sign-out.
  UserLoadFailure? get userLoadFailure => _userLoadFailure;
  UserLoadFailure? _userLoadFailure;

  AuthSession? _session;

  /// Starts following the identity provider's session.
  void start() {
    _sessions ??= _auth.sessionChanges().listen((s) => unawaited(_onSession(s)));
  }

  Future<void> _onSession(AuthSession? session) async {
    if (session?.uid == _session?.uid && _status != SessionStatus.starting) return;
    _session = session;
    _userLoadFailure = null;
    if (session == null) {
      _user = null;
      _loadingUser = false;
      _status = SessionStatus.signedOut;
      notifyListeners();
      await _db.clearSignedInUser();
      await _db.clearKnownLists();
      return;
    }

    final cached = await _db.readSignedInUser();
    if (_session?.uid != session.uid) return; // the session changed meanwhile
    if (cached != null && cached.authUid == session.uid) {
      _user = cached.user;
    } else {
      _user = null;
      if (cached != null) {
        await _db.clearSignedInUser();
        await _db.clearKnownLists(); // another User's Lists
      }
    }
    _loadingUser = _user == null;
    _status = SessionStatus.signedIn;
    notifyListeners();
    await refreshUser();
  }

  /// Reloads the User from the server. If that fails the cached User stays;
  /// with none cached, [userLoadFailure] says why.
  Future<void> refreshUser() async {
    final session = _session;
    if (session == null) return;
    UserLoadFailure? failure;
    try {
      switch (await _api.getMe()) {
        case GetMe200(:final value):
          await _keep(session, value);
        case GetMe429():
          failure = UserLoadFailure.rateLimited;
        case GetMe401():
          failure = UserLoadFailure.failed;
      }
    } on DioException catch (e) {
      failure = isOffline(e) ? UserLoadFailure.offline : UserLoadFailure.failed;
    }
    if (_session?.uid != session.uid) return;
    final unavailable = _user == null ? failure : null;
    if (_loadingUser || unavailable != _userLoadFailure) {
      _loadingUser = false;
      _userLoadFailure = unavailable;
      notifyListeners();
    }
  }

  /// Tries loading the User again after [userLoadFailure].
  Future<void> retryUserLoad() async {
    if (_session == null) return;
    _loadingUser = true;
    _userLoadFailure = null;
    notifyListeners();
    await refreshUser();
  }

  /// Sets and confirms the display name. [name] should already be validated.
  Future<DisplayNameOutcome> setDisplayName(String name) async {
    final session = _session;
    if (session == null) return DisplayNameOutcome.failed;
    try {
      return switch (await _api.updateMe(body: UserUpdate(displayName: name))) {
        UpdateMe200(:final value) => await _keep(session, value).then((_) => DisplayNameOutcome.saved),
        UpdateMe400() => DisplayNameOutcome.invalid,
        UpdateMe429() => DisplayNameOutcome.rateLimited,
        UpdateMe401() => DisplayNameOutcome.failed,
      };
    } on DioException catch (e) {
      return isOffline(e) ? DisplayNameOutcome.offline : DisplayNameOutcome.failed;
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _keep(AuthSession session, User user) async {
    if (_session?.uid != session.uid) return;
    await _db.saveSignedInUser(CachedUser(authUid: session.uid, user: user));
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_sessions?.cancel());
    super.dispose();
  }
}
