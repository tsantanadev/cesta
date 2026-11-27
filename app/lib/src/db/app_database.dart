import 'dart:convert';

import 'package:drift/drift.dart';

import '../api/generated/cesta_api.dart';

part 'app_database.g.dart';

/// The last health result the app saw from the backend, stored as the API
/// reported it. Single row (id 1). Placeholder table for the walking
/// skeleton; Lists and Items arrive later.
class KnownHealth extends Table {
  IntColumn get id => integer()();
  TextColumn get status => text().map(const _HealthStatusConverter())();
  TextColumn get database => text().map(const _HealthDatabaseConverter())();

  @override
  Set<Column> get primaryKey => {id};
}

/// The signed-in User as the server last reported them, so the app
/// can show it offline. Single row (id 1); cleared on sign out.
class SignedInUser extends Table {
  IntColumn get id => integer()();

  /// The identity provider's user ID, to notice a different User signing in.
  TextColumn get authUid => text()();
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get displayNameConfirmed => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The Lists the signed-in User is a Member of, as the server last reported
/// them, so the Lists screen works offline. Cleared on sign out.
class KnownLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text().map(const _RoleConverter())();
  IntColumn get uncheckedItemCount => integer()();
  IntColumn get memberCount => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Items as the server last reported them through sync pulls. What the app
/// shows is these with the [Outbox]'s changes on top (see `ItemsStore`), so
/// dropping a rejected change from the outbox rolls the display back.
/// Cleared on sign out.
class SyncedItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  TextColumn get quantity => text().nullable()();

  /// The [ItemUnit] wire value.
  TextColumn get unit => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get addedById => text()();
  TextColumn get addedByName => text()();

  /// Microseconds since the epoch (UTC): Items show in this order, so it keeps
  /// more precision than Drift's DateTime columns.
  IntColumn get addedAtMicros => integer()();
  IntColumn get checkedAtMicros => integer().nullable()();
  TextColumn get checkedById => text().nullable()();
  TextColumn get checkedByName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Each List's Item history as the server reported it through sync pulls:
/// the Items bought (checked, then cleared), so screens can search it
/// offline. One row per cleared Item; a row never changes. Dropped with its
/// List, and cleared on sign out.
class SyncedHistory extends Table {
  TextColumn get itemId => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  TextColumn get quantity => text().nullable()();

  /// The [ItemUnit] wire value.
  TextColumn get unit => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Microseconds since the epoch (UTC), the order history shows in.
  IntColumn get clearedAtMicros => integer()();
  TextColumn get clearedById => text()();
  TextColumn get clearedByName => text()();

  @override
  Set<Column> get primaryKey => {itemId};
}

/// The device's Item changes not yet confirmed by the server, oldest first
/// (ADR-0001). A change stays here, shown on top of [SyncedItems], until the
/// server applied it and a pull brought its result back, or until the server
/// rejected it. Cleared on sign out.
class Outbox extends Table {
  /// Order the changes were made in, which is the order they are pushed in.
  IntColumn get seq => integer().autoIncrement()();

  /// The client mutation ID, so retrying a push applies it once.
  TextColumn get mutationId => text().unique()();

  /// Stored as the [MutationType] wire value.
  TextColumn get type => text().map(const _MutationTypeConverter())();
  TextColumn get itemId => text()();
  TextColumn get listId => text()();

  /// The changed fields, stored as [ItemFields] JSON.
  TextColumn get fields => text().map(const _ItemFieldsConverter())();
  IntColumn get clientTimestampMicros => integer()();

  /// The signed-in User when the change was made: shown as who added or checked it.
  TextColumn get byId => text()();
  TextColumn get byName => text()();

  /// True once the server applied it; it is dropped after the next full pull.
  BoolColumn get applied => boolean().withDefault(const Constant(false))();
}

/// The last pull cursor (single row, id 1). Cleared on sign out.
class SyncCursor extends Table {
  IntColumn get id => integer()();
  TextColumn get cursor => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores [Role] by its API wire value.
class _RoleConverter extends TypeConverter<Role, String> {
  const _RoleConverter();

  @override
  Role fromSql(String fromDb) => Role.fromJson(fromDb);

  @override
  String toSql(Role value) => value.toJson();
}

/// Stores [MutationType] by its API wire value.
class _MutationTypeConverter extends TypeConverter<MutationType, String> {
  const _MutationTypeConverter();

  @override
  MutationType fromSql(String fromDb) => MutationType.fromJson(fromDb);

  @override
  String toSql(MutationType value) => value.toJson();
}

/// Stores [ItemFields] as their API JSON.
class _ItemFieldsConverter extends TypeConverter<ItemFields, String> {
  const _ItemFieldsConverter();

  @override
  ItemFields fromSql(String fromDb) => ItemFields.fromJson(jsonDecode(fromDb) as Map<String, Object?>);

