import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../routes.dart';
import '../ui/components.dart';
import 'auth_submission.dart';

/// First screen for a signed-out visitor (Figma "01 Welcome"): Google, or
/// email, which opens sign-up (from where the User can switch to sign-in).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with AuthSubmission {
  List<CesItemTile> _tiles(AppLocalizations l10n) => [
    CesItemTile(name: l10n.welcomeSampleOranges, icon: CesIcons.orange, quantity: '6'),
    CesItemTile(name: l10n.welcomeSampleBread, icon: CesIcons.bread),
    CesItemTile(name: l10n.welcomeSampleCoffee, icon: CesIcons.coffee, quantity: '500 g'),
    CesItemTile(name: l10n.welcomeSampleEggs, icon: CesIcons.egg, quantity: '12'),
    CesItemTile(name: l10n.welcomeSampleCheese, icon: CesIcons.cheese),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesBrandScaffold(
      hero: CesWelcomeHero(tiles: _tiles(l10n)),
      intro: [
        CesWordmark(name: l10n.appTitle, large: true),
        CesDisplayHeading(l10n.welcomeHeadline, large: true),
        CesText.intro(l10n.welcomeSubtitle),
      ],
      actions: [
        if (error case final error?) CesMessage(tone: CesMessageTone.error, text: error),
        CesButton.secondary(
          label: l10n.welcomeContinueWithGoogle,
          icon: CesIcons.google,
          busy: busy,
          onPressed: () => submitAuth(widget.auth.signInWithGoogle),
        ),
        CesButton.outline(
          label: l10n.welcomeContinueWithEmail,
          icon: CesIcons.email,
          onPressed: busy ? null : () => context.push(Routes.signUp),
        ),
      ],
    );
  }
}
