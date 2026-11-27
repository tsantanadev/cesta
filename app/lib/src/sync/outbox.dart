import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';

/// The signed-in User making a change, recorded with it so the change shows
/// who made it before the server confirms it.
typedef Actor = ({String id, String displayName});

/// The outbox of this device's changes not yet confirmed by the server
/// (ADR-0001), and the only writer of its rows: changes are enqueued here,
/// marked applied when the server confirms them, and dropped when refused,
/// undone or once a pull reflects them.
class ChangeOutbox {
  ChangeOutbox(this._db);

  final AppDatabase _db;
  final _changes = StreamController<void>.broadcast();

  static const _uuid = Uuid();

  /// Fires after every change enqueued or dropped on this device.
  Stream<void> get changes => _changes.stream;

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
            type: type.toJson(),
            itemId: itemId,
            listId: listId,
            fields: jsonEncode(fields.toJson()),
            clientTimestampMicros: DateTime.now().toUtc().microsecondsSinceEpoch,
            byId: by.id,
            byName: by.displayName,
          ),
        );
    _changes.add(null);
  }

  /// Drops the removal of Item [itemId] while it is still waiting to be
  /// pushed; false when there is none.
  Future<bool> dropPendingRemoval(String itemId) async {
    final dropped =
        await (_db.delete(_db.outbox)..where(
              (t) =>
                  t.itemId.equals(itemId) & t.type.equals(MutationType.itemDelete.toJson()) & t.applied.equals(false),
            ))
            .go();
    if (dropped > 0) _changes.add(null);
    return dropped > 0;
  }

  /// The oldest [limit] changes not yet pushed.
  Future<List<OutboxData>> unpushed(int limit) =>
      (_db.select(_db.outbox)
            ..where((t) => t.applied.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .get();

  /// The server applied [change]; it stays shown until a pull reflects it.
  Future<void> markApplied(OutboxData change) => (_db.update(
    _db.outbox,
  )..where((t) => t.seq.equals(change.seq))).write(const OutboxCompanion(applied: Value(true)));

  /// Drops the refused [change] and, for a refused create, every later change
  /// to that Item.
  Future<void> rollBack(OutboxData change) =>
      (_db.delete(_db.outbox)..where(
            (t) => change.type == MutationType.itemCreate.toJson()
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
