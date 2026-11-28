import 'routes.dart';

/// A deep link opened while signed out, kept until the User has signed in
/// (or signed up and confirmed a display name) and got there.
///
/// Only links meant to be opened from outside the app are kept (an
/// Invitation's), so signing out of a List doesn't send the next User there.
class PendingLink {
  /// The kept deep link's location, or null.
  String? get location => _location;
  String? _location;

  /// Keeps [uri] if it is a deep link; anything else leaves what was kept.
  void keep(Uri uri) {
    if (Routes.isDeepLink(uri.path)) _location = uri.path;
  }

  /// The screen at [location] was opened: the kept deep link is forgotten
  /// once its screen has been. (Not when a redirect points there: the router
  /// may evaluate several locations before settling on one.)
  void opened(String location) {
    if (location == _location) _location = null;
  }
}
