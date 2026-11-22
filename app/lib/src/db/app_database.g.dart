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
  static const VerificationMeta _serverUpMeta = const VerificationMeta('serverUp');
  @override
  late final GeneratedColumn<bool> serverUp = GeneratedColumn<bool>(
    'server_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("server_up" IN (0, 1))'),
  );
  static const VerificationMeta _databaseUpMeta = const VerificationMeta('databaseUp');
  @override
  late final GeneratedColumn<bool> databaseUp = GeneratedColumn<bool>(
    'database_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("database_up" IN (0, 1))'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, serverUp, databaseUp];
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
    if (data.containsKey('server_up')) {
      context.handle(_serverUpMeta, serverUp.isAcceptableOrUnknown(data['server_up']!, _serverUpMeta));
    } else if (isInserting) {
      context.missing(_serverUpMeta);
    }
    if (data.containsKey('database_up')) {
      context.handle(_databaseUpMeta, databaseUp.isAcceptableOrUnknown(data['database_up']!, _databaseUpMeta));
    } else if (isInserting) {
      context.missing(_databaseUpMeta);
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
      serverUp: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}server_up'])!,
      databaseUp: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}database_up'])!,
    );
  }

  @override
  $KnownHealthTable createAlias(String alias) {
    return $KnownHealthTable(attachedDatabase, alias);
  }
}

class KnownHealthData extends DataClass implements Insertable<KnownHealthData> {
  final int id;
  final bool serverUp;
  final bool databaseUp;
  const KnownHealthData({required this.id, required this.serverUp, required this.databaseUp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_up'] = Variable<bool>(serverUp);
    map['database_up'] = Variable<bool>(databaseUp);
    return map;
  }

  KnownHealthCompanion toCompanion(bool nullToAbsent) {
    return KnownHealthCompanion(id: Value(id), serverUp: Value(serverUp), databaseUp: Value(databaseUp));
  }

  factory KnownHealthData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownHealthData(
      id: serializer.fromJson<int>(json['id']),
      serverUp: serializer.fromJson<bool>(json['serverUp']),
      databaseUp: serializer.fromJson<bool>(json['databaseUp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverUp': serializer.toJson<bool>(serverUp),
      'databaseUp': serializer.toJson<bool>(databaseUp),
    };
  }

  KnownHealthData copyWith({int? id, bool? serverUp, bool? databaseUp}) => KnownHealthData(
    id: id ?? this.id,
    serverUp: serverUp ?? this.serverUp,
    databaseUp: databaseUp ?? this.databaseUp,
  );
  KnownHealthData copyWithCompanion(KnownHealthCompanion data) {
    return KnownHealthData(
      id: data.id.present ? data.id.value : this.id,
      serverUp: data.serverUp.present ? data.serverUp.value : this.serverUp,
      databaseUp: data.databaseUp.present ? data.databaseUp.value : this.databaseUp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownHealthData(')
          ..write('id: $id, ')
          ..write('serverUp: $serverUp, ')
          ..write('databaseUp: $databaseUp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, serverUp, databaseUp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownHealthData &&
          other.id == this.id &&
          other.serverUp == this.serverUp &&
          other.databaseUp == this.databaseUp);
}

class KnownHealthCompanion extends UpdateCompanion<KnownHealthData> {
  final Value<int> id;
  final Value<bool> serverUp;
  final Value<bool> databaseUp;
  const KnownHealthCompanion({
    this.id = const Value.absent(),
    this.serverUp = const Value.absent(),
    this.databaseUp = const Value.absent(),
  });
  KnownHealthCompanion.insert({this.id = const Value.absent(), required bool serverUp, required bool databaseUp})
    : serverUp = Value(serverUp),
      databaseUp = Value(databaseUp);
  static Insertable<KnownHealthData> custom({
    Expression<int>? id,
    Expression<bool>? serverUp,
    Expression<bool>? databaseUp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverUp != null) 'server_up': serverUp,
      if (databaseUp != null) 'database_up': databaseUp,
    });
  }

  KnownHealthCompanion copyWith({Value<int>? id, Value<bool>? serverUp, Value<bool>? databaseUp}) {
    return KnownHealthCompanion(
      id: id ?? this.id,
      serverUp: serverUp ?? this.serverUp,
      databaseUp: databaseUp ?? this.databaseUp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverUp.present) {
      map['server_up'] = Variable<bool>(serverUp.value);
    }
    if (databaseUp.present) {
      map['database_up'] = Variable<bool>(databaseUp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownHealthCompanion(')
          ..write('id: $id, ')
          ..write('serverUp: $serverUp, ')
          ..write('databaseUp: $databaseUp')
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
  required bool serverUp,
  required bool databaseUp,
});
typedef $$KnownHealthTableUpdateCompanionBuilder = KnownHealthCompanion Function({
  Value<int> id,
  Value<bool> serverUp,
  Value<bool> databaseUp,
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

  ColumnFilters<bool> get serverUp =>
      $composableBuilder(column: $table.serverUp, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get databaseUp =>
      $composableBuilder(column: $table.databaseUp, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<bool> get serverUp =>
      $composableBuilder(column: $table.serverUp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get databaseUp =>
      $composableBuilder(column: $table.databaseUp, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<bool> get serverUp => $composableBuilder(column: $table.serverUp, builder: (column) => column);

  GeneratedColumn<bool> get databaseUp => $composableBuilder(column: $table.databaseUp, builder: (column) => column);
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
            Value<bool> serverUp = const Value.absent(),
            Value<bool> databaseUp = const Value.absent(),
          }) => KnownHealthCompanion(id: id, serverUp: serverUp, databaseUp: databaseUp),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required bool serverUp,
            required bool databaseUp,
          }) => KnownHealthCompanion.insert(id: id, serverUp: serverUp, databaseUp: databaseUp),
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
