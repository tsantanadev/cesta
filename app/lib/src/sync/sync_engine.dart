import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart' show AppLifecycleListener, ValueNotifier;

import '../api/generated/cesta_api.dart';
import '../api/network.dart';
import '../db/app_database.dart';
import '../items/items_store.dart';
import 'network_status.dart';

/// A change made on this device that the server refused. It has already been
/// rolled back locally when this is reported.
final class RejectedChange {
  const RejectedChange({required this.type, required this.itemName, required this.listId, this.reason});

  final MutationType type;

  /// The Item's name as the device showed it before the rollback.
  final String itemName;
  final String listId;

  /// Why, as the server said (e.g. `limit_exceeded`, `item_deleted`).
  final ApiErrorCode? reason;
}

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
    required this._network,
    this.firstRetry = const Duration(seconds: 1),
    this.maxRetry = const Duration(seconds: 60),
  });

  final ApiClient _api;
  final AppDatabase _db;
  final ItemsStore _items;
  final NetworkStatus _network;

  /// Backoff bounds between failed attempts.
  final Duration firstRetry;
  final Duration maxRetry;

  /// The most mutations one push carries (the API's limit).
  static const pushBatch = 100;

  final _rejections = StreamController<RejectedChange>.broadcast();

  /// Changes the server refused, after they were rolled back.
  Stream<RejectedChange> get rejections => _rejections.stream;

  final _offline = ValueNotifier(false);

  /// True while the phone has no connection or the server can't be reached;
  /// false again once a sync gets through.
  ValueListenable<bool> get offline => _offline;

  bool _started = false;

  /// Bumped by [stop]: a sync begun before then writes nothing more, so a
  /// pull still in flight at sign-out can't bring the old User's data back.
  int _generation = 0;
  bool _again = false;
  int _failures = 0;
  Future<void>? _current;
  Timer? _retry;
  StreamSubscription<void>? _localChanges;
  StreamSubscription<bool>? _networkChanges;
  AppLifecycleListener? _lifecycle;

  /// Starts syncing for the signed-in User. Safe to call more than once.
  void start() {
    if (_started) return;
    _started = true;
    _localChanges = _items.changes.listen((_) => unawaited(sync()));
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
      final batch =
          await (_db.select(_db.outbox)
                ..where((t) => t.applied.equals(false))
                ..orderBy([(t) => OrderingTerm.asc(t.seq)])
                ..limit(size))
              .get();
      if (batch.isEmpty) return;
      final answer = await _send(batch);
      if (stopped()) return;
      // Items whose refused create took their later changes with it: those
      // changes' own results are moot and already reported.
      final droppedItems = <String>{};
      for (final row in batch) {
        if (stopped()) return;
        if (droppedItems.contains(row.itemId)) continue;
        final r = answer.results[row.mutationId];
        if (r == null) {
          if (batch.length > 1) {
            size = 1; // find which change it is
            break;
          }
          await _rollBack(row, answer.refusal);
        } else if (r.status == MutationResultStatus.applied) {
          await (_db.update(
            _db.outbox,
          )..where((t) => t.seq.equals(row.seq))).write(const OutboxCompanion(applied: Value(true)));
          continue;
        } else {
          await _rollBack(row, r.reason?.code);
        }
        if (row.type == MutationType.itemCreate.toJson()) droppedItems.add(row.itemId);
      }
    }
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

  static Mutation _mutation(OutboxData m) {
    final type = MutationType.fromJson(m.type);
    return Mutation(
      id: m.mutationId,
      type: type,
      entityId: m.itemId,
      listId: type == MutationType.itemCreate ? m.listId : null,
      fields: type == MutationType.itemDelete
          ? null
          : ItemFields.fromJson(jsonDecode(m.fields) as Map<String, Object?>),
      clientTimestamp: DateTime.fromMicrosecondsSinceEpoch(m.clientTimestampMicros, isUtc: true),
    );
  }

  /// Drops the refused change [row] (and, for a refused create, every later
  /// change to that Item), then reports it.
  Future<void> _rollBack(OutboxData row, ApiErrorCode? reason) async {
    final shown = await _items.readList(row.listId);
    final name =
        shown.where((i) => i.id == row.itemId).firstOrNull?.name ??
        ItemFields.fromJson(jsonDecode(row.fields) as Map<String, Object?>).name ??
        '';
    final type = MutationType.fromJson(row.type);
    await (_db.delete(_db.outbox)..where(
          (t) => type == MutationType.itemCreate
              ? t.itemId.equals(row.itemId) & t.applied.equals(false)
              : t.seq.equals(row.seq),
        ))
        .go();
    _rejections.add(RejectedChange(type: type, itemName: name, listId: row.listId, reason: reason));
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
      await _db.transaction(() async {
        // Checked inside the transaction: data cleared at sign-out waits for it.
        if (stopped()) return;
        for (final item in page.items) {
          await _db.into(_db.syncedItems).insertOnConflictUpdate(_row(item));
        }
        for (final t in page.tombstones) {
          switch (t.type) {
            case TombstoneType.item:
              await (_db.delete(_db.syncedItems)..where((r) => r.id.equals(t.id))).go();
            case TombstoneType.list:
              await (_db.delete(_db.syncedItems)..where((r) => r.listId.equals(t.id))).go();
              await (_db.delete(_db.outbox)..where((r) => r.listId.equals(t.id))).go();
              await _db.forgetKnownList(t.id);
          }
        }
        await _db
            .into(_db.syncCursor)
            .insertOnConflictUpdate(SyncCursorCompanion.insert(id: const Value(1), cursor: page.cursor));
        // The pull now reflects every change the server applied, so their
        // overlays can go without the display flickering back.
        if (!page.hasMore) await (_db.delete(_db.outbox)..where((t) => t.applied.equals(true))).go();
      });
      cursor = page.cursor;
      if (!page.hasMore) return;
    }
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

  Future<void> dispose() async {
    await stop();
    await _rejections.close();
    _offline.dispose();
  }
}

/// The server answered a sync call with an error status.
final class _Refused implements Exception {
  const _Refused(this.result);

  final Object result;

  @override
  String toString() => 'Sync refused: $result';
}
