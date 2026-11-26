import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_gateway.dart';
import '../ui/components.dart';
import 'auth_messages.dart';

enum EmailAuthMode { signIn, signUp }

/// Email + password sign-in or sign-up. On success the router moves on by
/// itself, because the session changes.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key, required this.auth, required this.mode});

  final AuthGateway auth;
  final EmailAuthMode mode;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _signUp => widget.mode == EmailAuthMode.signUp;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    String? error;
    try {
      final email = _email.text.trim();
      if (_signUp) {
        await widget.auth.signUpWithEmail(email: email, password: _password.text);
      } else {
        await widget.auth.signInWithEmail(email: email, password: _password.text);
      }
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
    final title = _signUp ? l10n.signUpTitle : l10n.signInTitle;
    return CesScaffold(
      title: title,
      body: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?) ...[CesMessage(tone: CesMessageTone.error, text: error), const CesGap.lg()],
              CesTextField(
                label: l10n.fieldEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (v) => validateEmail(l10n, v),
              ),
              const CesGap.md(),
              CesPasswordField(
                label: l10n.fieldPassword,
                showLabel: l10n.fieldPasswordShow,
                hideLabel: l10n.fieldPasswordHide,
                controller: _password,
                newPassword: _signUp,
                helper: _signUp ? l10n.fieldPasswordHint : null,
                validator: (v) => _signUp ? validateNewPassword(l10n, v) : validateSignInPassword(l10n, v),
                onSubmitted: (_) => _submit(),
              ),
              if (!_signUp)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: CesLink(
                    label: l10n.signInForgotPassword,
                    onPressed: _busy ? null : () => context.push('/reset-password', extra: _email.text.trim()),
                  ),
                )
              else
                const CesGap.lg(),
              const CesGap.md(),
              CesButton(label: _signUp ? l10n.signUpButton : l10n.signInButton, busy: _busy, onPressed: _submit),
              const CesGap.md(),
              CesLink(
                label: _signUp ? l10n.signUpHaveAccount : l10n.signInNoAccount,
                onPressed: _busy ? null : () => context.pushReplacement(_signUp ? '/sign-in' : '/sign-up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
