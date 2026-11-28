import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../lists/lists_controller.dart';
import '../ui/components.dart';
import 'invitation_messages.dart';
import 'invite_by_email_form.dart';
import 'sharing.dart';

/// Share list (Figma "06 Share list" 4:365), as far as Invitations go: the
/// card with Invite by email, then the List's pending Invitations, which the
/// Owner can cancel. The Share link, Share QR code and Members belong to
/// later tickets; the invite form and the pending Invitations are provisional
/// until their frames are designed (#44).
class ShareListScreen extends StatefulWidget {
  const ShareListScreen({super.key, required this.listId, required this.lists, required this.sharing});

  final String listId;
  final ListsController lists;
  final Sharing sharing;

  @override
  State<ShareListScreen> createState() => _ShareListScreenState();
}

class _ShareListScreenState extends State<ShareListScreen> {
  /// Null while loading or when loading failed ([_failure] says why).
  List<Invitation>? _pending;
  InvitationFailure? _failure;

  /// The Invitation being cancelled, if one is.
  String? _cancelling;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  ListSummary? get _list => widget.lists.lists.where((l) => l.id == widget.listId).firstOrNull;

  Future<void> _load() async {
    final (pending, failure) = await widget.sharing.pendingFor(widget.listId);
    if (!mounted) return;
    setState(() {
      _pending = pending ?? _pending;
      _failure = failure;
    });
  }

  void _invite() {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showCesFormSheet(
        context,
        title: l10n.shareInviteByEmail,
        closeTooltip: l10n.sheetClose,
        child: InviteByEmailForm(listName: _list?.name ?? '', onSubmit: _send),
      ),
    );
  }

  /// Sends the Invitation; once it went through, shows it as pending and says so.
  Future<InvitationFailure?> _send(String email) async {
    final language = invitationLanguage(Localizations.localeOf(context).languageCode);
    final (invitation, failure) = await widget.sharing.invite(widget.listId, email, language: language);
    if (invitation != null && mounted) {
      setState(() => _pending = [invitation, ...?_pending]);
      showCesToast(context, message: AppLocalizations.of(context).shareInvitationSent(invitation.email));
    }
    return failure;
  }

  Future<void> _cancel(Invitation invitation) async {
    setState(() => _cancelling = invitation.id);
    final failure = await widget.sharing.cancel(invitation);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _cancelling = null;
      // Accepted or declined meanwhile: it isn't pending any more either way.
      if (failure == null || failure is InvitationUnanswerable) {
        _pending = _pending?.where((i) => i.id != invitation.id).toList();
      }
    });
    showCesToast(
      context,
      message: failure == null
          ? l10n.shareInvitationCancelled(invitation.email)
          : invitationFailureMessage(l10n, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = _pending;
    return ListenableBuilder(
      listenable: widget.lists,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              CesCloseBar(title: l10n.shareTitle, onClose: () => context.pop()),
              CesShareCard(
                title: _list?.name ?? '',
                body: l10n.shareInviteExplanation,
                actions: [
                  CesButton.outline(label: l10n.shareInviteByEmail, icon: CesIcons.envelope, onPressed: _invite),
                ],
              ),
              const SizedBox(height: 24),
              if (_failure case final failure? when pending == null)
                CesMessage(tone: CesMessageTone.error, text: invitationFailureMessage(l10n, failure))
              else if (pending == null)
                CesProgress(label: l10n.loading)
              else if (pending.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: CesSectionHeading(l10n.sharePendingHeading),
                ),
                for (final invitation in pending)
                  CesPersonRow(
                    key: ValueKey(invitation.id),
                    icon: CesIcons.envelope,
                    label: invitation.email,
                    trailing: CesIconButton(
                      icon: CesIcons.close,
                      tooltip: l10n.shareCancelInvitation(invitation.email),
                      onPressed: _cancelling == null ? () => unawaited(_cancel(invitation)) : null,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
