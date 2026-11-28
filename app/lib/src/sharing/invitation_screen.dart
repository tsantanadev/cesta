import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../lists/lists_controller.dart';
import '../routes.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';
import 'invitation_messages.dart';
import 'sharing.dart';

/// Where an Invitation's deep link lands: who invited the User to which List,
/// to join (becoming an Editor and opening the List) or decline, whatever
/// email it was sent to. An Invitation that can no longer be accepted says why.
///
/// Provisional UI from existing components until the design gap is closed (#44).
class InvitationScreen extends StatefulWidget {
  const InvitationScreen({
    super.key,
    required this.token,
    required this.session,
    required this.lists,
    required this.sharing,
  });

  /// The token in the deep link.
  final String token;
  final SessionController session;
  final ListsController lists;
  final Sharing sharing;

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  Invitation? _invitation;

  /// Why the Invitation couldn't be loaded, or can't be answered.
  InvitationFailure? _failure;
  bool _loading = true;
  bool _accepting = false;
  bool _declining = false;

  bool get _busy => _accepting || _declining;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final (invitation, failure) = await widget.sharing.lookup(widget.token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invitation = invitation;
      _failure = failure ?? (invitation == null ? null : Sharing.closed(invitation));
    });
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _failure = null;
    });
    final (list, failure) = await widget.sharing.acceptLink(widget.token);
    if (list != null) await widget.lists.joined(list);
    if (!mounted) return;
    setState(() {
      _accepting = false;
      _failure = failure;
    });
    if (list != null) context.go(Routes.list(list.id));
  }

  Future<void> _decline(Invitation invitation) async {
    setState(() {
      _declining = true;
      _failure = null;
    });
    final failure = await widget.sharing.declineLink(widget.token);
    if (!mounted) return;
    setState(() {
      _declining = false;
      _failure = failure;
    });
    if (failure == null) {
      showCesToast(context, message: AppLocalizations.of(context).invitationDeclined(invitation.listName));
      context.go(Routes.home);
    }
  }

  /// Whether [failure] is worth trying again, as opposed to the Invitation
  /// (or its List) being beyond answering.
  static bool _retryable(InvitationFailure failure) =>
      failure is InvitationOffline || failure is InvitationRateLimited || failure is InvitationFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invitation = _invitation;
    final failure = _failure;
    final answerable = invitation != null && (failure == null || _retryable(failure));
    final me = widget.session.user?.email;
    void goToLists() => context.go(Routes.home);
    return CesFormScaffold(
      title: l10n.invitationTitle,
      top: [
        if (invitation != null) ...[
          CesDisplayHeading(l10n.invitationHeading(invitation.invitedBy.displayName, invitation.listName)),
          const CesGap.md(),
          if (answerable) ...[
            CesText.intro(l10n.invitationExplanation),
            if (me != null && canonicalEmail(me) != canonicalEmail(invitation.email)) ...[
              const CesGap.md(),
              CesText(l10n.invitationSentTo(invitation.email, me)),
            ],
            const CesGap.lg(),
          ],
        ],
        if (_loading)
          CesProgress(label: l10n.loading)
        else if (failure != null)
          CesMessage(
            tone: _retryable(failure) ? CesMessageTone.error : CesMessageTone.info,
            text: invitationFailureMessage(l10n, failure),
          ),
      ],
      bottom: [
        if (answerable) ...[
          CesButton(label: l10n.invitationJoin, busy: _accepting, onPressed: _busy ? null : () => unawaited(_accept())),
          const CesGap.sm(),
          CesButton.secondary(
            label: l10n.invitationDecline,
            busy: _declining,
            onPressed: _busy ? null : () => unawaited(_decline(invitation)),
          ),
        ] else if (!_loading && failure != null && _retryable(failure)) ...[
          CesButton(label: l10n.userLoadRetry, onPressed: () => unawaited(_load())),
          const CesGap.sm(),
          CesLink(label: l10n.invitationGoToLists, onPressed: goToLists),
        ] else if (!_loading)
          CesButton(label: l10n.invitationGoToLists, onPressed: goToLists),
      ],
    );
  }
}
