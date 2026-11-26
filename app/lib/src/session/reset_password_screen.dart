import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../ui/components.dart';
import 'auth_messages.dart';
import 'auth_submission.dart';

/// Sends a password reset email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.auth, this.initialEmail = ''});

  final AuthGateway auth;
  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with AuthSubmission {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  String? _sentTo;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    clearError();
    if (!(_form.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    if (await submitAuth(() => widget.auth.sendPasswordReset(email: email)) && mounted) {
      setState(() => _sentTo = email);
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
              if (error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.lg()],
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
              CesButton(label: l10n.resetButton, busy: busy, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
