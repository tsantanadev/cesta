import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';
import '../sync/outbox.dart';

export '../sync/outbox.dart' show Actor;

/// What a person fills in about an Item: its name, how much and a note.
final class ItemDetails {
  const ItemDetails({required this.name, this.quantity, this.unit, this.note});

  final String name;

  /// A positive decimal as the API writes it, e.g. "1.5"; null when not given.
  final String? quantity;
  final ItemUnit? unit;
  final String? note;

  /// These details with the name trimmed and a blank note left out.
  ItemDetails get _clean {
    final note = this.note?.trim();
    return ItemDetails(name: name.trim(), quantity: quantity, unit: unit, note: (note?.isEmpty ?? true) ? null : note);
  }

  /// The fields of an item_create with these details.
  ItemFields get _created {
    final d = _clean;
    return ItemFields(
      name: d.name,
      quantity: d.quantity == null ? null : (value: d.quantity),
      unit: d.unit == null ? null : (value: _fieldsUnit(d.unit)),
      note: d.note == null ? null : (value: d.note),
    );
  }

  /// The fields of an item_update from [before] to these details: only what
  /// changed, with a present null clearing a field.
  ItemFields _changedFrom(ItemDetails before) {
    final d = _clean;
    return ItemFields(
      name: d.name == before.name ? null : d.name,
      quantity: d.quantity == before.quantity ? null : (value: d.quantity),
      unit: d.unit == before.unit ? null : (value: _fieldsUnit(d.unit)),
      note: d.note == before.note ? null : (value: d.note),
    );
  }

  /// These details with [fields] applied, as an item_update would.
  ItemDetails _updated(ItemFields fields) => ItemDetails(
    name: fields.name ?? name,
    quantity: fields.quantity == null ? quantity : fields.quantity!.value,
    unit: fields.unit == null ? unit : _unit(fields.unit!.value),
    note: fields.note == null ? note : fields.note!.value,
  );
}

/// An Item as the app shows it: what the server last reported, with the
/// device's changes not yet confirmed applied on top.
final class ShownItem {
  const ShownItem({
    required this.id,
    required this.listId,
    required this.details,
    required this.addedAt,
    required this.addedBy,
    this.checkedAt,
    this.checkedBy,
  });

  final String id;
  final String listId;
  final ItemDetails details;
  final DateTime addedAt;

  String get name => details.name;
  String? get quantity => details.quantity;
  ItemUnit? get unit => details.unit;
  String? get note => details.note;

  /// Who added it, as the server (or, before it confirms, this device) says.
  final Actor addedBy;

  /// When and by whom the Item was checked (it is In the basket); null while
  /// it is to buy.
  final DateTime? checkedAt;
  final Actor? checkedBy;

  bool get checked => checkedAt != null;

  /// A copy with [fields] applied, as an item_update made [at] by [by] would:
  /// a field present in [fields] replaces the current value, and a present
  /// null clears it.
  ShownItem _updated(ItemFields fields, {required DateTime at, required Actor by}) {
    final (checkedAt, checkedBy) = switch (fields.checked) {
      true => (at, by),
      false => (null, null),
      null => (this.checkedAt, this.checkedBy),
    };
    return ShownItem(
      id: id,
      listId: listId,
      details: details._updated(fields),
      addedAt: addedAt,
      addedBy: addedBy,
      checkedAt: checkedAt,
      checkedBy: checkedBy,
    );
  }
}

