import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';

/// Says the List can't take more than [limit] Items (Figma "14 Item limit"
/// 38:2928).
///
/// The design's "Clear checked" button is left out until the app can clear
/// checked Items (#8); the sheet then closes with its close button only.
Future<void> showItemLimitSheet(BuildContext context, {required int limit}) {
  final l10n = AppLocalizations.of(context);
  return showCesItemSheet(
    context,
    title: l10n.itemLimitTitle,
    closeTooltip: l10n.sheetClose,
    child: CesSheetText(l10n.itemLimitBody(limit)),
  );
}
