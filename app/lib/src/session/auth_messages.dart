import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../names.dart';

/// The message shown for a failed sign-in, sign-up or reset. Null for failures
/// the User caused on purpose (backing out of the Google picker).
String? authFailureMessage(AppLocalizations l10n, AuthFailure failure) => switch (failure.code) {
  AuthFailureCode.cancelled => null,
  AuthFailureCode.invalidEmail => l10n.errorEmailInvalid,
  AuthFailureCode.wrongCredentials => l10n.errorWrongCredentials,
  AuthFailureCode.emailInUse => l10n.errorEmailInUse,
  AuthFailureCode.weakPassword => l10n.errorWeakPassword,
  AuthFailureCode.otherSignInMethod => l10n.errorOtherSignInMethod,
  AuthFailureCode.userDisabled => l10n.errorAccountDisabled,
  AuthFailureCode.tooManyAttempts => l10n.errorTooManyAttempts,
  AuthFailureCode.offline => l10n.errorOffline,
  AuthFailureCode.unknown => l10n.errorUnknown,
};

/// Shortest password accepted on sign-up. Firebase's own minimum is 6.
const minPasswordLength = 8;

/// Longest display name, matching the API contract.
const maxDisplayNameLength = 50;

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.errorEmailRequired;
  if (!_email.hasMatch(email)) return l10n.errorEmailInvalid;
  return null;
}

String? validateSignInPassword(AppLocalizations l10n, String? value) =>
    (value ?? '').isEmpty ? l10n.errorPasswordRequired : null;

String? validateNewPassword(AppLocalizations l10n, String? value) =>
    (value ?? '').length < minPasswordLength ? l10n.errorPasswordTooShort : null;

String? validateDisplayName(AppLocalizations l10n, String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return l10n.errorDisplayNameRequired;
  if (name.runes.length > maxDisplayNameLength) return l10n.errorDisplayNameTooLong;
  if (controlCharacters.hasMatch(name)) return l10n.errorDisplayNameInvalid;
  return null;
}
