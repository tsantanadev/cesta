/// The app's view of the identity provider (Firebase Auth, ADR-0003).
///
/// Screens and the session talk to this interface only, so Seam 2 tests
/// can swap in a fake ([FirebaseAuthGateway] is the real one).
abstract interface class AuthGateway {
  /// The signed-in session now and after every change, starting with the
  /// current one (null when signed out). Sessions persist across app launches.
  Stream<AuthSession?> sessionChanges();

  /// Creates an email + password account and signs in to it.
  Future<void> signUpWithEmail({required String email, required String password});

  Future<void> signInWithEmail({required String email, required String password});

  /// Signs in with Google, creating the account on first use. Throws an
  /// [AuthFailure] with [AuthFailureCode.cancelled] if the User backs out.
  Future<void> signInWithGoogle();

  /// Sends a password reset email. Succeeds whether or not the account exists,
  /// so the app never reveals which emails have accounts.
  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();

  /// The current ID token for API calls, refreshed when [forceRefresh] is set
  /// or it is about to expire; null when signed out.
  Future<String?> idToken({bool forceRefresh = false});
}

/// A signed-in identity at the provider.
final class AuthSession {
  const AuthSession({required this.uid, required this.email});

  /// The provider's user ID. Only used to tell accounts apart on this device.
  final String uid;
  final String? email;
}

enum AuthFailureCode {
  cancelled,
  invalidEmail,
  wrongCredentials,
  emailInUse,
  weakPassword,
  otherSignInMethod,
  userDisabled,
  tooManyAttempts,
  offline,
  unknown,
}

/// Why an [AuthGateway] call failed.
final class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.detail]);

  final AuthFailureCode code;

  /// Provider detail for debugging; never shown to the User.
  final String? detail;

  @override
  String toString() => 'AuthFailure(${code.name}${detail == null ? '' : ': $detail'})';
}
