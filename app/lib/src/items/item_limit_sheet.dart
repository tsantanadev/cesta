import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'item_text.dart';

/// Says the List can't take more Items (Figma "14 Item limit" 38:2928).
///
/// The design's "Clear checked" button is left out until the app can clear
/// checked Items; the sheet then closes with its close button only.
Future<void> showItemLimitSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showCesFormSheet(
    context,
    title: l10n.itemLimitTitle,
    closeTooltip: l10n.sheetClose,
    sectionGap: 18,
    child: Builder(
      builder: (context) => Text(
        l10n.itemLimitBody(maxItemsPerList),
        style: TextStyle(
          fontFamily: CestaFonts.family,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
