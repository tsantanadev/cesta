import 'items_store.dart';

/// Whether an Item named [name] matches what was typed in Add items
/// ([query]): the name contains it, ignoring case and accents ("PAO" matches
/// "Pão de forma"). A blank query matches nothing.
bool nameMatches(String name, String query) {
  final q = foldName(query.trim());
  return q.isNotEmpty && foldName(name).contains(q);
}

/// The Matches that come from the List itself: its Items whose names match
/// [query], Items to buy first and then those In the basket, each in the
/// order the List shows them. They show highlighted, so the Member opens the
/// Item already there instead of adding a duplicate.
List<ShownItem> listMatches(List<ShownItem> items, String query) => [
  for (final item in items)
    if (!item.checked && nameMatches(item.name, query)) item,
  for (final item in items)
    if (item.checked && nameMatches(item.name, query)) item,
];

/// The entries of a List's Item [history] (most recent first) to offer on
/// Add items: each name once, as last bought, leaving out names already on
/// the List ([onList]), to buy or In the basket, since the List's own Item
/// wins. With a blank [query] they are Bought before (the most recent
/// [boughtBeforeCap]); otherwise the ones that match, shown under Matches
/// after the List's.
List<HistoryEntry> historyToOffer(List<HistoryEntry> history, List<ShownItem> onList, String query) {
  // Names on the List, then also each name offered, so it's offered once.
  final taken = {for (final item in onList) _key(item.name)};
  final blank = query.trim().isEmpty;
  final offered = <HistoryEntry>[];
  for (final entry in history) {
    if (!taken.add(_key(entry.name))) continue;
    if (blank || nameMatches(entry.name, query)) offered.add(entry);
    if (blank && offered.length == boughtBeforeCap) break;
  }
  return offered;
}

/// [name] as names compare: trimmed and folded with [foldName].
String _key(String name) => foldName(name.trim());

/// How many names Bought before shows at most.
const boughtBeforeCap = 12;

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
