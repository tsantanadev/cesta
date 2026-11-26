import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'auth_messages.dart';
import 'session_controller.dart';

/// Sets the display name: once after sign-up ([onboarding]), prefilled with
/// the server's suggestion, and later from the User menu.
class DisplayNameScreen extends StatefulWidget {
  const DisplayNameScreen({super.key, required this.session, required this.onboarding});

  final SessionController session;
  final bool onboarding;

  @override
  State<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends State<DisplayNameScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.session.user?.displayName ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final outcome = await widget.session.setDisplayName(_name.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (outcome) {
        DisplayNameOutcome.saved => null,
        DisplayNameOutcome.invalid => l10n.errorDisplayNameInvalid,
        DisplayNameOutcome.rateLimited => l10n.errorTooManyAttempts,
        DisplayNameOutcome.offline => l10n.errorOffline,
        DisplayNameOutcome.failed => l10n.errorUnknown,
      };
    });
    // During onboarding the router moves on once the name is confirmed.
    if (outcome == DisplayNameOutcome.saved && !widget.onboarding) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onboarding) ...[
            const CesGap.lg(),
            CesHeading(title: l10n.displayNameOnboardingTitle, subtitle: l10n.displayNameExplanation),
          ] else
            CesText(l10n.displayNameExplanation),
          const CesGap.lg(),
          if (_error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.md()],
          CesTextField(
            label: l10n.fieldDisplayName,
            controller: _name,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) => validateDisplayName(l10n, v),
          ),
          const CesGap.lg(),
          CesButton(
            label: widget.onboarding ? l10n.displayNameContinue : l10n.displayNameSave,
            busy: _busy,
            onPressed: _submit,
          ),
          // A new User must be able to leave without confirming, e.g. offline.
          if (widget.onboarding) ...[
            const CesGap.sm(),
            CesLink(label: l10n.userMenuSignOut, onPressed: _busy ? null : widget.session.signOut),
          ],
        ],
      ),
    );
    return widget.onboarding ? CesScaffold.bare(body: form) : CesScaffold(title: l10n.displayNameEditTitle, body: form);
  }
}
