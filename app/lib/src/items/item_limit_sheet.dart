import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';

/// Says the List can't take more than [limit] Items (Figma "14 Item limit"
/// 38:2928). With [onClearChecked] (the List has Checked Items) it offers
/// Clear checked, which closes the sheet; without, the sheet closes with its
/// close button only.
Future<void> showItemLimitSheet(BuildContext context, {required int limit, VoidCallback? onClearChecked}) {
  final l10n = AppLocalizations.of(context);
  return showCesItemSheet(
    context,
    title: l10n.itemLimitTitle,
    closeTooltip: l10n.sheetClose,
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CesSheetText(onClearChecked == null ? l10n.itemLimitBody(limit) : l10n.itemLimitBodyClearChecked(limit)),
          if (onClearChecked != null) ...[
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
