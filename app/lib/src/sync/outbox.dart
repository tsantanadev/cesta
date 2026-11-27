import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';

/// The signed-in User making a change, recorded with it so the change shows
/// who made it before the server confirms it. Also who added or checked an
/// Item, as the server reports it.
typedef Actor = ({String id, String displayName});

/// The outbox of this device's changes not yet confirmed by the server
/// (ADR-0001), and the only reader and writer of its rows: changes are
/// enqueued here, marked applied when the server confirms them, and dropped
/// when refused, undone or once a pull reflects them.
class ChangeOutbox {
  ChangeOutbox(this._db);

  final AppDatabase _db;
  final _changes = StreamController<String>.broadcast();

  /// The changes being pushed right now ([unpushed] until [settle]), by
  /// [OutboxData.seq]: they may reach the server whatever this device does,
  /// so undoing one can't just drop it.
  final _inFlight = <int>{};

  /// Items whose removal is held out of the push while Undo is offered, so
  /// undoing it just drops it, with how many holds each has (removed, undone
  /// and removed again overlap). Kept in memory only: once the app is gone,
  /// so is the Undo, and the removal is pushed at the next sync.
  final _heldRemovals = <String, int>{};

  static const _uuid = Uuid();

  /// Fires with the List's ID after every change to its Items enqueued or
  /// dropped on this device.
  Stream<String> get changes => _changes.stream;

  /// Adds a change to Item [itemId] of List [listId].
  Future<void> enqueue(
    MutationType type, {
    required String itemId,
    required String listId,
    required Actor by,
    required ItemFields fields,
  }) async {
    await _db
        .into(_db.outbox)
        .insert(
          OutboxCompanion.insert(
            mutationId: _uuid.v4(),
            type: type,
            itemId: itemId,
            listId: listId,
            fields: fields,
            clientTimestampMicros: DateTime.now().toUtc().microsecondsSinceEpoch,
            byId: by.id,
            byName: by.displayName,
          ),
        );
    _changes.add(listId);
  }

  /// Enqueues the removal of Item [itemId] of List [listId], held out of the
  /// push until [until] completes (or fails).
  Future<void> enqueueHeldRemoval({
    required String itemId,
    required String listId,
    required Actor by,
    required Future<void> until,
  }) async {
    _heldRemovals.update(itemId, (n) => n + 1, ifAbsent: () => 1);
    unawaited(
      until.catchError((Object _) {}).whenComplete(() {
        if (_heldRemovals.update(itemId, (n) => n - 1) == 0) _heldRemovals.remove(itemId);
        // Pushes it now, unless it was undone meanwhile (nothing then to push).
        if (!_changes.isClosed) _changes.add(listId);
      }),
    );
    await enqueue(MutationType.itemDelete, itemId: itemId, listId: listId, by: by, fields: const ItemFields());
  }

  /// Drops every change to Item [itemId] while its creation is still waiting
  /// to be pushed, so the Item never reaches the server; false when it can't
  /// (it was pushed, or is being pushed).
  Future<bool> dropPendingCreate(String itemId) =>
      _dropWaiting(itemId, MutationType.itemCreate, (t) => t.itemId.equals(itemId) & t.applied.equals(false));

  /// Drops the removal of Item [itemId] while it is still waiting to be
  /// pushed; false when there is none (or it is being pushed).
  Future<bool> dropPendingRemoval(String itemId) => _dropWaiting(
    itemId,
    MutationType.itemDelete,
    (t) => t.itemId.equals(itemId) & t.type.equalsValue(MutationType.itemDelete) & t.applied.equals(false),
  );

  /// When a [type] change to [itemId] is waiting and none of its changes are
  /// in flight, drops the rows [drop] picks.
  Future<bool> _dropWaiting(String itemId, MutationType type, Expression<bool> Function($OutboxTable t) drop) async {
    final listId = await _db.transaction(() async {
      final waiting = await (_db.select(
        _db.outbox,
      )..where((t) => t.itemId.equals(itemId) & t.applied.equals(false))).get();
      if (!waiting.any((r) => r.type == type) || waiting.any((r) => _inFlight.contains(r.seq))) return null;
      return await (_db.delete(_db.outbox)..where(drop)).go() > 0 ? waiting.first.listId : null;
    });
    if (listId != null) _changes.add(listId);
    return listId != null;
  }

  /// The oldest [limit] changes not yet pushed and not held, now in flight
  /// until [settle].
  Future<List<OutboxData>> unpushed(int limit) async {
    final batch =
        await (_db.select(_db.outbox)
              ..where(
                (t) =>
                    t.applied.equals(false) &
                    (t.itemId.isNotIn(_heldRemovals.keys) | t.type.equalsValue(MutationType.itemDelete).not()),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.seq)])
              ..limit(limit))
            .get();
    _inFlight.addAll(batch.map((r) => r.seq));
    return batch;
  }

  /// The push of [batch] is over: what's left of it can be undone again.
  void settle(List<OutboxData> batch) => _inFlight.removeAll(batch.map((r) => r.seq));

  /// Every change to List [listId] still in the outbox, oldest first.
  Future<List<OutboxData>> forList(String listId) =>
      (_db.select(_db.outbox)
            ..where((t) => t.listId.equals(listId))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
          .get();

  /// How many changes to List [listId] are waiting to reach the server;
  /// emits on change.
  Stream<int> watchWaiting(String listId) {
    final count = _db.outbox.seq.count();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.listId.equals(listId) & _db.outbox.applied.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// The server applied [change]; it stays shown until a pull reflects it.
  Future<void> markApplied(OutboxData change) => (_db.update(
    _db.outbox,
  )..where((t) => t.seq.equals(change.seq))).write(const OutboxCompanion(applied: Value(true)));

  /// Drops the refused [change] and, for a refused create, every later change
  /// to that Item.
  Future<void> rollBack(OutboxData change) =>
      (_db.delete(_db.outbox)..where(
            (t) => change.type == MutationType.itemCreate
                ? t.itemId.equals(change.itemId) & t.applied.equals(false)
                : t.seq.equals(change.seq),
          ))
          .go();

  /// Drops every change to List [listId], which is gone.
  Future<void> dropList(String listId) => (_db.delete(_db.outbox)..where((t) => t.listId.equals(listId))).go();

  /// Drops the changes the server applied, once a pull reflects them all.
  Future<void> dropApplied() => (_db.delete(_db.outbox)..where((t) => t.applied.equals(true))).go();

  void dispose() => unawaited(_changes.close());
}
