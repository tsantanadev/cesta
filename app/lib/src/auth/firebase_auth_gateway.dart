import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_gateway.dart';

/// [AuthGateway] backed by Firebase Auth, with Google sign-in through the
/// google_sign_in plugin. Firebase persists the session on the device.
class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance {
    // Password reset emails follow the phone's language.
    unawaited(_auth.setLanguageCode(null));
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  @override
  Stream<AuthSession?> sessionChanges() =>
      _auth.authStateChanges().map((u) => u == null ? null : AuthSession(uid: u.uid, email: u.email));

  @override
  Future<void> signUpWithEmail({required String email, required String password}) =>
      _guard(() => _auth.createUserWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> signInWithEmail({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount account;
    try {
      await (_googleReady ??= _google.initialize());
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled => AuthFailure(AuthFailureCode.cancelled, e.description),
        _ => AuthFailure(AuthFailureCode.unknown, '${e.code.name}: ${e.description}'),
      };
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthFailure(AuthFailureCode.unknown, 'Google returned no ID token');
    await _guard(() => _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken)));
  }

  @override
  Future<void> sendPasswordReset({required String email}) => _guard(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists for this email.
      if (e.code != 'user-not-found') rethrow;
    }
  });

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Forget the Google account too, so the next sign-in can pick another.
    // After a restart google_sign_in isn't initialized yet, so do that first.
    try {
      await (_googleReady ??= _google.initialize());
      await _google.signOut();
    } on GoogleSignInException {
      // Signed out of Cesta already; Google only remembers which account to suggest.
    }
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async => _auth.currentUser?.getIdToken(forceRefresh);

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_code(e.code), e.code);
    }
  }

  static AuthFailureCode _code(String firebaseCode) => switch (firebaseCode) {
    'invalid-email' => AuthFailureCode.invalidEmail,
    'invalid-credential' || 'wrong-password' || 'user-not-found' => AuthFailureCode.wrongCredentials,
    'email-already-in-use' => AuthFailureCode.emailInUse,
    'weak-password' => AuthFailureCode.weakPassword,
    'account-exists-with-different-credential' => AuthFailureCode.otherSignInMethod,
    'user-disabled' => AuthFailureCode.userDisabled,
    'too-many-requests' => AuthFailureCode.tooManyAttempts,
    'network-request-failed' => AuthFailureCode.offline,
    _ => AuthFailureCode.unknown,
  };
}
