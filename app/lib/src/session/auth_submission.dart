import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import 'auth_messages.dart';

/// The busy and error state of a screen that calls the identity provider:
/// while [busy] its actions are disabled, and a failure leaves its message in
/// [error].
mixin AuthSubmission<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  /// Runs [action] as busy and reports whether it succeeded. An [AuthFailure]
  /// becomes [error] (none when the User backed out on purpose).
  Future<bool> submitAuth(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    String? failure;
    var succeeded = false;
    try {
      await action();
      succeeded = true;
    } on AuthFailure catch (e) {
      failure = authFailureMessage(l10n, e);
    }
    if (mounted) {
      setState(() {
        busy = false;
        error = failure;
      });
    }
    return succeeded;
  }

  /// Clears [error], e.g. before validating the form again.
  void clearError() => setState(() => error = null);
}
