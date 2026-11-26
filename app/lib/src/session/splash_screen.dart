import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';

/// Shown while the stored session or a new account is loading.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesScaffold.bare(
      body: Column(
        children: [
          CesBrandMark(name: l10n.appTitle),
          const CesGap.xl(),
          CesProgress(label: l10n.loading),
        ],
      ),
    );
  }
}
