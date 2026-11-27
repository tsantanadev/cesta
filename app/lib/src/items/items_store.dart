import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';
import '../sync/outbox.dart';

export '../sync/outbox.dart' show Actor;

/// An Item as the app shows it: what the server last reported, with the
/// device's changes not yet confirmed applied on top.
final class ShownItem {
  const ShownItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.addedAt,
    required this.addedById,
    required this.addedByName,
    this.quantity,
    this.unit,
    this.note,
    this.checkedAt,
    this.checkedById,
    this.checkedByName,
    this.pending = false,
  });

  final String id;
  final String listId;
  final String name;

  /// A positive decimal as the API writes it, e.g. "1.5"; null when not given.
  final String? quantity;
  final ItemUnit? unit;
  final String? note;
  final DateTime addedAt;

  /// Who added it, as the server (or, before it confirms, this device) says.
  final String addedById;
  final String addedByName;

  /// When the Item was checked (it is In the basket); null while it is to buy.
  final DateTime? checkedAt;
  final String? checkedById;
  final String? checkedByName;

  /// True while a change to it is waiting to reach the server.
  final bool pending;

  bool get checked => checkedAt != null;

  /// A copy with [fields] applied, as an item_update would: a field present
  /// in [fields] replaces the current value, and a present null clears it.
  ShownItem _updated(
    ItemFields fields, {
    required DateTime at,
    required String byId,
    required String byName,
    required bool pending,
  }) => ShownItem(
    id: id,
    listId: listId,
    name: fields.name ?? name,
    addedAt: addedAt,
    addedById: addedById,
    addedByName: addedByName,
    quantity: fields.quantity == null ? quantity : fields.quantity!.value,
    unit: fields.unit == null ? unit : _unit(fields.unit!.value),
    note: fields.note == null ? note : fields.note!.value,
    checkedAt: switch (fields.checked) {
      true => at,
      false => null,
      null => checkedAt,
    },
    checkedById: switch (fields.checked) {
      true => byId,
      false => null,
      null => checkedById,
    },
    checkedByName: switch (fields.checked) {
      true => byName,
      false => null,
      null => checkedByName,
    },
    pending: pending,
  );
}

ItemUnit? _unit(ItemFieldsUnit? u) => u == null ? null : ItemUnit.fromJson(u.toJson());

/// The device's Items (the display's source of truth) with the outbox of
/// changes to them on top (ADR-0001).
///
/// Changes go into the [ChangeOutbox] and show at once; the sync engine
/// pushes them from there.
class ItemsStore {
  ItemsStore(this._db, this._outbox);

  final AppDatabase _db;
  final ChangeOutbox _outbox;

  static const _uuid = Uuid();

  /// The Items of List [listId] as they should be shown, in insertion order;
  /// emits again whenever they change.
  Stream<List<ShownItem>> watchList(String listId) =>
      _db.customSelect('SELECT 1', readsFrom: {_db.syncedItems, _db.outbox}).watch().asyncMap((_) => readList(listId));

