import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// The last health result the app saw from the backend. Single row (id 1).
/// Placeholder table for the walking skeleton; Lists and Items arrive later.
class KnownHealth extends Table {
  IntColumn get id => integer()();
  BoolColumn get serverUp => boolean()();
  BoolColumn get databaseUp => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The app's local SQLite database (Drift). Source of truth for display.
///
/// Production opens it with `driftDatabase(name: 'cesta')`; tests pass
/// `NativeDatabase.memory()`.
@DriftDatabase(tables: [KnownHealth])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> saveKnownHealth({required bool serverUp, required bool databaseUp}) => into(
    knownHealth,
  ).insertOnConflictUpdate(KnownHealthCompanion.insert(id: const Value(1), serverUp: serverUp, databaseUp: databaseUp));

  Future<KnownHealthData?> readKnownHealth() => (select(knownHealth)..where((t) => t.id.equals(1))).getSingleOrNull();
}
