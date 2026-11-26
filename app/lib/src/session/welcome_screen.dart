import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../ui/components.dart';
import 'auth_messages.dart';

/// First screen for a signed-out visitor: Google, or email sign-up / sign-in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _google() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      await widget.auth.signInWithGoogle();
    } on AuthFailure catch (e) {
      error = authFailureMessage(l10n, e);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesScaffold.bare(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CesGap.xl(),
          CesBrandMark(name: l10n.appTitle),
          const CesGap.md(),
          CesText.lead(l10n.welcomeTagline, textAlign: TextAlign.center),
          const CesGap.xl(),
          const CesGap.xl(),
          if (_error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.md()],
          CesButton(label: l10n.welcomeContinueWithGoogle, icon: CesIcons.google, busy: _busy, onPressed: _google),
          const CesGap.md(),
          CesButton.secondary(
            label: l10n.welcomeContinueWithEmail,
            icon: CesIcons.email,
            onPressed: _busy ? null : () => context.push('/sign-up'),
          ),
          const CesGap.sm(),
          CesLink(label: l10n.welcomeHaveAccount, onPressed: _busy ? null : () => context.push('/sign-in')),
        ],
      ),
    );
  }
}
