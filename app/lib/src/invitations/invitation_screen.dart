import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../lists/lists_controller.dart';
import '../routes.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';
import 'invitation_link.dart';

/// Where an Invitation's deep link lands: who invited the User to which List,
/// to accept (becoming an Editor and opening the List) or decline. An
/// Invitation that can no longer be accepted says why.
///
/// Provisional UI from existing components until the design gap is closed (#44).
class InvitationScreen extends StatefulWidget {
  InvitationScreen({
    super.key,
    required String token,
    required this.session,
    required ListsController lists,
    required ApiClient api,
  }) : link = InvitationLink(token: token, api: api, lists: lists);

  final InvitationLink link;
  final SessionController session;

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  Invitation? _invitation;

  /// Why the Invitation couldn't be loaded, or can't be answered.
  InvitationProblem? _problem;
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
      _problem = null;
    });
    final (invitation, problem) = await widget.link.lookup();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invitation = invitation;
      _problem = problem ?? (invitation == null ? null : InvitationLink.closed(invitation.status));
    });
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _problem = null;
    });
    final (list, problem) = await widget.link.accept();
    if (!mounted) return;
    setState(() {
      _accepting = false;
      _problem = problem;
    });
    if (list != null) context.go(Routes.list(list.id));
  }

  Future<void> _decline() async {
    setState(() {
      _declining = true;
      _problem = null;
    });
    final problem = await widget.link.decline();
    if (!mounted) return;
    setState(() {
      _declining = false;
      _problem = problem;
    });
    if (problem == null) {
      showCesToast(context, message: AppLocalizations.of(context).invitationDeclinedToast);
      context.go(Routes.home);
    }
  }

  /// Whether [problem] means the Invitation can't be answered any more, as
  /// opposed to a failure worth trying again.
  static bool _final(InvitationProblem problem) => switch (problem) {
    InvitationProblem.offline || InvitationProblem.rateLimited || InvitationProblem.failed => false,
    _ => true,
  };

  static String _message(AppLocalizations l10n, InvitationProblem problem) => switch (problem) {
    InvitationProblem.notFound => l10n.invitationNotFound,
    InvitationProblem.accepted => l10n.invitationAlreadyAccepted,
    InvitationProblem.declined => l10n.invitationAlreadyDeclined,
    InvitationProblem.cancelled => l10n.invitationCancelled,
    InvitationProblem.expired => l10n.invitationExpired,
    InvitationProblem.listDeleted => l10n.invitationListDeleted,
    InvitationProblem.listFull => l10n.invitationListFull,
    InvitationProblem.rateLimited => l10n.errorTooManyAttempts,
    InvitationProblem.offline => l10n.errorOffline,
    InvitationProblem.failed => l10n.errorUnknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final invitation = _invitation;
    final problem = _problem;
    final answerable = invitation != null && (problem == null || !_final(problem));
    final me = widget.session.user?.email;
    return CesFormScaffold(
      title: l10n.invitationTitle,
      top: [
        if (invitation != null) ...[
          CesDisplayHeading(l10n.invitationHeading(invitation.invitedBy.displayName, invitation.listName)),
          const CesGap.md(),
          if (answerable) ...[
            CesText.intro(l10n.invitationExplanation),
            if (me != null && me.toLowerCase() != invitation.email.toLowerCase()) ...[
              const CesGap.md(),
              CesText(l10n.invitationSentTo(invitation.email, me)),
            ],
            const CesGap.lg(),
          ],
        ],
        if (_loading)
          CesProgress(label: l10n.loading)
        else if (problem != null)
          CesMessage(tone: _final(problem) ? CesMessageTone.info : CesMessageTone.error, text: _message(l10n, problem)),
      ],
      bottom: [
        if (answerable) ...[
          CesButton(
            label: l10n.invitationAccept,
            busy: _accepting,
            onPressed: _busy ? null : () => unawaited(_accept()),
          ),
          const CesGap.sm(),
          CesButton.secondary(
            label: l10n.invitationDecline,
            busy: _declining,
            onPressed: _busy ? null : () => unawaited(_decline()),
          ),
        ] else if (!_loading && invitation == null && problem != null && !_final(problem)) ...[
          CesButton(label: l10n.userLoadRetry, onPressed: () => unawaited(_load())),
          const CesGap.sm(),
          CesLink(label: l10n.invitationGoToLists, onPressed: () => context.go(Routes.home)),
        ] else if (!_loading)
          CesButton(label: l10n.invitationGoToLists, onPressed: () => context.go(Routes.home)),
      ],
    );
  }
}
