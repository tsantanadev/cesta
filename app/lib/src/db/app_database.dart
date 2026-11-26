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
@DriftDatabase(tables: [KnownHealth, SignedInUser])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(signedInUser);
    },
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
