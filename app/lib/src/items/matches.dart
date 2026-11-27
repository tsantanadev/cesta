import 'items_store.dart';

/// Whether an Item named [name] matches what was typed in Add items
/// ([query]): the name contains it, ignoring case and accents ("PAO" matches
/// "Pão de forma"). A blank query matches nothing.
bool nameMatches(String name, String query) {
  final q = foldName(query.trim());
  return q.isNotEmpty && foldName(name).contains(q);
}

/// The Matches that come from the List itself: its Items to buy whose names
/// match [query], in the order the List shows them. They show highlighted, so
/// the Member opens the Item already there instead of adding a duplicate.
List<ShownItem> listMatches(List<ShownItem> items, String query) => [
  for (final item in items)
    if (!item.checked && nameMatches(item.name, query)) item,
];

/// The entries of a List's Item [history] (most recent first) to offer on
/// Add items: each name once, as last bought, leaving out names the List already has
/// to buy ([onList]), since the List's own Item wins. With a blank [query]
/// they are Bought before (the most recent [limit]); otherwise the ones that
/// match, shown under Matches after the List's.
List<HistoryItem> historyToOffer(List<HistoryItem> history, List<ShownItem> onList, String query, {int limit = 12}) {
  final seen = {
    for (final item in onList)
      if (!item.checked) foldName(item.name.trim()),
  };
  final blank = query.trim().isEmpty;
  final offered = <HistoryItem>[];
  for (final entry in history) {
    if (!seen.add(foldName(entry.name.trim()))) continue;
    if (blank || nameMatches(entry.name, query)) offered.add(entry);
    if (blank && offered.length == limit) break;
  }
  return offered;
}

/// [text] lower-cased with the accents of Portuguese and other Latin
/// letters taken off, so names compare as a person reads them.
String foldName(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    // A combining accent (as in decomposed "a\u0303") just goes.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    out.write(_unaccented[char] ?? char);
  }
  return out.toString();
}

const _unaccented = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
};
