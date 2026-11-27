import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart' show AppLifecycleListener, ValueNotifier;

import '../api/generated/cesta_api.dart';
import '../api/network.dart';
import '../db/app_database.dart';
import '../items/items_store.dart' hide HistoryEntry;
import 'network_status.dart';
import 'outbox.dart';

/// A change made on this device that the server refused. It has already been
/// rolled back locally when this is reported.
final class RejectedChange {
  const RejectedChange({required this.listId, required this.itemName, this.reason, this.limit});

  /// The List of the Item changed.
  final String listId;

  /// The Item's name as the device showed it before the rollback.
  final String itemName;

  /// Why, as the server said (e.g. `limit_exceeded`, `item_deleted`).
  final ApiErrorCode? reason;

  /// For `limit_exceeded`, how many Items a List can hold.
  final int? limit;
}

/// What changed about the User's Lists on this device, already saved: by a
/// pull, a change made here, or a change rolled back.
final class ListsChanged {
  const ListsChanged({this.gone = const {}, this.toBuy = const {}});

  /// Lists the User can no longer see (deleted).
  final Set<String> gone;

  /// The new count of Items to buy of each List whose Items changed, by List
  /// ID: what the device shows, changes waiting to sync included.
  final Map<String, int> toBuy;
}

/// How many Items a List can hold until the server says otherwise.
const defaultMaxItemsPerList = 500;

/// Brings the device and the server in step (ADR-0001): pushes the outbox,
/// then pulls what changed since the last cursor.
///
/// Once [start]ed it syncs straight away, when the app resumes, when the
/// phone's connection comes back, after each local change and whenever [sync]
/// is called (e.g. pull-to-refresh). When the server can't be reached it also
/// retries with exponential backoff.
class SyncEngine {
  SyncEngine({
    required this._api,
    required this._db,
    required this._items,
    required this._outbox,
    required this._network,
    this.firstRetry = const Duration(seconds: 1),
    this.maxRetry = const Duration(seconds: 60),
  });

  final ApiClient _api;
  final AppDatabase _db;
  final ItemsStore _items;
  final ChangeOutbox _outbox;
  final NetworkStatus _network;

  /// Backoff bounds between failed attempts.
  final Duration firstRetry;
  final Duration maxRetry;

  /// The most mutations one push carries (the API's limit).
  static const pushBatch = 100;

  final _rejections = StreamController<RejectedChange>.broadcast();

  /// Changes the server refused, after they were rolled back.
  Stream<RejectedChange> get rejections => _rejections.stream;

  final _listsChanged = StreamController<ListsChanged>.broadcast();

  /// What changed about the User's Lists, once saved on the device.
  Stream<ListsChanged> get listsChanged => _listsChanged.stream;

  /// Recounts run one after another, so each reads what the ones before it
  /// saw and their results arrive in order.
  Future<void> _recounting = Future.value();

  final _offline = ValueNotifier(false);

  /// True while the phone has no connection or the server can't be reached;
  /// false again once a sync gets through.
  ValueListenable<bool> get offline => _offline;

  final _itemLimit = ValueNotifier(defaultMaxItemsPerList);

  /// How many Items a List can hold: the server's limit, as it last reported it.
  ValueListenable<int> get itemLimit => _itemLimit;

  bool _started = false;

  /// Bumped by [stop]: a sync begun before then writes nothing more, so a
  /// pull still in flight at sign-out can't bring the old User's data back.
  int _generation = 0;
  bool _again = false;
  int _failures = 0;
  Future<void>? _current;
  Timer? _retry;
  StreamSubscription<String>? _localChanges;
  StreamSubscription<bool>? _networkChanges;
  AppLifecycleListener? _lifecycle;

