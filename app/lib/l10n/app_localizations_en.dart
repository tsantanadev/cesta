// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cesta';

  @override
  String get healthTitle => 'Server status';

  @override
  String get healthChecking => 'Checking the server…';

  @override
  String get healthServerUp => 'Server is up';

  @override
  String get healthServerDegraded => 'Server is degraded';

  @override
  String get healthDatabaseUp => 'Database: connected';

  @override
  String get healthDatabaseDown => 'Database: unreachable';

  @override
  String get healthOffline => 'You\'re offline';

  @override
  String get healthOfflineNoData => 'Couldn\'t reach the server.';

  @override
  String get healthLastKnown => 'Last known status';

  @override
  String get healthCheckFailed => 'Couldn\'t check the server status.';

  @override
  String get healthRetry => 'Check again';

  @override
  String get welcomeTagline => 'Shared shopping lists that work in the store, with or without signal.';

  @override
  String get welcomeContinueWithGoogle => 'Continue with Google';

  @override
  String get welcomeContinueWithEmail => 'Continue with email';

  @override
  String get welcomeHaveAccount => 'Already have an account? Sign in';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInForgotPassword => 'Forgot password?';

  @override
  String get signInNoAccount => 'New here? Create an account';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpHaveAccount => 'Already have an account? Sign in';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordShow => 'Show password';

  @override
  String get fieldPasswordHide => 'Hide password';

  @override
  String get fieldPasswordHint => 'At least 8 characters';

  @override
  String get errorEmailRequired => 'Enter your email address.';

  @override
  String get errorEmailInvalid => 'Enter a valid email address.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get errorWrongCredentials => 'Wrong email or password.';

  @override
  String get errorEmailInUse => 'An account with this email already exists. Sign in instead.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorOffline => 'You\'re offline. Connect to the internet and try again.';

  @override
  String get errorTooManyAttempts => 'Too many attempts. Wait a moment and try again.';

  @override
  String get errorAccountDisabled => 'This account has been disabled.';

  @override
  String get errorOtherSignInMethod =>
      'This email is already used with another sign-in method. Sign in that way instead.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetExplanation =>
      'Enter the email you signed up with and we\'ll send you a link to choose a new password.';

  @override
  String get resetButton => 'Send reset link';

  @override
  String resetSent(String email) {
    return 'If an account exists for $email, we sent it a link to reset the password.';
  }

  @override
  String get resetBackToSignIn => 'Back to sign in';

  @override
  String get displayNameOnboardingTitle => 'What should we call you?';

  @override
  String get displayNameExplanation => 'Other Members of your Lists see this name.';

  @override
  String get displayNameEditTitle => 'Display name';

  @override
  String get fieldDisplayName => 'Display name';

  @override
  String get displayNameContinue => 'Continue';

  @override
  String get displayNameSave => 'Save';

  @override
  String get errorDisplayNameRequired => 'Enter a name.';

  @override
  String get errorDisplayNameTooLong => 'Use 50 characters or fewer.';

  @override
  String get errorDisplayNameInvalid => 'That name can\'t be used. Try another.';

  @override
  String get homeTitle => 'Your Lists';

  @override
  String get homeEmptyTitle => 'No Lists yet';

  @override
  String get homeEmptyBody => 'Lists you create or are invited to will show up here.';

  @override
  String get userMenu => 'Account';

  @override
  String get userMenuChangeDisplayName => 'Change display name';

  @override
  String get userMenuServerStatus => 'Server status';

  @override
  String get userMenuSignOut => 'Sign out';

  @override
  String get loading => 'Loading…';
}
