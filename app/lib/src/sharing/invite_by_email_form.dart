import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../session/auth_messages.dart';
import '../ui/components.dart';
import 'invitation_messages.dart';
import 'sharing.dart';

/// The Invite by email sheet's contents (provisional until its frame is
/// designed, #44): what the invitee gets, the address, and Send invitation.
/// Closes its sheet once [onSubmit] succeeds; otherwise says why it didn't,
/// e.g. the daily limit of Invitations.
class InviteByEmailForm extends StatefulWidget {
  const InviteByEmailForm({super.key, required this.listName, required this.onSubmit});

  final String listName;

  /// Sends the Invitation; null when it went through.
  final Future<InvitationFailure?> Function(String email) onSubmit;

  @override
  State<InviteByEmailForm> createState() => _InviteByEmailFormState();
}

class _InviteByEmailFormState extends State<InviteByEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  InvitationFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await widget.onSubmit(_email.text.trim());
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CesSheetText(l10n.shareInviteFormExplanation(widget.listName)),
          const CesGap.md(),
          CesTextField(
            label: l10n.fieldEmail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            textInputAction: TextInputAction.send,
            validator: (value) => validateEmail(l10n, value),
            onSubmitted: (_) => _submit(),
          ),
          if (_failure case final failure?) ...[
            const CesGap.md(),
            CesMessage(tone: CesMessageTone.error, text: invitationFailureMessage(l10n, failure)),
          ],
          const CesGap.lg(),
          CesButton(label: l10n.shareSendInvitation, icon: CesIcons.email, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
