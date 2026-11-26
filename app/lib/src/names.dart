/// Control characters (C0, DEL, C1), which the server rejects in any name.
final controlCharacters = RegExp(r'[\x00-\x1F\x7F-\x9F]');
