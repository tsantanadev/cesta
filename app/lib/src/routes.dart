/// The app's route paths, so a path changes in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const resetPassword = '/reset-password';
  static const onboardingName = '/onboarding/name';
  static const home = '/';
  static const recentlyDeleted = '/lists/deleted';

  /// A List's screen (04).
  static String list(String listId) => '/lists/$listId';

  /// Add items (05) for a List.
  static String addItems(String listId) => '/lists/$listId/add';

  /// Share list (06) for a List.
  static String shareList(String listId) => '/lists/$listId/share';
  static const changeDisplayName = '/me/name';
  static const serverStatus = '/server-status';
}
