import '../names.dart';

export '../names.dart' show NameProblem;

/// What the app accepts in the sign-in and display name fields, before the
/// identity provider or the server is asked. The messages for each problem are
/// in auth_messages.dart.

/// Shortest password accepted on sign-up. Firebase's own minimum is 6.
const minPasswordLength = 8;

/// Longest display name, matching the API contract.
const maxDisplayNameLength = 50;

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Whether [email] (already trimmed) looks like an email address.
bool looksLikeEmail(String email) => _email.hasMatch(email);

/// What is wrong with [name], or null if the server should accept it.
NameProblem? checkDisplayName(String name) => checkName(name, maxLength: maxDisplayNameLength);
