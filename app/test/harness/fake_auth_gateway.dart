import 'dart:async';

import 'package:cesta/src/auth/auth_gateway.dart';

/// What the Google account picker returns in tests.
final class FakeGoogleAccount {
  const FakeGoogleAccount({required this.email, required this.name});

  final String email;
  final String name;
}

/// A known account at the fake identity provider.
final class FakeIdentity {
  FakeIdentity({required this.uid, required this.email, this.password, this.name});

  final String uid;
  final String email;
  final String? password;

  /// The name the provider knows (from Google); null for email sign-ups.
  final String? name;
}

/// Seam 2 fake for the identity provider (Firebase Auth). Its session
/// persists across app restarts within a test, as Firebase's does on a phone.
class FakeAuthGateway implements AuthGateway {
  final _identities = <String, FakeIdentity>{}; // by email
  final _changes = StreamController<AuthSession?>.broadcast();
  FakeIdentity? _current;
  int _nextUid = 1;

  /// The account the Google picker returns; null means the User backs out.
  FakeGoogleAccount? googleAccount;

  /// When true, every call fails as if the network were down.
  bool offline = false;

  int signInAttempts = 0;
  int signUpAttempts = 0;
  final passwordResetsSentTo = <String>[];

  FakeIdentity? get current => _current;

  /// Registers an account, optionally signed in already (as after a past launch).
  FakeIdentity addIdentity({required String email, String? password, String? name, bool signedIn = false}) {
    final identity = FakeIdentity(uid: 'uid-${_nextUid++}', email: email, password: password, name: name);
    _identities[email] = identity;
    if (signedIn) _current = identity;
    return identity;
  }

  @override
  Stream<AuthSession?> sessionChanges() async* {
    yield _session(_current);
    yield* _changes.stream;
  }

  @override
  Future<void> signUpWithEmail({required String email, required String password}) async {
    signUpAttempts++;
    _failIfOffline();
    if (_identities.containsKey(email)) throw const AuthFailure(AuthFailureCode.emailInUse);
    _signIn(addIdentity(email: email, password: password));
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    signInAttempts++;
    _failIfOffline();
    final identity = _identities[email];
    if (identity == null || identity.password != password) {
      throw const AuthFailure(AuthFailureCode.wrongCredentials);
    }
    _signIn(identity);
  }

  @override
  Future<void> signInWithGoogle() async {
    _failIfOffline();
    final account = googleAccount;
    if (account == null) throw const AuthFailure(AuthFailureCode.cancelled);
    _signIn(_identities[account.email] ?? addIdentity(email: account.email, name: account.name));
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _failIfOffline();
    passwordResetsSentTo.add(email);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => _current == null ? null : 'token-${_current!.uid}';

  void _signIn(FakeIdentity identity) {
    _current = identity;
    _changes.add(_session(identity));
  }

  void _failIfOffline() {
    if (offline) throw const AuthFailure(AuthFailureCode.offline);
  }

  static AuthSession? _session(FakeIdentity? i) => i == null ? null : AuthSession(uid: i.uid, email: i.email);
}
