// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KnownHealthTable extends KnownHealth with TableInfo<$KnownHealthTable, KnownHealthData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownHealthTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HealthStatus, String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HealthStatus>($KnownHealthTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<HealthDatabase, String> database = GeneratedColumn<String>(
    'database',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HealthDatabase>($KnownHealthTable.$converterdatabase);
  @override
  List<GeneratedColumn> get $columns => [id, status, database];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_health';
  @override
  VerificationContext validateIntegrity(Insertable<KnownHealthData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnownHealthData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownHealthData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      status: $KnownHealthTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ),
      database: $KnownHealthTable.$converterdatabase.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}database'])!,
      ),
    );
  }

  @override
  $KnownHealthTable createAlias(String alias) {
    return $KnownHealthTable(attachedDatabase, alias);
  }

  static TypeConverter<HealthStatus, String> $converterstatus = const _HealthStatusConverter();
  static TypeConverter<HealthDatabase, String> $converterdatabase = const _HealthDatabaseConverter();
}

class KnownHealthData extends DataClass implements Insertable<KnownHealthData> {
  final int id;
  final HealthStatus status;
  final HealthDatabase database;
  const KnownHealthData({required this.id, required this.status, required this.database});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['status'] = Variable<String>($KnownHealthTable.$converterstatus.toSql(status));
    }
    {
      map['database'] = Variable<String>($KnownHealthTable.$converterdatabase.toSql(database));
    }
    return map;
  }

  KnownHealthCompanion toCompanion(bool nullToAbsent) {
    return KnownHealthCompanion(id: Value(id), status: Value(status), database: Value(database));
  }

  factory KnownHealthData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownHealthData(
      id: serializer.fromJson<int>(json['id']),
      status: serializer.fromJson<HealthStatus>(json['status']),
      database: serializer.fromJson<HealthDatabase>(json['database']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status': serializer.toJson<HealthStatus>(status),
      'database': serializer.toJson<HealthDatabase>(database),
    };
  }

  KnownHealthData copyWith({int? id, HealthStatus? status, HealthDatabase? database}) =>
      KnownHealthData(id: id ?? this.id, status: status ?? this.status, database: database ?? this.database);
  KnownHealthData copyWithCompanion(KnownHealthCompanion data) {
    return KnownHealthData(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      database: data.database.present ? data.database.value : this.database,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownHealthData(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('database: $database')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, status, database);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownHealthData &&
          other.id == this.id &&
          other.status == this.status &&
          other.database == this.database);
}

class KnownHealthCompanion extends UpdateCompanion<KnownHealthData> {
  final Value<int> id;
  final Value<HealthStatus> status;
  final Value<HealthDatabase> database;
  const KnownHealthCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.database = const Value.absent(),
  });
  KnownHealthCompanion.insert({
    this.id = const Value.absent(),
    required HealthStatus status,
    required HealthDatabase database,
  }) : status = Value(status),
       database = Value(database);
  static Insertable<KnownHealthData> custom({
    Expression<int>? id,
    Expression<String>? status,
    Expression<String>? database,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (database != null) 'database': database,
    });
  }

  KnownHealthCompanion copyWith({Value<int>? id, Value<HealthStatus>? status, Value<HealthDatabase>? database}) {
    return KnownHealthCompanion(id: id ?? this.id, status: status ?? this.status, database: database ?? this.database);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>($KnownHealthTable.$converterstatus.toSql(status.value));
    }
    if (database.present) {
      map['database'] = Variable<String>($KnownHealthTable.$converterdatabase.toSql(database.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownHealthCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('database: $database')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KnownHealthTable knownHealth = $KnownHealthTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [knownHealth];
}

typedef $$KnownHealthTableCreateCompanionBuilder = KnownHealthCompanion Function({
  Value<int> id,
  required HealthStatus status,
  required HealthDatabase database,
});
typedef $$KnownHealthTableUpdateCompanionBuilder = KnownHealthCompanion Function({
  Value<int> id,
  Value<HealthStatus> status,
  Value<HealthDatabase> database,
});

class $$KnownHealthTableFilterComposer extends Composer<_$AppDatabase, $KnownHealthTable> {
  $$KnownHealthTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<HealthStatus, HealthStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<HealthDatabase, HealthDatabase, String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$KnownHealthTableOrderingComposer extends Composer<_$AppDatabase, $KnownHealthTable> {
  $$KnownHealthTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => ColumnOrderings(column));
}

class $$KnownHealthTableAnnotationComposer extends Composer<_$AppDatabase, $KnownHealthTable> {
  $$KnownHealthTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HealthStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HealthDatabase, String> get database =>
      $composableBuilder(column: $table.database, builder: (column) => column);
}

class $$KnownHealthTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnownHealthTable,
          KnownHealthData,
          $$KnownHealthTableFilterComposer,
          $$KnownHealthTableOrderingComposer,
          $$KnownHealthTableAnnotationComposer,
          $$KnownHealthTableCreateCompanionBuilder,
          $$KnownHealthTableUpdateCompanionBuilder,
          (KnownHealthData, BaseReferences<_$AppDatabase, $KnownHealthTable, KnownHealthData>),
          KnownHealthData,
          PrefetchHooks Function()
        > {
  $$KnownHealthTableTableManager(_$AppDatabase db, $KnownHealthTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KnownHealthTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KnownHealthTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$KnownHealthTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<HealthStatus> status = const Value.absent(),
            Value<HealthDatabase> database = const Value.absent(),
          }) => KnownHealthCompanion(id: id, status: status, database: database),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required HealthStatus status,
            required HealthDatabase database,
          }) => KnownHealthCompanion.insert(id: id, status: status, database: database),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnownHealthTable, KnownHealthData>(table),
                  BaseReferences<_$AppDatabase, $KnownHealthTable, KnownHealthData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownHealthTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnownHealthTable,
      KnownHealthData,
      $$KnownHealthTableFilterComposer,
      $$KnownHealthTableOrderingComposer,
      $$KnownHealthTableAnnotationComposer,
      $$KnownHealthTableCreateCompanionBuilder,
      $$KnownHealthTableUpdateCompanionBuilder,
      (KnownHealthData, BaseReferences<_$AppDatabase, $KnownHealthTable, KnownHealthData>),
      KnownHealthData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KnownHealthTableTableManager get knownHealth => $$KnownHealthTableTableManager(_db, _db.knownHealth);
}
