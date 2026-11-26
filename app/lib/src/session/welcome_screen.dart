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
  // The hero's layout in the design's 390 × 330 frame.
  static const _heroCanvas = Size(390, 330);

  List<CesHangingTile> _tags(AppLocalizations l10n) => [
    CesHangingTile(
      left: 20,
      top: 92,
      degrees: 7,
      tile: CesItemTile(name: l10n.welcomeSampleOranges, icon: CesIcons.orange, quantity: '6'),
    ),
    CesHangingTile(
      left: 142,
      top: 40,
      degrees: -4,
      tile: CesItemTile(name: l10n.welcomeSampleBread, icon: CesIcons.bread),
    ),
    CesHangingTile(
      left: 262,
      top: 104,
      degrees: 4,
      tile: CesItemTile(name: l10n.welcomeSampleCoffee, icon: CesIcons.coffee, quantity: '500 g'),
    ),
    CesHangingTile(
      left: 72,
      top: 214,
      degrees: -6,
      tile: CesItemTile(name: l10n.welcomeSampleEggs, icon: CesIcons.egg, quantity: '12'),
    ),
    CesHangingTile(
      left: 204,
      top: 226,
      degrees: 5,
      tile: CesItemTile(name: l10n.welcomeSampleCheese, icon: CesIcons.cheese),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesBrandScaffold(
      body: CesPinnedLayout(
        top: [
          CesHangingTiles(canvas: _heroCanvas, tiles: _tags(l10n)),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CesWordmark(name: l10n.appTitle, large: true),
                const CesGap.md(),
                CesDisplayHeading(l10n.welcomeHeadline, large: true),
                const CesGap.md(),
                CesText.intro(l10n.welcomeSubtitle),
              ],
            ),
          ),
        ],
        bottom: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error case final error?) ...[
                  CesMessage(tone: CesMessageTone.error, text: error),
                  const CesGap.md(),
                ],
                CesButton.secondary(
                  label: l10n.welcomeContinueWithGoogle,
                  icon: CesIcons.google,
                  busy: busy,
                  onPressed: () => submitAuth(widget.auth.signInWithGoogle),
                ),
                const SizedBox(height: 12),
                CesButton.outline(
                  label: l10n.welcomeContinueWithEmail,
                  icon: CesIcons.email,
                  onPressed: busy ? null : () => context.push(Routes.signUp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