  /// Starts syncing for the signed-in User. Safe to call more than once.
  void start() {
    if (_started) return;
    _started = true;
    _localChanges = _outbox.changes.listen((listId) {
      unawaited(_recount({listId}));
      unawaited(sync());
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(sync()));
    _networkChanges = _network.changes.listen(_networkChanged);
    unawaited(_network.isConnected().then((connected) => connected ? null : _offline.value = true));
    unawaited(sync());
  }

  void _networkChanged(bool connected) {
    if (!connected) {
      _offline.value = true;
      return;
    }
    // Back online: sync now rather than at the next backoff retry.
    _failures = 0;
    _retry?.cancel();
    _retry = null;
    unawaited(sync());
  }

  /// Stops syncing (sign out) and waits for a sync in flight to finish.
  Future<void> stop() async {
    _started = false;
    _generation++;
    _retry?.cancel();
    _retry = null;
    _failures = 0;
    _lifecycle?.dispose();
    _lifecycle = null;
    await _networkChanges?.cancel();
    _networkChanges = null;
    await _localChanges?.cancel();
    _localChanges = null;
    await _current;
  }

  /// Before signing out: pushes what this device still holds, held removals
  /// included, if the phone is online, waiting at most [timeout]. Best effort:
  /// whatever doesn't reach the server is lost with the session's data.
  Future<void> flush({Duration timeout = const Duration(seconds: 3)}) async {
    _outbox.releaseHolds();
    if (!_started || !await _network.isConnected()) return;
    await sync().timeout(timeout, onTimeout: () {});
  }

  /// Syncs now. When a sync is already running, another one follows it, and
  /// the returned future completes after that one.
  Future<void> sync() {
    if (!_started) return Future.value();
    if (_current case final current?) {
      _again = true;
      return current;
    }
    final run = _run();
    _current = run;
    return run.whenComplete(() => _current = null);
  }

  Future<void> _run() async {
    do {
      _again = false;
      if (!await _attempt()) {
        _scheduleRetry();
        return;
      }
      _failures = 0;
      _retry?.cancel();
      _retry = null;
    } while (_again && _started);
  }

  /// One push and pull; false when the server couldn't be reached or refused.
  Future<bool> _attempt() async {
    final generation = _generation;
    try {
      await _push(generation);
      await _pull(generation);
      if (generation != _generation) return true; // stopped meanwhile: nothing to retry
      _offline.value = false;
      return true;
    } on DioException catch (e) {
      if (isOffline(e)) _offline.value = true;
      return false;
    } catch (_) {
      // Offline, a timeout, 401/429, or an unexpected answer: try again later.
      return false;
    }
  }

  void _scheduleRetry() {
    if (!_started) return;
    _failures++;
    final factor = math.pow(2, math.min(_failures - 1, 16)).toInt();
    final delay = firstRetry * factor;
    _retry?.cancel();
    _retry = Timer(delay > maxRetry ? maxRetry : delay, () => unawaited(sync()));
  }

  /// Pushes the outbox, oldest change first.
  ///
  /// A push the server can't take right now (no connection, 5xx, 429, 401)
  /// throws, to be retried later. One it refuses for good (another 4xx, or
  /// an answer without a result for a change) must not block the outbox:
  /// the changes are then pushed one at a time, and each one still refused
  /// is rolled back and reported.
  Future<void> _push(int generation) async {
    bool stopped() => generation != _generation;
    var size = pushBatch;
    while (!stopped()) {
      final batch = await _outbox.unpushed(size);
      if (batch.isEmpty) return;
      try {
        size = await _settle(batch, await _send(batch), generation) ?? size;
      } finally {
        _outbox.settle(batch);
      }
    }
  }

  /// Marks applied or rolls back each change of [batch] by the server's
  /// [answer]; the batch size to push next when the answer can't say which
  /// change of a batch was refused.
  Future<int?> _settle(
    List<OutboxData> batch,
    ({Map<String, MutationResult> results, ApiErrorCode? refusal}) answer,
    int generation,
  ) async {
    // Changes a refused change took with it (a refused create's later
    // changes, a refused check's clear): their own results are moot.
    final dropped = <int>{};
    for (final row in batch) {
      if (generation != _generation) return null;
      if (dropped.contains(row.seq)) continue;
      final r = answer.results[row.mutationId];
      if (r == null) {
        if (batch.length > 1) return 1; // find which change it is
        dropped.addAll(await _rollBack(row, answer.refusal, null, generation));
      } else if (r.status == MutationResultStatus.applied) {
        await _outbox.markApplied(row);
      } else {
        dropped.addAll(await _rollBack(row, r.reason?.code, r.reason?.limit, generation));
      }
    }
    return null;
  }

  /// Sends [batch]; the results by mutation ID, or none and why when the
  /// server refused it as a whole. Throws when it should be tried again later.
  Future<({Map<String, MutationResult> results, ApiErrorCode? refusal})> _send(List<OutboxData> batch) async {
    try {
      return switch (await _api.pushMutations(body: PushRequest(mutations: [for (final m in batch) _mutation(m)]))) {
        PushMutations200(:final value) => (results: {for (final r in value.results) r.mutationId: r}, refusal: null),
        PushMutations400(:final value) => (results: const <String, MutationResult>{}, refusal: value.code),
        // Signed out, or too many requests: try again later.
        final other => throw _Refused(other),
      };
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null || status >= 500 || status == 408) rethrow;
      return (results: const <String, MutationResult>{}, refusal: null);
    }
  }

  static Mutation _mutation(OutboxData m) => Mutation(
    id: m.mutationId,
    type: m.type,
    entityId: m.itemId,
    listId: m.type == MutationType.itemCreate ? m.listId : null,
    // A remove or a clear carries nothing but the Item.
    fields: m.type == MutationType.itemDelete || m.type == MutationType.itemClear ? null : m.fields,
    clientTimestamp: DateTime.fromMicrosecondsSinceEpoch(m.clientTimestampMicros, isUtc: true),
  );

