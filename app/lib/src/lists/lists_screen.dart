import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../routes.dart';
import '../session/session_controller.dart';
import '../sharing/invitation_messages.dart';
import '../sharing/sharing.dart';
import '../ui/components.dart';
import 'list_messages.dart';
import 'list_name_form.dart';
import 'lists_controller.dart';

/// Home: the Invitations addressed to the User, the Lists the User owns or
/// was shared, and the User menu.
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key, required this.session, required this.lists, required this.sharing});

  final SessionController session;
  final ListsController lists;
  final Sharing sharing;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  ListsController get _lists => widget.lists;

  /// The pending Invitations addressed to the User, newest first. They need
  /// the network, so offline there are none to show.
  List<Invitation> _invitations = const [];

  /// The Invitation being joined or declined, if one is.
  String? _answering;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    unawaited(_loadInvitations());
  }

  Future<void> _loadInvitations() async {
    final (invitations, _) = await widget.sharing.mine();
    if (!mounted || invitations == null) return;
    setState(() => _invitations = invitations);
  }

  /// Joins or declines [invitation] through [answer], then takes it off the
  /// screen unless that failed for a reason worth retrying.
  Future<void> _answer(Invitation invitation, Future<InvitationFailure?> Function() answer, String done) async {
    setState(() => _answering = invitation.id);
    final failure = await answer();
    if (!mounted) return;
    final retry = failure is InvitationOffline || failure is InvitationRateLimited || failure is InvitationFailed;
    setState(() {
      _answering = null;
      if (!retry) _invitations = _invitations.where((i) => i.id != invitation.id).toList();
    });
    showCesToast(
      context,
      message: failure == null ? done : invitationFailureMessage(AppLocalizations.of(context), failure),
    );
  }

  Future<void> _join(Invitation invitation) => _answer(invitation, () async {
    final (_, failure) = await widget.sharing.accept(invitation);
    if (failure == null) await _lists.refresh();
    return failure;
  }, AppLocalizations.of(context).invitationJoined(invitation.listName));

  Future<void> _decline(Invitation invitation) => _answer(
    invitation,
    () => widget.sharing.decline(invitation),
    AppLocalizations.of(context).invitationDeclined(invitation.listName),
  );

  /// Reloads the Lists. Offline the cached ones just stay; any other failure
  /// is shown, as the session's own requests do.
  Future<void> _refresh() async {
    final failure = await _lists.refresh();
    if (!mounted || failure == null || failure == ListFailure.offline) return;
    showCesToast(context, message: listFailureMessage(AppLocalizations.of(context), failure));
  }

  void _openUserMenu() {
    final l10n = AppLocalizations.of(context);
    final user = widget.session.user;
    unawaited(
      showCesSheet(
        context,
        title: user?.displayName,
        subtitle: user?.email,
        closeTooltip: l10n.sheetClose,
        items: [
          CesSheetItem(
            icon: CesIcons.recentlyDeleted,
            label: l10n.listsRecentlyDeleted,
            onTap: () => unawaited(_openRecentlyDeleted()),
          ),
          CesSheetItem(
            icon: CesIcons.edit,
            label: l10n.userMenuChangeDisplayName,
            onTap: () => unawaited(context.push(Routes.changeDisplayName)),
          ),
          CesSheetItem(
            icon: CesIcons.server,
            label: l10n.userMenuServerStatus,
            onTap: () => unawaited(context.push(Routes.serverStatus)),
          ),
          CesSheetItem(
            icon: CesIcons.signOut,
            label: l10n.userMenuSignOut,
            onTap: () => unawaited(widget.session.signOut()),
          ),
        ],
      ),
    );
  }

  Future<void> _openRecentlyDeleted() async {
    await context.push(Routes.recentlyDeleted);
    await _refresh(); // pick up Lists restored there
  }

  void _create() {
    final l10n = AppLocalizations.of(context);
    final id = ListsController.newListId(); // one per sheet, so retries don't duplicate
    unawaited(
      showCesFormSheet(
        context,
        title: l10n.listsNewSheetTitle,
        closeTooltip: l10n.sheetClose,
        child: ListNameForm(submitLabel: l10n.listsCreate, onSubmit: (name) => _lists.create(id, name)),
      ),
    );
  }

  void _openOptions(ListSummary list) {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showCesSheet(
        context,
        title: list.name,
        closeTooltip: l10n.sheetClose,
        items: [
          CesSheetItem(icon: CesIcons.edit, label: l10n.listsRename, onTap: () => _rename(list)),
          CesSheetItem(
            icon: CesIcons.delete,
            label: l10n.listsDelete,
            destructive: true,
            onTap: () => unawaited(_delete(list)),
          ),
        ],
      ),
    );
  }

  void _rename(ListSummary list) {
    final l10n = AppLocalizations.of(context);
    unawaited(
      showCesFormSheet(
        context,
        title: l10n.listsRenameSheetTitle,
        closeTooltip: l10n.sheetClose,
        child: ListNameForm(
          initialName: list.name,
          submitLabel: l10n.listsSave,
          onSubmit: (name) => _lists.rename(list, name),
        ),
      ),
    );
  }

  Future<void> _delete(ListSummary list) async {
    final failure = await _lists.delete(list);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (failure != null) {
      showCesToast(context, message: listFailureMessage(l10n, failure));
      return;
    }
    showCesToast(
      context,
      message: l10n.listsDeleted(list.name),
      actionLabel: l10n.listsUndo,
      onAction: () => unawaited(_undoDelete(list)),
    );
  }

  Future<void> _undoDelete(ListSummary list) async {
    final failure = await _lists.restore(list.id);
    if (!mounted || failure == null) return;
    showCesToast(context, message: listFailureMessage(AppLocalizations.of(context), failure));
  }

  String _subtitle(AppLocalizations l10n, ListSummary list) => switch (list.role) {
    Role.editor => l10n.listsSharedWithYou,
    Role.owner when list.memberCount > 1 => l10n.listsSharedWithPeople(list.memberCount - 1),
    Role.owner => l10n.listsOnlyYou,
  };

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    return words.map((w) => String.fromCharCode(w.runes.first).toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_lists, widget.session]),
      builder: (context, _) => CesHomeScaffold(
        brand: l10n.appTitle,
        title: l10n.listsTitle,
        actions: [
          CesAvatarButton(
            initials: _initials(widget.session.user?.displayName ?? ''),
            tooltip: l10n.userMenu,
            onPressed: _openUserMenu,
          ),
        ],
        empty: _lists.loaded
            ? CesEmptyState(icon: CesIcons.basket, title: l10n.listsEmptyTitle, body: l10n.listsEmptyBody)
            : const SizedBox.shrink(),
        items: [
          for (final invitation in _invitations)
            CesInvitationCard(
              key: ValueKey(invitation.id),
              name: invitation.listName,
              subtitle: l10n.invitationFrom(invitation.invitedBy.displayName),
              actions: [
                CesButton(
                  label: l10n.invitationJoin,
                  busy: _answering == invitation.id,
                  onPressed: _answering == null ? () => unawaited(_join(invitation)) : null,
                ),
                CesButton.outline(
                  label: l10n.invitationDecline,
                  onPressed: _answering == null ? () => unawaited(_decline(invitation)) : null,
                ),
              ],
            ),
          for (final list in _lists.lists)
            CesListCard(
              key: ValueKey(list.id),
              name: list.name,
              subtitle: _subtitle(l10n, list),
              onTap: () => unawaited(context.push(Routes.list(list.id))),
              action: list.role == Role.owner
                  ? CesIconButton(
                      icon: CesIcons.more,
                      tooltip: l10n.listsOptions(list.name),
                      compact: true,
                      onPressed: () => _openOptions(list),
                    )
                  : null,
              trailing: [
                CesCountSign(
                  count: list.uncheckedItemCount,
                  caption: l10n.listsToBuy,
                  nothingLabel: l10n.listsNothingToBuy,
                ),
              ],
            ),
        ],
        floatingAction: CesFab(label: l10n.listsNew, icon: CesIcons.plus, onPressed: _create),
      ),
    );
  }
}