  @override
  String toSql(ItemFields value) => jsonEncode(value.toJson());
}

/// The signed-in User as cached on the device.
final class CachedUser {
  const CachedUser({required this.authUid, required this.user});

  final String authUid;
  final User user;
}

/// Stores [HealthStatus] by its API wire value.
class _HealthStatusConverter extends TypeConverter<HealthStatus, String> {
  const _HealthStatusConverter();

  @override
  HealthStatus fromSql(String fromDb) => HealthStatus.fromJson(fromDb);

  @override
  String toSql(HealthStatus value) => value.toJson();
}

/// Stores [HealthDatabase] by its API wire value.
class _HealthDatabaseConverter extends TypeConverter<HealthDatabase, String> {
  const _HealthDatabaseConverter();

  @override
  HealthDatabase fromSql(String fromDb) => HealthDatabase.fromJson(fromDb);

  @override
  String toSql(HealthDatabase value) => value.toJson();
}

/// The app's local SQLite database (Drift). Source of truth for display.
///
/// Production opens it with `driftDatabase(name: 'cesta')`; tests pass
/// `NativeDatabase.memory()`.
@DriftDatabase(tables: [KnownHealth, SignedInUser, KnownLists, SyncedItems, SyncedHistory, Outbox, SyncCursor])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(signedInUser);
      if (from < 3) await m.createTable(knownLists);
      if (from < 4) {
        await m.createTable(syncedItems);
        await m.createTable(outbox);
        await m.createTable(syncCursor);
      }
      if (from < 5) {
        await m.createTable(syncedHistory);
        // Pull everything again, so the history of Items cleared before the
        // table existed comes too.
        await delete(syncCursor).go();
      }
    },
  );

  /// Forgets every Item, the Item history, pending changes and the pull
  /// cursor (sign out, or another User signing in).
  Future<void> clearSyncedData() => transaction(() async {
    await delete(syncedItems).go();
    await delete(syncedHistory).go();
    await delete(outbox).go();
    await delete(syncCursor).go();
  });

  /// Replaces the cached Lists with [lists] (the server's full answer).
  Future<void> saveKnownLists(List<ListSummary> lists) => transaction(() async {
    await delete(knownLists).go();
    await batch((b) => b.insertAll(knownLists, [for (final l in lists) _listRow(l)]));
  });

  /// Adds or updates one cached List.
  Future<void> saveKnownList(ListSummary list) => into(knownLists).insertOnConflictUpdate(_listRow(list));

  /// Sets the to-buy count of the cached Lists in [toBuy], by List ID.
  Future<void> saveToBuyCounts(Map<String, int> toBuy) => transaction(() async {
    for (final MapEntry(key: id, value: n) in toBuy.entries) {
      await (update(
        knownLists,
      )..where((t) => t.id.equals(id))).write(KnownListsCompanion(uncheckedItemCount: Value(n)));
    }
  });

  Future<void> forgetKnownList(String id) => (delete(knownLists)..where((t) => t.id.equals(id))).go();

  /// The cached Lists, newest first.
  Future<List<ListSummary>> readKnownLists() async {
    final rows = await (select(knownLists)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return [for (final r in rows) _summary(r)];
  }

  static ListSummary _summary(KnownList r) => ListSummary(
    id: r.id,
    name: r.name,
    role: r.role,
    uncheckedItemCount: r.uncheckedItemCount,
    memberCount: r.memberCount,
    createdAt: r.createdAt.toUtc(),
  );

  Future<void> clearKnownLists() => delete(knownLists).go();

  static KnownListsCompanion _listRow(ListSummary l) => KnownListsCompanion.insert(
    id: l.id,
    name: l.name,
    role: l.role,
    uncheckedItemCount: l.uncheckedItemCount,
    memberCount: l.memberCount,
    createdAt: l.createdAt,
  );

  Future<void> saveSignedInUser(CachedUser cached) => into(signedInUser).insertOnConflictUpdate(
    SignedInUserCompanion.insert(
      id: const Value(1),
      authUid: cached.authUid,
      userId: cached.user.id,
      email: cached.user.email,
      displayName: cached.user.displayName,
      displayNameConfirmed: cached.user.displayNameConfirmed,
    ),
  );

  Future<CachedUser?> readSignedInUser() async {
    final row = await (select(signedInUser)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return CachedUser(
      authUid: row.authUid,
      user: User(
        id: row.userId,
        email: row.email,
        displayName: row.displayName,
        displayNameConfirmed: row.displayNameConfirmed,
      ),
    );
  }

  Future<void> clearSignedInUser() => delete(signedInUser).go();

  Future<void> saveKnownHealth(Health health) => into(knownHealth).insertOnConflictUpdate(
    KnownHealthCompanion.insert(id: const Value(1), status: health.status, database: health.database),
  );

  Future<Health?> readKnownHealth() async {
    final row = await (select(knownHealth)..where((t) => t.id.equals(1))).getSingleOrNull();
    return row == null ? null : Health(status: row.status, database: row.database);
  }
}