  /// Drops the refused change [row] and the changes that depended on it
  /// (see [ChangeOutbox.rollBack]), then reports it; the seqs dropped.
  /// [limit] comes with `limit_exceeded`.
  Future<Set<int>> _rollBack(OutboxData row, ApiErrorCode? reason, int? limit, int generation) async {
    final before = (await _items.readList(row.listId)).where((i) => i.id == row.itemId).firstOrNull?.name;
    if (generation != _generation) return const {};
    final dropped = await _outbox.rollBack(row);
    // A removed or cleared Item shows again once its change is rolled back.
    final name =
        before ??
        (await _items.readList(row.listId)).where((i) => i.id == row.itemId).firstOrNull?.name ??
        row.fields.name ??
        '';
    unawaited(_recount({row.listId}));
    if (limit != null) _itemLimit.value = limit;
    _rejections.add(RejectedChange(listId: row.listId, itemName: name, reason: reason, limit: limit));
    return dropped;
  }

  Future<void> _pull(int generation) async {
    bool stopped() => generation != _generation;
    var cursor = (await (_db.select(_db.syncCursor)..where((t) => t.id.equals(1))).getSingleOrNull())?.cursor;
    while (!stopped()) {
      final result = await _api.pullChanges(cursor: cursor);
      final page = switch (result) {
        PullChanges200(:final value) => value,
        _ => throw _Refused(result),
      };
      final gone = <String>{};
      final touched = <String>{};
      await _db.transaction(() async {
        // Checked inside the transaction: data cleared at sign-out waits for it.
        if (stopped()) return;
        for (final item in page.items) {
          await _db.into(_db.syncedItems).insertOnConflictUpdate(_row(item));
          touched.add(item.listId);
        }
        for (final entry in page.history) {
          await _db.into(_db.syncedHistory).insertOnConflictUpdate(_historyRow(entry));
        }
        for (final t in page.tombstones) {
          switch (t.type) {
            case TombstoneType.item:
              await (_db.delete(_db.syncedItems)..where((r) => r.id.equals(t.id))).go();
              if (t.listId case final listId?) touched.add(listId);
            case TombstoneType.list:
              await (_db.delete(_db.syncedItems)..where((r) => r.listId.equals(t.id))).go();
              await (_db.delete(_db.syncedHistory)..where((r) => r.listId.equals(t.id))).go();
              await _outbox.dropList(t.id);
              await _db.forgetKnownList(t.id);
              gone.add(t.id);
          }
        }
        await _db
            .into(_db.syncCursor)
            .insertOnConflictUpdate(SyncCursorCompanion.insert(id: const Value(1), cursor: page.cursor));
        // The pull now reflects every change the server applied, so their
        // overlays can go without the display flickering back.
        if (!page.hasMore) await _outbox.dropApplied();
      });
      if (stopped()) return;
      if (gone.isNotEmpty) _listsChanged.add(ListsChanged(gone: gone));
      // Lists whose Items changed: recount their Items to buy.
      unawaited(_recount(touched.difference(gone)));
      cursor = page.cursor;
      if (!page.hasMore) return;
    }
  }

  /// Counts the Items to buy of [listIds] as the device shows them, saves
  /// the counts and reports them.
  Future<void> _recount(Set<String> listIds) {
    if (listIds.isEmpty) return _recounting;
    final generation = _generation;
    return _recounting = _recounting
        .then((_) async {
          if (generation != _generation) return;
          final toBuy = {for (final id in listIds) id: await _items.toBuyCount(id)};
          if (generation != _generation) return;
          await _db.saveToBuyCounts(toBuy);
          if (!_listsChanged.isClosed) _listsChanged.add(ListsChanged(toBuy: toBuy));
        })
        .catchError((Object _) {}); // a count is redone at the next change or pull
  }

  static SyncedItemsCompanion _row(Item i) => SyncedItemsCompanion.insert(
    id: i.id,
    listId: i.listId,
    name: i.name,
    quantity: Value(i.quantity?.value),
    unit: Value(i.unit?.value?.toJson()),
    note: Value(i.note?.value),
    addedById: i.addedBy.id,
    addedByName: i.addedBy.displayName,
    addedAtMicros: i.addedAt.microsecondsSinceEpoch,
    checkedAtMicros: Value(i.checkedAt?.value?.microsecondsSinceEpoch),
    checkedById: Value(i.checkedBy?.value?.id),
    checkedByName: Value(i.checkedBy?.value?.displayName),
  );

  static SyncedHistoryCompanion _historyRow(HistoryEntry e) => SyncedHistoryCompanion.insert(
    itemId: e.itemId,
    listId: e.listId,
    name: e.name,
    quantity: Value(e.quantity),
    unit: Value(e.unit?.toJson()),
    note: Value(e.note),
    clearedAtMicros: e.clearedAt.microsecondsSinceEpoch,
    clearedById: e.clearedBy.id,
    clearedByName: e.clearedBy.displayName,
  );

  Future<void> dispose() async {
    await stop();
    await _rejections.close();
    await _recounting;
    await _listsChanged.close();
    _offline.dispose();
    _itemLimit.dispose();
  }
}

/// The server answered a sync call with an error status.
final class _Refused implements Exception {
  const _Refused(this.result);

  final Object result;

  @override
  String toString() => 'Sync refused: $result';
}
