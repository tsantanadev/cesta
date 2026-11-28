import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../lists/lists_controller.dart';
import '../routes.dart';
import '../session/session_controller.dart';
import '../sync/sync_engine.dart';
import '../ui/components.dart';
import 'item_limit_sheet.dart';
import 'item_text.dart';
import 'items_store.dart';
import 'opened_item.dart';

/// A List's screen (Figma "04 List" 4:148): its Items to buy as tags, then
/// the Checked Items In the basket, and the bar that adds Items.
///
/// Everything shown comes from the device ([ItemsStore]), so it works offline;
/// pulling down syncs.
class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    required this.listId,
    required this.session,
    required this.lists,
    required this.items,
    required this.sync,
  });

  final String listId;
  final SessionController session;
  final ListsController lists;
  final ItemsStore items;
  final SyncEngine sync;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<ShownItem> _shown = const [];
  int _pending = 0;
  bool _loaded = false;
  StreamSubscription<List<ShownItem>>? _itemsSub;
  StreamSubscription<int>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _itemsSub = widget.items
        .watchList(widget.listId)
        .listen(
          (items) => setState(() {
            _shown = items;
            _loaded = true;
          }),
        );
    _pendingSub = widget.items.watchPendingCount(widget.listId).listen((n) => setState(() => _pending = n));
    // Show what other Members changed since the last sync (story 43).
    unawaited(widget.sync.sync());
  }

  @override
  void dispose() {
    unawaited(_itemsSub?.cancel());
    unawaited(_pendingSub?.cancel());
    super.dispose();
  }

  ListSummary? get _list => widget.lists.lists.where((l) => l.id == widget.listId).firstOrNull;

  void _setChecked(ShownItem item, bool checked) =>
      widget.session.asMe((me) => unawaited(widget.items.setChecked(item, checked: checked, by: me)));

  /// Clears every Checked Item into the List's Item history.
  void _clearChecked() =>
      widget.session.asMe((me) => unawaited(widget.items.clearChecked(listId: widget.listId, by: me)));

  /// Opens [item] to edit or remove it (Figma "12 Opened item" 38:2519).
  void _openItem(ShownItem item) =>
      widget.session.asMe((me) => showOpenedItem(context, items: widget.items, item: item, me: me));

  /// Opens Add items, unless the List is already full (Figma "14 Item limit").
  void _addItems() {
    final limit = widget.sync.itemLimit.value;
    if (_shown.length >= limit) {
      unawaited(showItemLimitSheet(context, limit: limit, items: _shown, onClearChecked: _clearChecked));
      return;
    }
    unawaited(context.push(Routes.addItems(widget.listId)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final toBuy = _shown.where((i) => !i.checked).toList();
    final inBasket = _shown.where((i) => i.checked).toList()..sort((a, b) => a.checkedAt!.compareTo(b.checkedAt!));
    final myId = widget.session.user?.id;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: widget.lists,
      builder: (context, _) => Scaffold(
        // The Add bar is the bottom bar, so Toasts float above it (Figma 12b, 13b).
        extendBody: true,
        bottomNavigationBar: CesAddBar(label: l10n.listAddAnItem, onTap: _addItems),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar (Figma 4:151).
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CesBackButton(onPressed: () => context.pop()),
                      const Spacer(),
                      // Only the Owner invites, so far all Share list offers (Figma "Share" 4:163).
                      if (_list?.role == Role.owner)
                        CesTopBarButton(
                          icon: CesIcons.share,
                          tooltip: l10n.shareTitle,
                          onPressed: () => unawaited(context.push(Routes.shareList(widget.listId))),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.sync.sync,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                        sliver: SliverToBoxAdapter(
                          // Figma "13 List offline" 38:3843: the pill shows only while offline.
                          child: ValueListenableBuilder(
                            valueListenable: widget.sync.offline,
                            builder: (context, offline, _) => CesListHeading(
                              title: _list?.name ?? '',
                              summary: _shown.isEmpty
                                  ? l10n.listNothingToBuyYet
                                  : l10n.listToBuyInBasket(toBuy.length, inBasket.length),
                              status: offline ? l10n.listOffline(_pending) : null,
                            ),
                          ),
                        ),
                      ),
                      // Figma "15 Empty list" 39:3859.
                      if (_loaded && _shown.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(40, 96, 40, 0),
                            child: CesEmptyListState(title: l10n.listEmptyTitle, body: l10n.listEmptyBody),
                          ),
                        ),
                      // To buy (Figma 4:169): tags in insertion order.
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            spacing: 11,
                            runSpacing: 11,
                            children: [
                              for (final item in toBuy)
                                CesItemTile(
                                  key: ValueKey(item.id),
                                  name: item.name,
                                  quantity: tagQuantity(l10n, item.quantity, item.unit),
                                  semanticHint: l10n.itemCheck,
                                  onTap: () => _setChecked(item, true),
                                  onLongPress: () => _openItem(item),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // In the basket (Figma 4:242).
                      if (inBasket.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                          sliver: SliverList.list(
                            children: [
                              // The heading, with Clear checked (Figma 4:245) on its right.
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(child: CesSectionHeading(l10n.listInTheBasket)),
                                    CesBarAction(label: l10n.listClearChecked, onPressed: _clearChecked),
                                  ],
                                ),
                              ),
                              for (final item in inBasket)
                                Padding(
                                  key: ValueKey(item.id),
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: CesCheckedItem(
                                    name: item.name,
                                    checkedBy: item.checkedBy?.id == myId
                                        ? l10n.listCheckedByYou
                                        : item.checkedBy?.displayName ?? '',
                                    semanticHint: l10n.itemUncheck,
                                    onTap: () => _setChecked(item, false),
                                    onLongPress: () => _openItem(item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: CesAddBar.height + 16 + bottomInset)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
