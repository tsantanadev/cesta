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
import '../ui/tokens.dart';
import 'item_text.dart';
import 'items_store.dart';

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
  StreamSubscription<List<ShownItem>>? _itemsSub;
  StreamSubscription<int>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _itemsSub = widget.items.watchList(widget.listId).listen((items) => setState(() => _shown = items));
    _pendingSub = widget.items.watchPendingCount().listen((n) => setState(() => _pending = n));
  }

  @override
  void dispose() {
    unawaited(_itemsSub?.cancel());
    unawaited(_pendingSub?.cancel());
    super.dispose();
  }

  ListSummary? get _list => widget.lists.lists.where((l) => l.id == widget.listId).firstOrNull;

  Actor? get _me => switch (widget.session.user) {
    final user? => (id: user.id, displayName: user.displayName),
    null => null,
  };

  void _setChecked(ShownItem item, bool checked) {
    final me = _me;
    if (me == null) return;
    unawaited(widget.items.setChecked(item, checked: checked, by: me));
  }

  /// Opens the Item to edit or remove it (#7 design gap "Opened Item": not built yet).
  void _openItem(ShownItem item) {}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final toBuy = _shown.where((i) => !i.checked).toList();
    final inBasket = _shown.where((i) => i.checked).toList()..sort((a, b) => a.checkedAt!.compareTo(b.checkedAt!));
    final myId = widget.session.user?.id;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: widget.lists,
      builder: (context, _) => Scaffold(
        body: Stack(
          children: [
            SafeArea(
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
                          // Placeholder until the offline/pending indicator is designed (#7 design gap).
                          if (_pending > 0)
                            Tooltip(
                              message: l10n.listSyncPending,
                              child: Icon(CesIcons.offline, size: 20, color: scheme.onSurfaceVariant),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      _list?.name ?? '',
                                      style: CestaDisplayType.screenTitle.copyWith(color: scheme.onSurface),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.listToBuyInBasket(toBuy.length, inBasket.length),
                                    style: TextStyle(
                                      fontFamily: CestaFonts.family,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
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
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: CesSectionHeading(l10n.listInTheBasket),
                                  ),
                                  for (final item in inBasket)
                                    Padding(
                                      key: ValueKey(item.id),
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: CesCheckedItem(
                                        name: item.name,
                                        checkedBy: item.checkedById == myId
                                            ? l10n.listCheckedByYou
                                            : item.checkedByName ?? '',
                                        semanticHint: l10n.itemUncheck,
                                        onTap: () => _setChecked(item, false),
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CesAddBar(
                label: l10n.listAddAnItem,
                onTap: () => unawaited(context.push(Routes.addItems(widget.listId))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
