import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../routes.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';
import 'list_messages.dart';
import 'list_name_form.dart';
import 'lists_controller.dart';

/// Home: the Lists the User owns or was shared, and the User menu.
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key, required this.session, required this.lists});

  final SessionController session;
  final ListsController lists;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  ListsController get _lists => widget.lists;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

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
          for (final list in _lists.lists)
            CesListCard(
              key: ValueKey(list.id),
              name: list.name,
              subtitle: _subtitle(l10n, list),
              trailing: [
                CesCountSign(
                  count: list.uncheckedItemCount,
                  caption: l10n.listsToBuy,
                  nothingLabel: l10n.listsNothingToBuy,
                ),
                if (list.role == Role.owner)
                  CesIconButton(
                    icon: CesIcons.more,
                    tooltip: l10n.listsOptions(list.name),
                    onPressed: () => _openOptions(list),
                  ),
              ],
            ),
        ],
        floatingAction: CesFab(label: l10n.listsNew, icon: CesIcons.plus, onPressed: _create),
      ),
    );
  }
}
