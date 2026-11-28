import 'package:go_router/go_router.dart';

import 'api/generated/cesta_api.dart';
import 'auth/auth_gateway.dart';
import 'db/app_database.dart';
import 'health/health_screen.dart';
import 'items/add_items_screen.dart';
import 'items/items_store.dart';
import 'items/list_screen.dart';
import 'lists/lists_controller.dart';
import 'lists/lists_screen.dart';
import 'lists/recently_deleted_screen.dart';
import 'pending_link.dart';
import 'routes.dart';
import 'session/display_name_screen.dart';
import 'session/email_auth_screen.dart';
import 'session/reset_password_screen.dart';
import 'session/session_controller.dart';
import 'session/splash_screen.dart';
import 'session/welcome_screen.dart';
import 'sharing/invitation_screen.dart';
import 'sharing/share_list_screen.dart';
import 'sharing/sharing.dart';
import 'sync/sync_engine.dart';

/// Screens a signed-out visitor may see.
const _signedOutRoutes = {Routes.welcome, Routes.signIn, Routes.signUp, Routes.resetPassword};

/// Where the session sends the User, or null to stay on [uri].
///
/// - Until the stored session is known, and while a signed-in User is not
///   known yet: the splash screen, which remembers where the User was going
///   (`/splash?from=...`) and goes there once the User is known. If the User
///   can't be loaded (offline, nothing cached) it says so and offers to retry
///   or sign out.
/// - Signed out: the welcome flow only. A deep link opened meanwhile is kept
///   in [pending] and opened once the User is signed in.
/// - Signed in with a display name not yet confirmed: the display name screen.
/// - Signed in otherwise: anywhere but the signed-out flow.
String? sessionRedirect(SessionController session, Uri uri, PendingLink pending) {
  final location = uri.path;
  final atSplash = location == Routes.splash;
  String? splash() => atSplash ? null : Uri(path: Routes.splash, queryParameters: {'from': uri.toString()}).toString();
  switch (session.status) {
    case SessionStatus.starting:
      return splash();
    case SessionStatus.signedOut:
      pending.keep(atSplash ? Uri.tryParse(uri.queryParameters['from'] ?? '') ?? uri : uri);
      return _signedOutRoutes.contains(location) ? null : Routes.welcome;
    case SessionStatus.signedIn:
      final user = session.user;
      if (user == null) return splash();
      if (!user.displayNameConfirmed) {
        return location == Routes.onboardingName ? null : Routes.onboardingName;
      }
      if (atSplash) {
        final from = Uri.tryParse(uri.queryParameters['from'] ?? '');
        final resumable = from != null && !_signedOutRoutes.contains(from.path) && from.path != Routes.splash;
        return resumable ? from.toString() : pending.location ?? Routes.home;
      }
      if (_signedOutRoutes.contains(location) || location == Routes.onboardingName) {
        return pending.location ?? Routes.home;
      }
      return null;
  }
}

GoRouter buildRouter({
  required SessionController session,
  required ListsController lists,
  required ItemsStore items,
  required SyncEngine sync,
  required AuthGateway auth,
  required ApiClient api,
  required AppDatabase database,
  required Sharing sharing,
  required PendingLink pending,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? Routes.home,
  refreshListenable: session,
  redirect: (context, state) => sessionRedirect(session, state.uri, pending),
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (_, _) => SplashScreen(session: session),
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (_, _) => WelcomeScreen(auth: auth),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (_, _) => EmailAuthScreen(auth: auth, mode: EmailAuthMode.signIn),
    ),
    GoRoute(
      path: Routes.signUp,
      builder: (_, _) => EmailAuthScreen(auth: auth, mode: EmailAuthMode.signUp),
    ),
    GoRoute(
      path: Routes.resetPassword,
      builder: (_, state) => ResetPasswordScreen(auth: auth, initialEmail: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: Routes.onboardingName,
      builder: (_, _) => DisplayNameScreen(session: session, onboarding: true),
    ),
    GoRoute(
      path: Routes.home,
      builder: (_, _) => ListsScreen(session: session, lists: lists, sharing: sharing),
    ),
    GoRoute(
      path: Routes.recentlyDeleted,
      builder: (_, _) => RecentlyDeletedScreen(lists: lists),
    ),
    GoRoute(
      path: '/lists/:listId',
      builder: (_, state) =>
          ListScreen(listId: state.pathParameters['listId']!, session: session, lists: lists, items: items, sync: sync),
      routes: [
        GoRoute(
          path: 'add',
          builder: (_, state) =>
              AddItemsScreen(listId: state.pathParameters['listId']!, session: session, lists: lists, items: items),
        ),
        GoRoute(
          path: 'share',
          builder: (_, state) =>
              ShareListScreen(listId: state.pathParameters['listId']!, lists: lists, sharing: sharing),
        ),
      ],
    ),
    GoRoute(
      path: Routes.invitation(':token'),
      builder: (_, state) {
        pending.opened(state.uri.path);
        return InvitationScreen(
          token: state.pathParameters['token']!,
          session: session,
          lists: lists,
          sharing: sharing,
        );
      },
    ),
    GoRoute(
      path: Routes.changeDisplayName,
      builder: (_, _) => DisplayNameScreen(session: session, onboarding: false),
    ),
    GoRoute(
      path: Routes.serverStatus,
      builder: (_, _) => HealthScreen(api: api, database: database),
    ),
  ],
);