/// The two generated unit types the API's schemas give the same values.
ItemUnit? _unit(ItemFieldsUnit? u) => u == null ? null : ItemUnit.fromJson(u.toJson());
ItemFieldsUnit? _fieldsUnit(ItemUnit? u) => u == null ? null : ItemFieldsUnit.fromJson(u.toJson());

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
    return showItems(synced, await _outbox.forList(listId));
  });

  /// How many Items of List [listId] are to buy, as shown.
  Future<int> toBuyCount(String listId) async => (await readList(listId)).where((i) => !i.checked).length;

  /// How many changes to List [listId] are waiting to reach the server;
  /// emits on change.
  Stream<int> watchPendingCount(String listId) => _outbox.watchWaiting(listId);

  /// Adds a new Item with [details] to List [listId]; returns its ID.
  Future<String> add({required String listId, required Actor by, required ItemDetails details}) async {
    final id = _uuid.v4();
    await _outbox.enqueue(MutationType.itemCreate, itemId: id, listId: listId, by: by, fields: details._created);
    return id;
  }

  /// Edits [item] to have [details]: how much and the note are cleared when
  /// null. Only what changed is sent.
  Future<void> update(ShownItem item, {required Actor by, required ItemDetails details}) {
    final fields = details._changedFrom(item.details);
    if (fields.toJson().isEmpty) return Future.value();
    return _outbox.enqueue(MutationType.itemUpdate, itemId: item.id, listId: item.listId, by: by, fields: fields);
  }

  /// Checks [item] (puts it In the basket), or unchecks it when [checked] is false.
  Future<void> setChecked(ShownItem item, {required bool checked, required Actor by}) => _outbox.enqueue(
    MutationType.itemUpdate,
    itemId: item.id,
    listId: item.listId,
    by: by,
    fields: ItemFields(checked: checked),
  );

  /// Removes Item [itemId] from List [listId]. An Item added on this device
  /// that hasn't reached the server yet just goes, with its changes, so
  /// nothing is left waiting to sync.
  ///
  /// With [undoableUntil] (the Undo window), the removal waits to be pushed
  /// until it completes, so [restore] meanwhile just drops it.
  Future<void> remove({
    required String itemId,
    required String listId,
    required Actor by,
    Future<void>? undoableUntil,
  }) async {
    if (await _outbox.dropPendingCreate(itemId)) return;
    if (undoableUntil != null) {
      return _outbox.enqueueHeldRemoval(itemId: itemId, listId: listId, by: by, until: undoableUntil);
    }
    await _outbox.enqueue(MutationType.itemDelete, itemId: itemId, listId: listId, by: by, fields: const ItemFields());
  }

  /// Undoes the removal of [item]: drops the removal while it is still
  /// waiting to sync, or else adds the Item again as it was (the server keeps
  /// removed Items removed, so it comes back as a new Item).
  Future<void> restore(ShownItem item, {required Actor by}) async {
    if (await _outbox.dropPendingRemoval(item.id)) return;
    final id = await add(listId: item.listId, by: by, details: item.details);
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
    final fields = m.fields;
    final at = DateTime.fromMicrosecondsSinceEpoch(m.clientTimestampMicros, isUtc: true);
    final by = (id: m.byId, displayName: m.byName);
    switch (m.type) {
      case MutationType.itemCreate:
        items.putIfAbsent(
          m.itemId,
          () => ShownItem(
            id: m.itemId,
            listId: m.listId,
            details: ItemDetails(
              name: fields.name ?? '',
              quantity: fields.quantity?.value,
              unit: _unit(fields.unit?.value),
              note: fields.note?.value,
            ),
            addedAt: at,
            addedBy: by,
          ),
        );
      case MutationType.itemUpdate:
        if (items[m.itemId] case final item?) items[m.itemId] = item._updated(fields, at: at, by: by);
      case MutationType.itemDelete || MutationType.itemClear:
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
  details: ItemDetails(
    name: r.name,
    quantity: r.quantity,
    unit: r.unit == null ? null : ItemUnit.fromJson(r.unit),
    note: r.note,
  ),
  addedAt: DateTime.fromMicrosecondsSinceEpoch(r.addedAtMicros, isUtc: true),
  addedBy: (id: r.addedById, displayName: r.addedByName),
  checkedAt: r.checkedAtMicros == null ? null : DateTime.fromMicrosecondsSinceEpoch(r.checkedAtMicros!, isUtc: true),
  checkedBy: r.checkedById == null ? null : (id: r.checkedById!, displayName: r.checkedByName ?? ''),
);
