import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'api/generated/cesta_api.dart';
import 'auth/auth_gateway.dart';
import 'db/app_database.dart';
import 'items/items_store.dart';
import 'lists/lists_controller.dart';
import 'router.dart';
import 'session/session_controller.dart';
import 'sync/sync_engine.dart';
import 'ui/components.dart';
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
  late final ItemsStore _items;
  late final SyncEngine _sync;
  late final GoRouter _router;
  late final StreamSubscription<RejectedChange> _rejections;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _session = SessionController(auth: widget.auth, api: widget.api, db: widget.database)..start();
    _lists = ListsController(api: widget.api, db: widget.database, session: _session);
    _items = ItemsStore(widget.database);
    _sync = SyncEngine(api: widget.api, db: widget.database, items: _items);
    _session.addListener(_followSession);
    _rejections = _sync.rejections.listen(_tellRejected);
    _router = buildRouter(
      session: _session,
      lists: _lists,
      items: _items,
      sync: _sync,
      auth: widget.auth,
      api: widget.api,
      database: widget.database,
      initialLocation: widget.initialLocation,
    );
  }

  /// Syncs while a User is signed in.
  void _followSession() {
    if (_session.status == SessionStatus.signedIn && _session.user != null) {
      _sync.start();
    } else {
      unawaited(_sync.stop());
    }
  }

  /// Says that a change was rolled back. A placeholder until the rejected-change
  /// message is designed (#7 design gap).
  void _tellRejected(RejectedChange change) {
    final messenger = _messenger.currentState;
    if (messenger == null) return;
    final l10n = AppLocalizations.of(messenger.context);
    showCesToastOn(messenger, message: l10n.errorItemRejected(change.itemName));
  }

  @override
  void dispose() {
    unawaited(_rejections.cancel());
    _session.removeListener(_followSession);
    unawaited(_sync.dispose());
    _items.dispose();
    _router.dispose();
    _lists.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    scaffoldMessengerKey: _messenger,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: CestaTheme.light(),
    darkTheme: CestaTheme.dark(),
    themeMode: widget.themeMode,
    locale: widget.locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
  );
}
