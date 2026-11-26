import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'session_controller.dart';

/// Shown while the stored session or a newly signed-in User is loading. If the
/// User can't be loaded (and nothing is stored on the device), it says why and
/// offers to try again or sign out.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final failure = session.userLoadFailure;
        return CesScaffold.bare(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: CesWordmark(name: l10n.appTitle, large: true)),
              const CesGap.xl(),
              if (failure == null)
                CesProgress(label: l10n.loading)
              else ...[
                CesMessage(
                  tone: CesMessageTone.error,
                  text: switch (failure) {
                    UserLoadFailure.offline => l10n.errorOffline,
                    UserLoadFailure.rateLimited => l10n.errorTooManyAttempts,
                    UserLoadFailure.failed => l10n.userLoadFailed,
                  },
                ),
                const CesGap.lg(),
                CesButton(label: l10n.userLoadRetry, onPressed: session.retryUserLoad),
                const CesGap.sm(),
                CesLink(label: l10n.userMenuSignOut, onPressed: session.signOut),
              ],
            ],
          ),
        );
      },
    );
  }
}
