import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import 'input_rules.dart';

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

// Form validators: the message for what input_rules.dart rejects.

String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.errorEmailRequired;
  if (!looksLikeEmail(email)) return l10n.errorEmailInvalid;
  return null;
}

String? validateSignInPassword(AppLocalizations l10n, String? value) =>
    (value ?? '').isEmpty ? l10n.errorPasswordRequired : null;

String? validateNewPassword(AppLocalizations l10n, String? value) =>
    (value ?? '').length < minPasswordLength ? l10n.errorPasswordTooShort : null;

String? validateDisplayName(AppLocalizations l10n, String? value) => switch (checkDisplayName(value ?? '')) {
  null => null,
  NameProblem.blank => l10n.errorDisplayNameRequired,
  NameProblem.tooLong => l10n.errorDisplayNameTooLong,
  NameProblem.invalidCharacters => l10n.errorDisplayNameInvalid,
};
