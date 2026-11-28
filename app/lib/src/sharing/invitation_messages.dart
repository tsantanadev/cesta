import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import 'sharing.dart';

/// What to tell the User when something about an Invitation didn't go through.
String invitationFailureMessage(AppLocalizations l10n, InvitationFailure failure) => switch (failure) {
  InvitationInvalidEmail() => l10n.errorEmailInvalid,
  InvitationLimitReached(:final limit?) => l10n.errorInvitationLimit(limit),
  InvitationLimitReached(limit: null) => l10n.errorInvitationLimitGeneric,
  InvitationListGone() => l10n.errorListNotFound,
  InvitationNoLongerValid(:final reason) => switch (reason) {
    ApiErrorCode.invitationAccepted => l10n.errorInvitationAccepted,
    ApiErrorCode.invitationDeclined => l10n.errorInvitationDeclined,
    _ => l10n.errorInvitationGone,
  },
  InvitationRateLimited() => l10n.errorTooManyAttempts,
  InvitationOffline() => l10n.errorOffline,
  InvitationFailed() => l10n.errorUnknown,
};
