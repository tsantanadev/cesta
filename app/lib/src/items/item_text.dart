import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';

/// The longest Item name the server accepts, in characters.
const maxItemNameLength = 80;

/// The longest Item note the server accepts, in characters.
const maxItemNoteLength = 200;

/// The units in the order the New item sheet offers them (Figma 9:467).
const unitChoices = [ItemUnit.kg, ItemUnit.g, ItemUnit.un, ItemUnit.l, ItemUnit.ml, ItemUnit.pack];

/// [unit] as its chip shows it ("un" reads "units" in English).
String unitLabel(AppLocalizations l10n, ItemUnit unit) => switch (unit) {
  ItemUnit.un => l10n.unitUn,
  ItemUnit.kg => l10n.unitKg,
  ItemUnit.g => l10n.unitG,
  ItemUnit.l => l10n.unitL,
  ItemUnit.ml => l10n.unitMl,
  ItemUnit.pack => l10n.unitPack,
};

/// [quantity] (API form, e.g. "1.5") written for [l10n]'s locale, e.g. "1,5".
String formatQuantity(AppLocalizations l10n, String quantity) {
  final value = num.tryParse(quantity);
  if (value == null) return quantity;
  return NumberFormat.decimalPattern(l10n.localeName).format(value);
}

/// What an Item's tag shows above its name, e.g. "1 kg", "10" (counted
/// units show just the number), or null when it has no quantity.
String? tagQuantity(AppLocalizations l10n, String? quantity, ItemUnit? unit) {
  if (quantity == null) return null;
  final number = formatQuantity(l10n, quantity);
  if (unit == null || unit == ItemUnit.un) return number;
  return '$number ${unitLabel(l10n, unit)}';
}

/// A typed quantity in the API's form ("1.5"), accepting a comma as the
/// decimal separator; null when blank. Throws [FormatException] when it isn't
/// a positive number with at most 6 whole and 3 decimal digits.
String? parseQuantity(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final match = RegExp(r'^([0-9]{1,6})(?:\.([0-9]{0,3}))?$').firstMatch(t);
  if (match == null) throw FormatException('Not a quantity', text);
  final whole = int.parse(match.group(1)!).toString();
  final fraction = (match.group(2) ?? '').replaceFirst(RegExp(r'0+$'), '');
  final result = fraction.isEmpty ? whole : '$whole.$fraction';
  if (num.parse(result) <= 0) throw FormatException('Not above zero', text);
  return result;
}

/// [text] as [parseQuantity] reads it, or null when it is blank or not a quantity.
String? tryParseQuantity(String text) {
  try {
    return parseQuantity(text);
  } on FormatException {
    return null;
  }
}

/// [quantity] (API form) as a person types it in [l10n]'s locale: the
/// locale's decimal separator, no grouping (e.g. "1,5" in Portuguese).
String editableQuantity(AppLocalizations l10n, String quantity) =>
    quantity.replaceAll('.', NumberFormat.decimalPattern(l10n.localeName).symbols.DECIMAL_SEP);

/// [quantity] (API form; null for none) moved by [by] whole units, exactly,
/// keeping its decimals ("2.3" − 1 is "1.3"); null when that is below one,
/// where the quantity goes away.
String? stepQuantity(String? quantity, int by) {
  final (whole, fraction) = switch (quantity?.split('.')) {
    [final w] => (int.parse(w), ''),
    [final w, final f] => (int.parse(w), f),
    _ => (0, ''),
  };
  final next = whole + by;
  if (next < 1) return null;
  return fraction.isEmpty ? '$next' : '$next.$fraction';
}
