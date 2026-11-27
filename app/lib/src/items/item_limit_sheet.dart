import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'items_store.dart';

/// Says the List can't take more than [limit] Items (Figma "14 Item limit"
/// 38:2928). When the List's [items] include Checked Items it offers Clear
/// checked ([onClearChecked]), which closes the sheet; otherwise the sheet
/// closes with its close button only.
Future<void> showItemLimitSheet(
  BuildContext context, {
  required int limit,
  required List<ShownItem> items,
  required VoidCallback onClearChecked,
}) {
  final l10n = AppLocalizations.of(context);
  final anyChecked = items.any((i) => i.checked);
  return showCesItemSheet(
    context,
    title: l10n.itemLimitTitle,
    closeTooltip: l10n.sheetClose,
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CesSheetText(anyChecked ? l10n.itemLimitBodyClearChecked(limit) : l10n.itemLimitBody(limit)),
          if (anyChecked) ...[
            const CesItemSheetGap(),
            CesButton(
              label: l10n.listClearChecked,
              onPressed: () {
                Navigator.of(context).pop();
                onClearChecked();
              },
            ),
          ],
        ],
      ),
    ),
  );
}