  Future<List<ShownItem>> readList(String listId) => _db.transaction(() async {
    final synced = await (_db.select(_db.syncedItems)..where((t) => t.listId.equals(listId))).get();
    final pending =
        await (_db.select(_db.outbox)
              ..where((t) => t.listId.equals(listId))
              ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
            .get();
    return showItems(synced, pending);
  });

  /// How many changes to List [listId] are waiting to reach the server;
  /// emits on change.
  Stream<int> watchPendingCount(String listId) {
    final count = _db.outbox.seq.count();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.listId.equals(listId) & _db.outbox.applied.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Adds a new Item to List [listId]; returns its ID.
  Future<String> add({
    required String listId,
    required Actor by,
    required String name,
    String? quantity,
    ItemUnit? unit,
    String? note,
  }) async {
    final id = _uuid.v4();
    await _outbox.enqueue(
      MutationType.itemCreate,
      itemId: id,
      listId: listId,
      by: by,
      fields: ItemFields(
        name: name.trim(),
        quantity: quantity == null ? null : (value: quantity),
        unit: unit == null ? null : (value: ItemFieldsUnit.fromJson(unit.toJson())),
        note: _note(note) == null ? null : (value: _note(note)),
      ),
    );
    return id;
  }

  /// Edits [item]: its name, and how much and the note, which are cleared
  /// when null. Only what changed is sent.
  Future<void> update(
    ShownItem item, {
    required Actor by,
    required String name,
    String? quantity,
    ItemUnit? unit,
    String? note,
  }) {
    final trimmed = name.trim();
    final cleanNote = _note(note);
    final fields = ItemFields(
      name: trimmed == item.name ? null : trimmed,
      quantity: quantity == item.quantity ? null : (value: quantity),
      unit: unit == item.unit ? null : (value: unit == null ? null : ItemFieldsUnit.fromJson(unit.toJson())),
      note: cleanNote == item.note ? null : (value: cleanNote),
    );
    if (fields.toJson().isEmpty) return Future.value();
    return _outbox.enqueue(MutationType.itemUpdate, itemId: item.id, listId: item.listId, by: by, fields: fields);
  }

  static String? _note(String? note) => (note?.trim().isEmpty ?? true) ? null : note!.trim();

  /// Checks [item] (puts it In the basket), or unchecks it when [checked] is false.
  Future<void> setChecked(ShownItem item, {required bool checked, required Actor by}) => _outbox.enqueue(
    MutationType.itemUpdate,
    itemId: item.id,
    listId: item.listId,
    by: by,
    fields: ItemFields(checked: checked),
  );

  /// Removes Item [itemId] from List [listId].
  Future<void> remove({required String itemId, required String listId, required Actor by}) =>
      _outbox.enqueue(MutationType.itemDelete, itemId: itemId, listId: listId, by: by, fields: const ItemFields());

  /// Undoes the removal of [item]: drops the removal while it is still
  /// waiting to sync, or else adds the Item again as it was (the server keeps
  /// removed Items removed, so it comes back as a new Item).
  Future<void> restore(ShownItem item, {required Actor by}) async {
    if (await _outbox.dropPendingRemoval(item.id)) return;
    final id = await add(
      listId: item.listId,
      by: by,
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      note: item.note,
    );
    if (item.checked) {
      await _outbox.enqueue(
        MutationType.itemUpdate,
        itemId: id,
        listId: item.listId,
        by: by,
        fields: const ItemFields(checked: true),
      );
    }
  }
}

/// [synced] Items with the [pending] outbox changes (oldest first) applied on top.
List<ShownItem> showItems(List<SyncedItem> synced, List<OutboxData> pending) {
  final items = <String, ShownItem>{for (final r in synced) r.id: _fromRow(r)};
  for (final m in pending) {
    final fields = ItemFields.fromJson(jsonDecode(m.fields) as Map<String, Object?>);
    final at = DateTime.fromMicrosecondsSinceEpoch(m.clientTimestampMicros, isUtc: true);
    switch (MutationType.fromJson(m.type)) {
      case MutationType.itemCreate:
        items.putIfAbsent(
          m.itemId,
          () => ShownItem(
            id: m.itemId,
            listId: m.listId,
            name: fields.name ?? '',
            addedAt: at,
            addedById: m.byId,
            addedByName: m.byName,
            quantity: fields.quantity?.value,
            unit: _unit(fields.unit?.value),
            note: fields.note?.value,
            pending: !m.applied,
          ),
        );
      case MutationType.itemUpdate:
        final item = items[m.itemId];
        if (item == null) continue;
        items[m.itemId] = item._updated(
          fields,
          at: at,
          byId: m.byId,
          byName: m.byName,
          pending: item.pending || !m.applied,
        );
      case MutationType.itemDelete:
        items.remove(m.itemId);
    }
  }
  return items.values.toList()..sort((a, b) {
    final byTime = a.addedAt.compareTo(b.addedAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
}

ShownItem _fromRow(SyncedItem r) => ShownItem(
  id: r.id,
  listId: r.listId,
  name: r.name,
  addedAt: DateTime.fromMicrosecondsSinceEpoch(r.addedAtMicros, isUtc: true),
  addedById: r.addedById,
  addedByName: r.addedByName,
  quantity: r.quantity,
  unit: r.unit == null ? null : ItemUnit.fromJson(r.unit),
  note: r.note,
  checkedAt: r.checkedAtMicros == null ? null : DateTime.fromMicrosecondsSinceEpoch(r.checkedAtMicros!, isUtc: true),
  checkedById: r.checkedById,
  checkedByName: r.checkedByName,
);
