import 'package:go_router/go_router.dart';

import 'api/generated/cesta_api.dart';
import 'auth/auth_gateway.dart';
import 'db/app_database.dart';
import 'health/health_screen.dart';
import 'home/home_screen.dart';
import 'session/display_name_screen.dart';
import 'session/email_auth_screen.dart';
import 'session/reset_password_screen.dart';
import 'session/session_controller.dart';
import 'session/splash_screen.dart';
import 'session/welcome_screen.dart';

/// Screens a signed-out visitor may see.
const _signedOutRoutes = {'/welcome', '/sign-in', '/sign-up', '/reset-password'};

/// Where the session sends the User, or null to stay on [uri].
///
/// - Until the stored session is known, and while a signed-in User is
///   first loading: the splash screen, which remembers where the User was
///   going (`/splash?from=...`) and goes there once the User is known.
/// - Signed out: the welcome flow only.
/// - Signed in with a display name not yet confirmed: the display name screen.
/// - Signed in otherwise: anywhere but the signed-out flow. If the User
///   can't be loaded (offline, nothing cached) the User still gets home.
String? sessionRedirect(SessionController session, Uri uri) {
  final location = uri.path;
  final atSplash = location == '/splash';
  String? splash() => atSplash ? null : Uri(path: '/splash', queryParameters: {'from': uri.toString()}).toString();
  switch (session.status) {
    case SessionStatus.starting:
      return splash();
    case SessionStatus.signedOut:
      return _signedOutRoutes.contains(location) ? null : '/welcome';
    case SessionStatus.signedIn:
      if (session.loadingUser) return splash();
      if (session.user case final user? when !user.displayNameConfirmed) {
        return location == '/onboarding/name' ? null : '/onboarding/name';
      }
      if (atSplash) {
        final from = Uri.tryParse(uri.queryParameters['from'] ?? '');
        final resumable = from != null && !_signedOutRoutes.contains(from.path) && from.path != '/splash';
        return resumable ? from.toString() : '/';
      }
      if (_signedOutRoutes.contains(location) || location == '/onboarding/name') return '/';
      return null;
  }
}

GoRouter buildRouter({
  required SessionController session,
  required AuthGateway auth,
  required ApiClient api,
  required AppDatabase database,
  String? initialLocation,
}) => GoRouter(
  initialLocation: initialLocation ?? '/',
  refreshListenable: session,
  redirect: (context, state) => sessionRedirect(session, state.uri),
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/welcome',
      builder: (_, _) => WelcomeScreen(auth: auth),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (_, _) => EmailAuthScreen(auth: auth, mode: EmailAuthMode.signIn),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (_, _) => EmailAuthScreen(auth: auth, mode: EmailAuthMode.signUp),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) => ResetPasswordScreen(auth: auth, initialEmail: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: '/onboarding/name',
      builder: (_, _) => DisplayNameScreen(session: session, onboarding: true),
    ),
    GoRoute(
      path: '/',
      builder: (_, _) => HomeScreen(session: session),
    ),
    GoRoute(
      path: '/me/name',
      builder: (_, _) => DisplayNameScreen(session: session, onboarding: false),
    ),
    GoRoute(
      path: '/server-status',
      builder: (_, _) => HealthScreen(api: api, database: database),
    ),
  ],
);
