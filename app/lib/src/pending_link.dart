import 'dart:async';

import 'db/app_database.dart';
import 'routes.dart';

/// A deep link opened while signed out, kept until the User has signed in
/// (or signed up and confirmed a display name) and got there. It is stored
/// on the device, so it survives the app restarting before the User signs in.
///
/// Only links meant to be opened from outside the app are kept (an
/// Invitation's), so signing out of a List doesn't send the next User there.
class PendingLink {
  PendingLink(this._db);

  final AppDatabase _db;

  /// The kept deep link's location, or null.
  String? get location => _location;
  String? _location;

  /// Whether [keep] or [opened] ran, so [restore] doesn't undo them.
  bool _changed = false;

  /// Reads back the deep link kept before the app last stopped.
  Future<void> restore() async {
    final stored = await _db.readPendingLink();
    if (!_changed) _location = stored;
  }

  /// Keeps [uri] if it is a deep link; anything else leaves what was kept.
  void keep(Uri uri) {
    if (!Routes.isDeepLink(uri.path) || uri.path == _location) return;
    _set(uri.path);
  }

  /// The screen at [location] was opened: the kept deep link is forgotten
  /// once its screen has been. (Not when a redirect points there: the router
  /// may evaluate several locations before settling on one.)
  void opened(String location) {
    if (location == _location) _set(null);
  }

  void _set(String? location) {
    _changed = true;
    _location = location;
    unawaited(_db.savePendingLink(location));
  }
}
