import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../lists/lists_controller.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'item_form.dart';
import 'items_store.dart';

/// Add items (Figma "05 Add items" 4:269): search what to add; "Add “…” as a
/// new item" opens the New item sheet. Matches and Bought before come with #8.
class AddItemsScreen extends StatefulWidget {
  const AddItemsScreen({
    super.key,
    required this.listId,
    required this.session,
    required this.lists,
    required this.items,
  });

  final String listId;
  final SessionController session;
  final ListsController lists;
  final ItemsStore items;

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _listName => widget.lists.lists.where((l) => l.id == widget.listId).firstOrNull?.name ?? '';

  void _addAsNew() {
    final l10n = AppLocalizations.of(context);
    final user = widget.session.user;
    if (user == null) return;
    final me = (id: user.id, displayName: user.displayName);
    unawaited(
      showCesFormSheet(
        context,
        title: l10n.newItemTitle,
        closeTooltip: l10n.sheetClose,
        sectionGap: 18,
        child: ItemForm(
          submitLabel: l10n.newItemAddTo(_listName),
          submitIcon: CesIcons.plus,
          initial: ItemDetails(name: _search.text.trim()),
          onSubmit: (draft) async {
            final id = await widget.items.add(listId: widget.listId, by: me, details: draft);
            if (!mounted) return;
            _search.clear();
            setState(() {});
            showCesToast(
              context,
              message: l10n.itemAdded(draft.name, _listName),
              actionLabel: l10n.itemUndo,
              onAction: () => unawaited(widget.items.remove(itemId: id, listId: widget.listId, by: me)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final query = _search.text.trim();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar (Figma 4:272).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: CesSearchField(
                      controller: _search,
                      label: l10n.addItemsSearch,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (_search.text.trim().isNotEmpty) _addAsNew();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      textStyle: const TextStyle(
                        fontFamily: CestaFonts.family,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    child: Text(l10n.addItemsDone),
                  ),
                ],
              ),
            ),
            if (query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CesAddAsNew(label: l10n.addItemsAddAsNew(query), onTap: _addAsNew),
              ),
          ],
        ),
      ),
    );
  }
}
