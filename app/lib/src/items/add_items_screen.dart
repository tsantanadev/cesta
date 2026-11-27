import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../lists/lists_controller.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';
import 'item_form.dart';
import 'item_text.dart';
import 'items_store.dart';
import 'matches.dart';
import 'opened_item.dart';

/// Add items (Figma "05 Add items" 4:269): search what to add. As the Member
/// types, Matches (4:280) shows the List's Items to buy whose names match,
/// highlighted; tapping one opens that Item instead of adding a duplicate.
/// "Add “…” as a new item" opens the New item sheet, even when something
/// matches. Items from the List's Item history show white: as Bought
/// before while nothing is typed, and under Matches after the List's own as
/// the Member types. Tapping one adds it straight away as last bought, with
/// an Undo Toast.
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
  List<ShownItem> _onList = const [];
  List<HistoryEntry> _history = const [];
  StreamSubscription<List<ShownItem>>? _itemsSub;
  StreamSubscription<List<HistoryEntry>>? _historySub;

  @override
  void initState() {
    super.initState();
    _itemsSub = widget.items.watchList(widget.listId).listen((items) => setState(() => _onList = items));
    _historySub = widget.items.watchHistory(widget.listId).listen((h) => setState(() => _history = h));
  }

  @override
  void dispose() {
    unawaited(_itemsSub?.cancel());
    unawaited(_historySub?.cancel());
    _search.dispose();
    super.dispose();
  }

  Actor? get _me => switch (widget.session.user) {
    final user? => (id: user.id, displayName: user.displayName),
    null => null,
  };

  /// Opens [item], already on the List, instead of adding it again.
  void _openItem(ShownItem item) {
    final me = _me;
    if (me == null) return;
    showOpenedItem(context, items: widget.items, item: item, me: me);
  }

  String get _listName => widget.lists.lists.where((l) => l.id == widget.listId).firstOrNull?.name ?? '';

  void _addAsNew() {
    final l10n = AppLocalizations.of(context);
    final me = _me;
    if (me == null) return;
    unawaited(
      showCesItemSheet(
        context,
        title: l10n.newItemTitle,
        closeTooltip: l10n.sheetClose,
        child: ItemForm(
          submitLabel: l10n.newItemAddTo(_listName),
          submitIcon: CesIcons.plus,
          initial: ItemDetails(name: _search.text.trim()),
          onSubmit: (draft) => unawaited(_add(draft, me)),
        ),
      ),
    );
  }

  /// Adds an Item with [details], clears the search for the next one, and
  /// offers Undo.
  Future<void> _add(ItemDetails details, Actor me) async {
    final id = await widget.items.add(listId: widget.listId, by: me, details: details);
    if (!mounted) return;
    _search.clear();
    setState(() {});
    final l10n = AppLocalizations.of(context);
    showCesToast(
      context,
      message: l10n.itemAdded(details.name, _listName),
      actionLabel: l10n.itemUndo,
      onAction: () => unawaited(widget.items.remove(itemId: id, listId: widget.listId, by: me)),
    );
  }

  /// Adds [entry] of the Item history again, as it was last bought.
  void _addAgain(HistoryEntry entry) {
    final me = _me;
    if (me == null) return;
    unawaited(_add(entry.details, me));
  }

  Widget _section(String heading, List<Widget> tiles) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CesSectionHeading(heading),
        const SizedBox(height: 12),
        Wrap(spacing: 11, runSpacing: 11, children: tiles),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = _search.text.trim();
    final matches = listMatches(_onList, query);
    final fromHistory = historyToOffer(_history, _onList, query);
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
                  CesBarAction(label: l10n.addItemsDone, onPressed: () => context.pop()),
                ],
              ),
            ),
            // Matches (Figma 4:280): the List's Items to buy, as on the List,
            // then Items from the Item history; Bought before while nothing is typed.
            if (matches.isNotEmpty || fromHistory.isNotEmpty)
              _section(query.isEmpty ? l10n.addItemsBoughtBefore : l10n.addItemsMatches, [
                for (final item in matches)
                  CesItemTile(
                    key: ValueKey(item.id),
                    name: item.name,
                    quantity: tagQuantity(l10n, item.quantity, item.unit),
                    semanticHint: l10n.itemOpen,
                    onTap: () => _openItem(item),
                  ),
                for (final item in fromHistory)
                  CesItemTile(
                    key: ValueKey('history ${item.itemId}'),
                    name: item.name,
                    quantity: tagQuantity(l10n, item.quantity, item.unit),
                    semanticHint: l10n.itemAddAgain,
                    suggestion: true,
                    onTap: () => _addAgain(item),
                  ),
              ]),
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
