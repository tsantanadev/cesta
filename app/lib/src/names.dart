/// Control characters (C0, DEL, C1), which the server rejects in any name.
final controlCharacters = RegExp(r'[\x00-\x1F\x7F-\x9F]');

/// Why a display name or List name cannot be accepted as typed.
enum NameProblem { blank, tooLong, invalidCharacters }

/// What is wrong with [name], or null if the server should accept it.
NameProblem? checkName(String name, {required int maxLength}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return NameProblem.blank;
  if (trimmed.runes.length > maxLength) return NameProblem.tooLong;
  if (controlCharacters.hasMatch(trimmed)) return NameProblem.invalidCharacters;
  return null;
}
