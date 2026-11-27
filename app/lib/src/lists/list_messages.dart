import '../../l10n/app_localizations.dart';
import '../names.dart';
import 'lists_controller.dart';

/// What to tell the User when a change to their Lists didn't go through.
String listFailureMessage(AppLocalizations l10n, ListFailure failure) => switch (failure) {
  ListInvalidName() => l10n.errorListNameInvalid,
  ListLimitReached(:final limit?) => l10n.errorListLimit(limit),
  ListLimitReached(limit: null) => l10n.errorListLimitGeneric,
  ListNotFound() => l10n.errorListNotFound,
  ListDeleted() => l10n.errorListDeleted,
  ListNotRestorable() => l10n.errorListNotRestorable,
  ListRateLimited() => l10n.errorTooManyAttempts,
  ListOffline() => l10n.errorOffline,
  ListFailed() => l10n.errorUnknown,
};

String? validateListName(AppLocalizations l10n, String? value) =>
    switch (checkName(value ?? '', maxLength: maxListNameLength)) {
      null => null,
      NameProblem.blank => l10n.errorListNameRequired,
      NameProblem.tooLong => l10n.errorListNameTooLong(maxListNameLength),
      NameProblem.invalidCharacters => l10n.errorListNameInvalid,
    };
