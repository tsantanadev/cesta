import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'item_form.dart';
import 'items_store.dart';

/// Opens [item] to edit or remove it (Figma "12 Opened item" 38:2519), from a
/// List's screen or from Matches on Add items. Removing shows a Toast with
/// Undo (Figma "12b Item removed" 38:2667).
void showOpenedItem(BuildContext context, {required ItemsStore items, required ShownItem item, required Actor me}) {
  final l10n = AppLocalizations.of(context);
  unawaited(
    showCesItemSheet(
      context,
      title: l10n.itemEditTitle,
      closeTooltip: l10n.sheetClose,
      child: ItemForm(
        submitLabel: l10n.itemSave,
        initial: item.details,
        details: [
          item.addedBy.id == me.id ? l10n.itemAddedByYou : l10n.itemAddedBy(item.addedBy.displayName),
          if (item.checkedBy case final checkedBy?)
            checkedBy.id == me.id ? l10n.itemCheckedByYou : l10n.itemCheckedBy(checkedBy.displayName),
        ],
        onSubmit: (draft) => unawaited(items.update(item, by: me, details: draft)),
        onRemove: () => unawaited(_remove(context, items, item, me)),
      ),
    ),
  );
}

Future<void> _remove(BuildContext context, ItemsStore items, ShownItem item, Actor me) async {
  await items.remove(itemId: item.id, listId: item.listId, by: me);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  showCesToast(
    context,
    message: l10n.itemRemoved(item.name),
    actionLabel: l10n.itemUndo,
    onAction: () => unawaited(items.restore(item, by: me)),
  );
}
