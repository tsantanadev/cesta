import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../routes.dart';
import '../ui/components.dart';
import 'auth_messages.dart';
import 'session_controller.dart';

/// Sets the display name (Figma "02 Your name"): once after sign-up
/// ([onboarding]), prefilled with the server's suggestion, and later from the
/// User menu. A tag previews the name as it is typed.
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

  // The preview tag's place in the design's 342 × 196 frame.
  static const _previewCanvas = Size(342, 196);

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
    if (outcome == DisplayNameOutcome.saved && !widget.onboarding) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: CesFormScaffold(
        title: widget.onboarding ? null : l10n.displayNameEditTitle,
        top: [
          ValueListenableBuilder(
            valueListenable: _name,
            builder: (context, value, _) => CesHangingTiles(
              canvas: _previewCanvas,
              tiles: [
                CesHangingTile(
                  left: 97,
                  top: 44,
                  degrees: 3,
                  tile: CesItemTile(name: value.text.trim(), icon: CesIcons.basket, size: 148),
                ),
              ],
            ),
          ),
          const CesGap.lg(),
          if (widget.onboarding) ...[CesDisplayHeading(l10n.displayNameOnboardingTitle), const SizedBox(height: 10)],
          CesText.intro(l10n.displayNameExplanation),
          const CesGap.lg(),
          if (_error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.md()],
          CesTextField.display(
            label: l10n.fieldDisplayName,
            controller: _name,
            autofillHints: const [AutofillHints.name],
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) => validateDisplayName(l10n, v),
          ),
          const CesGap.lg(),
        ],
        bottom: [
          CesButton(
            label: widget.onboarding ? l10n.displayNameContinue : l10n.displayNameSave,
            busy: _busy,
            onPressed: _submit,
          ),
          // A new User must be able to leave without confirming, e.g. offline.
          if (widget.onboarding) ...[
            const CesGap.md(),
            CesLink(label: l10n.userMenuSignOut, onPressed: _busy ? null : widget.session.signOut),
          ],
        ],
      ),
    );
  }
}
