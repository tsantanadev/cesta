import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../ui/components.dart';
import 'auth_messages.dart';

/// Sends a password reset email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.auth, this.initialEmail = ''});

  final AuthGateway auth;
  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _error;
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final email = _email.text.trim();
    String? error;
    String? sentTo;
    try {
      await widget.auth.sendPasswordReset(email: email);
      sentTo = email;
    } on AuthFailure catch (e) {
      error = authFailureMessage(l10n, e);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
        _sentTo = sentTo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesScaffold(
      title: l10n.resetTitle,
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CesText(l10n.resetExplanation),
            const CesGap.lg(),
            if (_sentTo case final sentTo?) ...[
              CesMessage(tone: CesMessageTone.info, text: l10n.resetSent(sentTo)),
              const CesGap.lg(),
              CesButton(label: l10n.resetBackToSignIn, onPressed: () => context.pop()),
            ] else ...[
              if (_error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.lg()],
              CesTextField(
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                validator: (v) => validateEmail(l10n, v),
              ),
              const CesGap.lg(),
              CesButton(label: l10n.resetButton, busy: _busy, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
