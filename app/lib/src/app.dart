import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'api/generated/cesta_api.dart';
import 'auth/auth_gateway.dart';
import 'db/app_database.dart';
import 'lists/lists_controller.dart';
import 'router.dart';
import 'session/session_controller.dart';
import 'ui/theme.dart';

/// The Cesta app. Its dependencies are passed in so tests can supply an
/// in-memory database, a fake API client and a fake identity provider.
class CestaApp extends StatefulWidget {
  const CestaApp({
    super.key,
    required this.api,
    required this.auth,
    required this.database,
    this.locale,
    this.themeMode = ThemeMode.system,
    this.initialLocation,
  });

  final ApiClient api;
  final AuthGateway auth;
  final AppDatabase database;

  /// Forces a locale; null follows the device.
  final Locale? locale;
  final ThemeMode themeMode;

  /// The route to open first (tests); the session may redirect it.
  final String? initialLocation;

  @override
  State<CestaApp> createState() => _CestaAppState();
}

class _CestaAppState extends State<CestaApp> {
  late final SessionController _session;
  late final ListsController _lists;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = SessionController(auth: widget.auth, api: widget.api, db: widget.database)..start();
    _lists = ListsController(api: widget.api, db: widget.database, session: _session);
    _router = buildRouter(
      session: _session,
      lists: _lists,
      auth: widget.auth,
      api: widget.api,
      database: widget.database,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _lists.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: CestaTheme.light(),
    darkTheme: CestaTheme.dark(),
    themeMode: widget.themeMode,
    locale: widget.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  );
}
