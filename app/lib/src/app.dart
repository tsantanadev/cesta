import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'api/generated/cesta_api.dart';
import 'auth/auth_gateway.dart';
import 'db/app_database.dart';
import 'items/item_limit_sheet.dart';
import 'items/items_store.dart';
import 'lists/lists_controller.dart';
import 'pending_link.dart';
import 'router.dart';
import 'session/session_controller.dart';
import 'sharing/sharing.dart';
import 'sync/network_status.dart';
import 'sync/outbox.dart';
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
    required this.network,
    this.locale,
    this.themeMode = ThemeMode.system,
    this.initialLocation,
  });

  final ApiClient api;
  final AuthGateway auth;
  final AppDatabase database;
  final NetworkStatus network;

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
  late final ChangeOutbox _outbox;
  late final ItemsStore _items;
  late final SyncEngine _sync;
  late final GoRouter _router;
  late final StreamSubscription<RejectedChange> _rejections;
  late final StreamSubscription<ListsChanged> _listsChanged;
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _session = SessionController(auth: widget.auth, api: widget.api, db: widget.database)..start();
    _lists = ListsController(api: widget.api, db: widget.database, session: _session);
    _outbox = ChangeOutbox(widget.database);
    _items = ItemsStore(widget.database, _outbox);
    _sync = SyncEngine(api: widget.api, db: widget.database, items: _items, outbox: _outbox, network: widget.network);
    _session
      ..beforeSignOut = _beforeSignOut
      ..addListener(_followSession);
    _rejections = _sync.rejections.listen(_tellRejected);
    _listsChanged = _sync.listsChanged.listen((c) => _lists.changed(gone: c.gone, toBuy: c.toBuy));
    final pending = PendingLink(widget.database);
    unawaited(pending.restore());
    _router = buildRouter(
      session: _session,
      lists: _lists,
      items: _items,
      sync: _sync,
      auth: widget.auth,
      api: widget.api,
      database: widget.database,
      pending: pending,
      sharing: Sharing(api: widget.api),
      initialLocation: widget.initialLocation,
    );
  }

  /// Syncs while a User is signed in; signing out takes away any Toast.
  void _followSession() {
    if (_session.status == SessionStatus.signedIn && _session.user != null) {
      _sync.start();
    } else {
      unawaited(_sync.stop());
      // An Undo belongs to the session that made the change.
      _messenger.currentState?.removeCurrentSnackBar();
    }
  }

  /// Takes away the Undo and pushes what's left to sync, so a removal held
  /// for Undo isn't lost with the session's data.
  Future<void> _beforeSignOut() async {
    _messenger.currentState?.removeCurrentSnackBar();
    await _sync.flush();
  }

  /// The context of the router's navigator, once it is built.
  BuildContext? get _routerContext => _router.routerDelegate.navigatorKey.currentContext;

  /// Clears the Checked Items of List [listId] as the signed-in User.
  void _clearChecked(String listId) => _session.asMe((me) => unawaited(_items.clearChecked(listId: listId, by: me)));

  /// Says that a change was rolled back (Figma "13b Change not saved"
  /// 38:2815). A create refused because the List is full opens the Item limit
  /// sheet instead (Figma "14 Item limit").
  void _tellRejected(RejectedChange change) {
    if (change.reason == ApiErrorCode.limitExceeded && _routerContext != null) {
      unawaited(_showItemLimit(change));
      return;
    }
    _toastRejected(change);
  }

  /// Opens the Item limit sheet for the List [change] was refused on,
  /// offering Clear checked when it has Checked Items.
  Future<void> _showItemLimit(RejectedChange change) async {
    final items = await _items.readList(change.listId);
    if (_routerContext case final context? when context.mounted) {
      await showItemLimitSheet(
        context,
        limit: change.limit ?? _sync.itemLimit.value,
        items: items,
        onClearChecked: () => _clearChecked(change.listId),
      );
    } else {
      _toastRejected(change);
    }
  }

  void _toastRejected(RejectedChange change) {
    final messenger = _messenger.currentState;
    if (messenger == null) return;
    final l10n = AppLocalizations.of(messenger.context);
    final name = change.itemName;
    showCesToastOn(
      messenger,
      message: switch (change.reason) {
        ApiErrorCode.itemDeleted || ApiErrorCode.itemNotFound => l10n.itemRejectedRemoved(name),
        ApiErrorCode.listDeleted || ApiErrorCode.listNotFound => l10n.itemRejectedListGone(name),
        ApiErrorCode.itemNotChecked => l10n.itemRejectedNotChecked(name),
        _ => l10n.itemRejected(name),
      },
    );
  }

  @override
  void dispose() {
    unawaited(_rejections.cancel());
    unawaited(_listsChanged.cancel());
    _session.removeListener(_followSession);
    unawaited(_sync.dispose());
    _outbox.dispose();
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
