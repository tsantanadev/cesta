import '../../l10n/app_localizations.dart';
import '../names.dart';
import 'lists_controller.dart';

/// What to tell the User when a change to their Lists didn't go through.
String listFailureMessage(AppLocalizations l10n, ListFailure failure) => switch (failure) {
  ListFailure.invalidName => l10n.errorListNameInvalid,
  ListFailure.limitReached => l10n.errorListLimit(maxListsPerUser),
  ListFailure.notFound => l10n.errorListNotFound,
  ListFailure.deleted => l10n.errorListDeleted,
  ListFailure.notRestorable => l10n.errorListNotRestorable,
  ListFailure.rateLimited => l10n.errorTooManyAttempts,
  ListFailure.offline => l10n.errorOffline,
  ListFailure.failed => l10n.errorUnknown,
};

String? validateListName(AppLocalizations l10n, String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return l10n.errorListNameRequired;
  if (name.runes.length > maxListNameLength) return l10n.errorListNameTooLong(maxListNameLength);
  if (controlCharacters.hasMatch(name)) return l10n.errorListNameInvalid;
  return null;
}
