import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';

/// An Item as the app shows it: what the server last reported, with the
/// device's changes not yet confirmed applied on top.
final class ShownItem {
  const ShownItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.addedAt,
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

  /// When the Item was checked (it is In the basket); null while it is to buy.
  final DateTime? checkedAt;
  final String? checkedById;
  final String? checkedByName;

  /// True while a change to it is waiting to reach the server.
  final bool pending;

  bool get checked => checkedAt != null;

  ShownItem _copy({
    String? name,
    String? quantity,
    ItemUnit? unit,
    String? note,
    (DateTime, String, String)? checked,
    bool uncheck = false,
    bool? pending,
  }) => ShownItem(
    id: id,
    listId: listId,
    name: name ?? this.name,
    addedAt: addedAt,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    note: note ?? this.note,
    checkedAt: uncheck ? null : (checked?.$1 ?? checkedAt),
    checkedById: uncheck ? null : (checked?.$2 ?? checkedById),
    checkedByName: uncheck ? null : (checked?.$3 ?? checkedByName),
    pending: pending ?? this.pending,
  );
}

/// The signed-in User making a change, recorded with it so the change shows
/// who made it before the server confirms it.
typedef Actor = ({String id, String displayName});

/// The device's Items (the display's source of truth) and the outbox of
/// changes to them (ADR-0001).
///
/// Changes are written to the outbox and show at once; [changes] fires after
/// each so the sync engine can push it.
class ItemsStore {
  ItemsStore(this._db);

  final AppDatabase _db;
  final _changes = StreamController<void>.broadcast();

  /// Fires after every local change.
  Stream<void> get changes => _changes.stream;

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

  /// How many changes are waiting to reach the server; emits on change.
  Stream<int> watchPendingCount() {
    final count = _db.outbox.seq.count();
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.applied.equals(false));
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
    await _enqueue(
      MutationType.itemCreate,
      itemId: id,
      listId: listId,
      by: by,
      fields: ItemFields(
        name: name.trim(),
        quantity: quantity,
        unit: unit == null ? null : ItemFieldsUnit.fromJson(unit.toJson()),
        note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      ),
    );
    return id;
  }

  /// Checks [item] (puts it In the basket), or unchecks it when [checked] is false.
  Future<void> setChecked(ShownItem item, {required bool checked, required Actor by}) => _enqueue(
    MutationType.itemUpdate,
    itemId: item.id,
    listId: item.listId,
    by: by,
    fields: ItemFields(checked: checked),
  );

  /// Removes Item [itemId] from List [listId].
  Future<void> remove({required String itemId, required String listId, required Actor by}) =>
      _enqueue(MutationType.itemDelete, itemId: itemId, listId: listId, by: by, fields: const ItemFields());

  Future<void> _enqueue(
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

  void dispose() => unawaited(_changes.close());
}

/// [synced] Items with the [pending] outbox changes (oldest first) applied on top.
List<ShownItem> showItems(List<SyncedItem> synced, List<OutboxData> pending) {
  final items = <String, ShownItem>{for (final r in synced) r.id: _fromRow(r)};
  for (final m in pending) {
    final fields = ItemFields.fromJson(jsonDecode(m.fields) as Map<String, Object?>);
    final at = DateTime.fromMicrosecondsSinceEpoch(m.clientTimestampMicros, isUtc: true);
    final unit = fields.unit == null ? null : ItemUnit.fromJson(fields.unit!.toJson());
    switch (MutationType.fromJson(m.type)) {
      case MutationType.itemCreate:
        items.putIfAbsent(
          m.itemId,
          () => ShownItem(
            id: m.itemId,
            listId: m.listId,
            name: fields.name ?? '',
            addedAt: at,
            quantity: fields.quantity,
            unit: unit,
            note: fields.note,
            pending: !m.applied,
          ),
        );
      case MutationType.itemUpdate:
        final item = items[m.itemId];
        if (item == null) continue;
        items[m.itemId] = item._copy(
          name: fields.name,
          quantity: fields.quantity,
          unit: unit,
          note: fields.note,
          checked: fields.checked == true ? (at, m.byId, m.byName) : null,
          uncheck: fields.checked == false,
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
  quantity: r.quantity,
  unit: r.unit == null ? null : ItemUnit.fromJson(r.unit),
  note: r.note,
  checkedAt: r.checkedAtMicros == null ? null : DateTime.fromMicrosecondsSinceEpoch(r.checkedAtMicros!, isUtc: true),
  checkedById: r.checkedById,
  checkedByName: r.checkedByName,
);
