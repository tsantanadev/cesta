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
/// card with Invite by email, then the List's open Invitations (pending, or
/// expired without an answer, so the Owner sees who never joined), which the
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
  /// The open Invitations; null while loading or when loading failed
  /// ([_failure] says why).
  List<Invitation>? _open;
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
    final result = await widget.sharing.openFor(widget.listId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case InvitationDone(value: final open):
          _open = open;
          _failure = null;
        case final InvitationFailure failure:
          _failure = failure;
      }
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
    switch (await widget.sharing.invite(widget.listId, email, language: language)) {
      case InvitationDone(value: final invitation):
        if (mounted) {
          setState(() => _open = [invitation, ...?_open]);
          showCesToast(context, message: AppLocalizations.of(context).shareInvitationSent(invitation.email));
        }
        return null;
      case final InvitationFailure failure:
        return failure;
    }
  }

  Future<void> _cancel(Invitation invitation) async {
    setState(() => _cancelling = invitation.id);
    final failure = await widget.sharing.cancel(invitation);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _cancelling = null;
      // Accepted or declined meanwhile: it isn't open any more either way.
      if (failure == null || failure is InvitationUnanswerable) {
        _open = _open?.where((i) => i.id != invitation.id).toList();
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
    final open = _open;
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
              if (_failure case final failure? when open == null)
                CesMessage(tone: CesMessageTone.error, text: invitationFailureMessage(l10n, failure))
              else if (open == null)
                CesProgress(label: l10n.loading)
              else if (open.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: CesSectionHeading(l10n.sharePendingHeading),
                ),
                for (final invitation in open)
                  CesPersonRow(
                    key: ValueKey(invitation.id),
                    icon: CesIcons.envelope,
                    label: invitation.email,
                    detail: invitation.status == InvitationStatus.expired ? l10n.shareInvitationExpired : null,
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
