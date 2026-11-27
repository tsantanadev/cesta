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

class $SignedInUserTable extends SignedInUser with TableInfo<$SignedInUserTable, SignedInUserData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignedInUserTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authUidMeta = const VerificationMeta('authUid');
  @override
  late final GeneratedColumn<String> authUid = GeneratedColumn<String>(
    'auth_uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameConfirmedMeta = const VerificationMeta('displayNameConfirmed');
  @override
  late final GeneratedColumn<bool> displayNameConfirmed = GeneratedColumn<bool>(
    'display_name_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("display_name_confirmed" IN (0, 1))'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, authUid, userId, email, displayName, displayNameConfirmed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signed_in_user';
  @override
  VerificationContext validateIntegrity(Insertable<SignedInUserData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('auth_uid')) {
      context.handle(_authUidMeta, authUid.isAcceptableOrUnknown(data['auth_uid']!, _authUidMeta));
    } else if (isInserting) {
      context.missing(_authUidMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta, userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(_emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(_displayNameMeta, displayName.isAcceptableOrUnknown(data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('display_name_confirmed')) {
      context.handle(
        _displayNameConfirmedMeta,
        displayNameConfirmed.isAcceptableOrUnknown(data['display_name_confirmed']!, _displayNameConfirmedMeta),
      );
    } else if (isInserting) {
      context.missing(_displayNameConfirmedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignedInUserData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignedInUserData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      authUid: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}auth_uid'])!,
      userId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      email: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      displayName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      displayNameConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}display_name_confirmed'],
      )!,
    );
  }

  @override
  $SignedInUserTable createAlias(String alias) {
    return $SignedInUserTable(attachedDatabase, alias);
  }
}

class SignedInUserData extends DataClass implements Insertable<SignedInUserData> {
  final int id;

  /// The identity provider's user ID, to notice a different User signing in.
  final String authUid;
  final String userId;
  final String email;
  final String displayName;
  final bool displayNameConfirmed;
  const SignedInUserData({
    required this.id,
    required this.authUid,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.displayNameConfirmed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['auth_uid'] = Variable<String>(authUid);
    map['user_id'] = Variable<String>(userId);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['display_name_confirmed'] = Variable<bool>(displayNameConfirmed);
    return map;
  }

  SignedInUserCompanion toCompanion(bool nullToAbsent) {
    return SignedInUserCompanion(
      id: Value(id),
      authUid: Value(authUid),
      userId: Value(userId),
      email: Value(email),
      displayName: Value(displayName),
      displayNameConfirmed: Value(displayNameConfirmed),
    );
  }

  factory SignedInUserData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignedInUserData(
      id: serializer.fromJson<int>(json['id']),
      authUid: serializer.fromJson<String>(json['authUid']),
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      displayNameConfirmed: serializer.fromJson<bool>(json['displayNameConfirmed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'authUid': serializer.toJson<String>(authUid),
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'displayNameConfirmed': serializer.toJson<bool>(displayNameConfirmed),
    };
  }

  SignedInUserData copyWith({
    int? id,
    String? authUid,
    String? userId,
    String? email,
    String? displayName,
    bool? displayNameConfirmed,
  }) => SignedInUserData(
    id: id ?? this.id,
    authUid: authUid ?? this.authUid,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    displayNameConfirmed: displayNameConfirmed ?? this.displayNameConfirmed,
  );
  SignedInUserData copyWithCompanion(SignedInUserCompanion data) {
    return SignedInUserData(
      id: data.id.present ? data.id.value : this.id,
      authUid: data.authUid.present ? data.authUid.value : this.authUid,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present ? data.displayName.value : this.displayName,
      displayNameConfirmed: data.displayNameConfirmed.present
          ? data.displayNameConfirmed.value
          : this.displayNameConfirmed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignedInUserData(')
          ..write('id: $id, ')
          ..write('authUid: $authUid, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('displayNameConfirmed: $displayNameConfirmed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, authUid, userId, email, displayName, displayNameConfirmed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignedInUserData &&
          other.id == this.id &&
          other.authUid == this.authUid &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.displayNameConfirmed == this.displayNameConfirmed);
}

class SignedInUserCompanion extends UpdateCompanion<SignedInUserData> {
  final Value<int> id;
  final Value<String> authUid;
  final Value<String> userId;
  final Value<String> email;
  final Value<String> displayName;
  final Value<bool> displayNameConfirmed;
  const SignedInUserCompanion({
    this.id = const Value.absent(),
    this.authUid = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.displayNameConfirmed = const Value.absent(),
  });
  SignedInUserCompanion.insert({
    this.id = const Value.absent(),
    required String authUid,
    required String userId,
    required String email,
    required String displayName,
    required bool displayNameConfirmed,
  }) : authUid = Value(authUid),
       userId = Value(userId),
       email = Value(email),
       displayName = Value(displayName),
       displayNameConfirmed = Value(displayNameConfirmed);
  static Insertable<SignedInUserData> custom({
    Expression<int>? id,
    Expression<String>? authUid,
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<bool>? displayNameConfirmed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authUid != null) 'auth_uid': authUid,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (displayNameConfirmed != null) 'display_name_confirmed': displayNameConfirmed,
    });
  }

  SignedInUserCompanion copyWith({
    Value<int>? id,
    Value<String>? authUid,
    Value<String>? userId,
    Value<String>? email,
    Value<String>? displayName,
    Value<bool>? displayNameConfirmed,
  }) {
    return SignedInUserCompanion(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      displayNameConfirmed: displayNameConfirmed ?? this.displayNameConfirmed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (authUid.present) {
      map['auth_uid'] = Variable<String>(authUid.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (displayNameConfirmed.present) {
      map['display_name_confirmed'] = Variable<bool>(displayNameConfirmed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignedInUserCompanion(')
          ..write('id: $id, ')
          ..write('authUid: $authUid, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('displayNameConfirmed: $displayNameConfirmed')
          ..write(')'))
        .toString();
  }
}

class $KnownListsTable extends KnownLists with TableInfo<$KnownListsTable, KnownList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Role, String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Role>($KnownListsTable.$converterrole);
  static const VerificationMeta _uncheckedItemCountMeta = const VerificationMeta('uncheckedItemCount');
  @override
  late final GeneratedColumn<int> uncheckedItemCount = GeneratedColumn<int>(
    'unchecked_item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta('memberCount');
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, role, uncheckedItemCount, memberCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_lists';
  @override
  VerificationContext validateIntegrity(Insertable<KnownList> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unchecked_item_count')) {
      context.handle(
        _uncheckedItemCountMeta,
        uncheckedItemCount.isAcceptableOrUnknown(data['unchecked_item_count']!, _uncheckedItemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_uncheckedItemCountMeta);
    }
    if (data.containsKey('member_count')) {
      context.handle(_memberCountMeta, memberCount.isAcceptableOrUnknown(data['member_count']!, _memberCountMeta));
    } else if (isInserting) {
      context.missing(_memberCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KnownList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownList(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: $KnownListsTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      ),
      uncheckedItemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unchecked_item_count'],
      )!,
      memberCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}member_count'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $KnownListsTable createAlias(String alias) {
    return $KnownListsTable(attachedDatabase, alias);
  }

  static TypeConverter<Role, String> $converterrole = const _RoleConverter();
}

class KnownList extends DataClass implements Insertable<KnownList> {
  final String id;
  final String name;
  final Role role;
  final int uncheckedItemCount;
  final int memberCount;
  final DateTime createdAt;
  const KnownList({
    required this.id,
    required this.name,
    required this.role,
    required this.uncheckedItemCount,
    required this.memberCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['role'] = Variable<String>($KnownListsTable.$converterrole.toSql(role));
    }
    map['unchecked_item_count'] = Variable<int>(uncheckedItemCount);
    map['member_count'] = Variable<int>(memberCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  KnownListsCompanion toCompanion(bool nullToAbsent) {
    return KnownListsCompanion(
      id: Value(id),
      name: Value(name),
      role: Value(role),
      uncheckedItemCount: Value(uncheckedItemCount),
      memberCount: Value(memberCount),
      createdAt: Value(createdAt),
    );
  }

  factory KnownList.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<Role>(json['role']),
      uncheckedItemCount: serializer.fromJson<int>(json['uncheckedItemCount']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<Role>(role),
      'uncheckedItemCount': serializer.toJson<int>(uncheckedItemCount),
      'memberCount': serializer.toJson<int>(memberCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  KnownList copyWith({
    String? id,
    String? name,
    Role? role,
    int? uncheckedItemCount,
    int? memberCount,
    DateTime? createdAt,
  }) => KnownList(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    uncheckedItemCount: uncheckedItemCount ?? this.uncheckedItemCount,
    memberCount: memberCount ?? this.memberCount,
    createdAt: createdAt ?? this.createdAt,
  );
  KnownList copyWithCompanion(KnownListsCompanion data) {
    return KnownList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      uncheckedItemCount: data.uncheckedItemCount.present ? data.uncheckedItemCount.value : this.uncheckedItemCount,
      memberCount: data.memberCount.present ? data.memberCount.value : this.memberCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('uncheckedItemCount: $uncheckedItemCount, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, role, uncheckedItemCount, memberCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownList &&
          other.id == this.id &&
          other.name == this.name &&
          other.role == this.role &&
          other.uncheckedItemCount == this.uncheckedItemCount &&
          other.memberCount == this.memberCount &&
          other.createdAt == this.createdAt);
}

class KnownListsCompanion extends UpdateCompanion<KnownList> {
  final Value<String> id;
  final Value<String> name;
  final Value<Role> role;
  final Value<int> uncheckedItemCount;
  final Value<int> memberCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const KnownListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.uncheckedItemCount = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownListsCompanion.insert({
    required String id,
    required String name,
    required Role role,
    required int uncheckedItemCount,
    required int memberCount,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       role = Value(role),
       uncheckedItemCount = Value(uncheckedItemCount),
       memberCount = Value(memberCount),
       createdAt = Value(createdAt);
  static Insertable<KnownList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? role,
    Expression<int>? uncheckedItemCount,
    Expression<int>? memberCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (uncheckedItemCount != null) 'unchecked_item_count': uncheckedItemCount,
      if (memberCount != null) 'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<Role>? role,
    Value<int>? uncheckedItemCount,
    Value<int>? memberCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return KnownListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      uncheckedItemCount: uncheckedItemCount ?? this.uncheckedItemCount,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>($KnownListsTable.$converterrole.toSql(role.value));
    }
    if (uncheckedItemCount.present) {
      map['unchecked_item_count'] = Variable<int>(uncheckedItemCount.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('uncheckedItemCount: $uncheckedItemCount, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedItemsTable extends SyncedItems with TableInfo<$SyncedItemsTable, SyncedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedByIdMeta = const VerificationMeta('addedById');
  @override
  late final GeneratedColumn<String> addedById = GeneratedColumn<String>(
    'added_by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedByNameMeta = const VerificationMeta('addedByName');
  @override
  late final GeneratedColumn<String> addedByName = GeneratedColumn<String>(
    'added_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMicrosMeta = const VerificationMeta('addedAtMicros');
  @override
  late final GeneratedColumn<int> addedAtMicros = GeneratedColumn<int>(
    'added_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedAtMicrosMeta = const VerificationMeta('checkedAtMicros');
  @override
  late final GeneratedColumn<int> checkedAtMicros = GeneratedColumn<int>(
    'checked_at_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedByIdMeta = const VerificationMeta('checkedById');
  @override
  late final GeneratedColumn<String> checkedById = GeneratedColumn<String>(
    'checked_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedByNameMeta = const VerificationMeta('checkedByName');
  @override
  late final GeneratedColumn<String> checkedByName = GeneratedColumn<String>(
    'checked_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    name,
    quantity,
    unit,
    note,
    addedById,
    addedByName,
    addedAtMicros,
    checkedAtMicros,
    checkedById,
    checkedByName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_items';
  @override
  VerificationContext validateIntegrity(Insertable<SyncedItem> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta, quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('added_by_id')) {
      context.handle(_addedByIdMeta, addedById.isAcceptableOrUnknown(data['added_by_id']!, _addedByIdMeta));
    } else if (isInserting) {
      context.missing(_addedByIdMeta);
    }
    if (data.containsKey('added_by_name')) {
      context.handle(_addedByNameMeta, addedByName.isAcceptableOrUnknown(data['added_by_name']!, _addedByNameMeta));
    } else if (isInserting) {
      context.missing(_addedByNameMeta);
    }
    if (data.containsKey('added_at_micros')) {
      context.handle(
        _addedAtMicrosMeta,
        addedAtMicros.isAcceptableOrUnknown(data['added_at_micros']!, _addedAtMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMicrosMeta);
    }
    if (data.containsKey('checked_at_micros')) {
      context.handle(
        _checkedAtMicrosMeta,
        checkedAtMicros.isAcceptableOrUnknown(data['checked_at_micros']!, _checkedAtMicrosMeta),
      );
    }
    if (data.containsKey('checked_by_id')) {
      context.handle(_checkedByIdMeta, checkedById.isAcceptableOrUnknown(data['checked_by_id']!, _checkedByIdMeta));
    }
    if (data.containsKey('checked_by_name')) {
      context.handle(
        _checkedByNameMeta,
        checkedByName.isAcceptableOrUnknown(data['checked_by_name']!, _checkedByNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedItem(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}quantity']),
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      addedById: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}added_by_id'])!,
      addedByName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}added_by_name'])!,
      addedAtMicros: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}added_at_micros'])!,
      checkedAtMicros: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}checked_at_micros']),
      checkedById: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}checked_by_id']),
      checkedByName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}checked_by_name']),
    );
  }

  @override
  $SyncedItemsTable createAlias(String alias) {
    return $SyncedItemsTable(attachedDatabase, alias);
  }
}

class SyncedItem extends DataClass implements Insertable<SyncedItem> {
  final String id;
  final String listId;
  final String name;
  final String? quantity;

  /// The [ItemUnit] wire value.
  final String? unit;
  final String? note;
  final String addedById;
  final String addedByName;

  /// Microseconds since the epoch (UTC): Items show in this order, so it keeps
  /// more precision than Drift's DateTime columns.
  final int addedAtMicros;
  final int? checkedAtMicros;
  final String? checkedById;
  final String? checkedByName;
  const SyncedItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.unit,
    this.note,
    required this.addedById,
    required this.addedByName,
    required this.addedAtMicros,
    this.checkedAtMicros,
    this.checkedById,
    this.checkedByName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['added_by_id'] = Variable<String>(addedById);
    map['added_by_name'] = Variable<String>(addedByName);
    map['added_at_micros'] = Variable<int>(addedAtMicros);
    if (!nullToAbsent || checkedAtMicros != null) {
      map['checked_at_micros'] = Variable<int>(checkedAtMicros);
    }
    if (!nullToAbsent || checkedById != null) {
      map['checked_by_id'] = Variable<String>(checkedById);
    }
    if (!nullToAbsent || checkedByName != null) {
      map['checked_by_name'] = Variable<String>(checkedByName);
    }
    return map;
  }

  SyncedItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncedItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      name: Value(name),
      quantity: quantity == null && nullToAbsent ? const Value.absent() : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      addedById: Value(addedById),
      addedByName: Value(addedByName),
      addedAtMicros: Value(addedAtMicros),
      checkedAtMicros: checkedAtMicros == null && nullToAbsent ? const Value.absent() : Value(checkedAtMicros),
      checkedById: checkedById == null && nullToAbsent ? const Value.absent() : Value(checkedById),
      checkedByName: checkedByName == null && nullToAbsent ? const Value.absent() : Value(checkedByName),
    );
  }

  factory SyncedItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      note: serializer.fromJson<String?>(json['note']),
      addedById: serializer.fromJson<String>(json['addedById']),
      addedByName: serializer.fromJson<String>(json['addedByName']),
      addedAtMicros: serializer.fromJson<int>(json['addedAtMicros']),
      checkedAtMicros: serializer.fromJson<int?>(json['checkedAtMicros']),
      checkedById: serializer.fromJson<String?>(json['checkedById']),
      checkedByName: serializer.fromJson<String?>(json['checkedByName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'note': serializer.toJson<String?>(note),
      'addedById': serializer.toJson<String>(addedById),
      'addedByName': serializer.toJson<String>(addedByName),
      'addedAtMicros': serializer.toJson<int>(addedAtMicros),
      'checkedAtMicros': serializer.toJson<int?>(checkedAtMicros),
      'checkedById': serializer.toJson<String?>(checkedById),
      'checkedByName': serializer.toJson<String?>(checkedByName),
    };
  }

  SyncedItem copyWith({
    String? id,
    String? listId,
    String? name,
    Value<String?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? addedById,
    String? addedByName,
    int? addedAtMicros,
    Value<int?> checkedAtMicros = const Value.absent(),
    Value<String?> checkedById = const Value.absent(),
    Value<String?> checkedByName = const Value.absent(),
  }) => SyncedItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    note: note.present ? note.value : this.note,
    addedById: addedById ?? this.addedById,
    addedByName: addedByName ?? this.addedByName,
    addedAtMicros: addedAtMicros ?? this.addedAtMicros,
    checkedAtMicros: checkedAtMicros.present ? checkedAtMicros.value : this.checkedAtMicros,
    checkedById: checkedById.present ? checkedById.value : this.checkedById,
    checkedByName: checkedByName.present ? checkedByName.value : this.checkedByName,
  );
  SyncedItem copyWithCompanion(SyncedItemsCompanion data) {
    return SyncedItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      note: data.note.present ? data.note.value : this.note,
      addedById: data.addedById.present ? data.addedById.value : this.addedById,
      addedByName: data.addedByName.present ? data.addedByName.value : this.addedByName,
      addedAtMicros: data.addedAtMicros.present ? data.addedAtMicros.value : this.addedAtMicros,
      checkedAtMicros: data.checkedAtMicros.present ? data.checkedAtMicros.value : this.checkedAtMicros,
      checkedById: data.checkedById.present ? data.checkedById.value : this.checkedById,
      checkedByName: data.checkedByName.present ? data.checkedByName.value : this.checkedByName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('addedById: $addedById, ')
          ..write('addedByName: $addedByName, ')
          ..write('addedAtMicros: $addedAtMicros, ')
          ..write('checkedAtMicros: $checkedAtMicros, ')
          ..write('checkedById: $checkedById, ')
          ..write('checkedByName: $checkedByName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    name,
    quantity,
    unit,
    note,
    addedById,
    addedByName,
    addedAtMicros,
    checkedAtMicros,
    checkedById,
    checkedByName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.note == this.note &&
          other.addedById == this.addedById &&
          other.addedByName == this.addedByName &&
          other.addedAtMicros == this.addedAtMicros &&
          other.checkedAtMicros == this.checkedAtMicros &&
          other.checkedById == this.checkedById &&
          other.checkedByName == this.checkedByName);
}

class SyncedItemsCompanion extends UpdateCompanion<SyncedItem> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> name;
  final Value<String?> quantity;
  final Value<String?> unit;
  final Value<String?> note;
  final Value<String> addedById;
  final Value<String> addedByName;
  final Value<int> addedAtMicros;
  final Value<int?> checkedAtMicros;
  final Value<String?> checkedById;
  final Value<String?> checkedByName;
  final Value<int> rowid;
  const SyncedItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.addedById = const Value.absent(),
    this.addedByName = const Value.absent(),
    this.addedAtMicros = const Value.absent(),
    this.checkedAtMicros = const Value.absent(),
    this.checkedById = const Value.absent(),
    this.checkedByName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedItemsCompanion.insert({
    required String id,
    required String listId,
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    required String addedById,
    required String addedByName,
    required int addedAtMicros,
    this.checkedAtMicros = const Value.absent(),
    this.checkedById = const Value.absent(),
    this.checkedByName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       name = Value(name),
       addedById = Value(addedById),
       addedByName = Value(addedByName),
       addedAtMicros = Value(addedAtMicros);
  static Insertable<SyncedItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<String>? unit,
    Expression<String>? note,
    Expression<String>? addedById,
    Expression<String>? addedByName,
    Expression<int>? addedAtMicros,
    Expression<int>? checkedAtMicros,
    Expression<String>? checkedById,
    Expression<String>? checkedByName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (note != null) 'note': note,
      if (addedById != null) 'added_by_id': addedById,
      if (addedByName != null) 'added_by_name': addedByName,
      if (addedAtMicros != null) 'added_at_micros': addedAtMicros,
      if (checkedAtMicros != null) 'checked_at_micros': checkedAtMicros,
      if (checkedById != null) 'checked_by_id': checkedById,
      if (checkedByName != null) 'checked_by_name': checkedByName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? name,
    Value<String?>? quantity,
    Value<String?>? unit,
    Value<String?>? note,
    Value<String>? addedById,
    Value<String>? addedByName,
    Value<int>? addedAtMicros,
    Value<int?>? checkedAtMicros,
    Value<String?>? checkedById,
    Value<String?>? checkedByName,
    Value<int>? rowid,
  }) {
    return SyncedItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      addedById: addedById ?? this.addedById,
      addedByName: addedByName ?? this.addedByName,
      addedAtMicros: addedAtMicros ?? this.addedAtMicros,
      checkedAtMicros: checkedAtMicros ?? this.checkedAtMicros,
      checkedById: checkedById ?? this.checkedById,
      checkedByName: checkedByName ?? this.checkedByName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (addedById.present) {
      map['added_by_id'] = Variable<String>(addedById.value);
    }
    if (addedByName.present) {
      map['added_by_name'] = Variable<String>(addedByName.value);
    }
    if (addedAtMicros.present) {
      map['added_at_micros'] = Variable<int>(addedAtMicros.value);
    }
    if (checkedAtMicros.present) {
      map['checked_at_micros'] = Variable<int>(checkedAtMicros.value);
    }
    if (checkedById.present) {
      map['checked_by_id'] = Variable<String>(checkedById.value);
    }
    if (checkedByName.present) {
      map['checked_by_name'] = Variable<String>(checkedByName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('addedById: $addedById, ')
          ..write('addedByName: $addedByName, ')
          ..write('addedAtMicros: $addedAtMicros, ')
          ..write('checkedAtMicros: $checkedAtMicros, ')
          ..write('checkedById: $checkedById, ')
          ..write('checkedByName: $checkedByName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncedHistoryTable extends SyncedHistory with TableInfo<$SyncedHistoryTable, SyncedHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncedHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clearedAtMicrosMeta = const VerificationMeta('clearedAtMicros');
  @override
  late final GeneratedColumn<int> clearedAtMicros = GeneratedColumn<int>(
    'cleared_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clearedByIdMeta = const VerificationMeta('clearedById');
  @override
  late final GeneratedColumn<String> clearedById = GeneratedColumn<String>(
    'cleared_by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clearedByNameMeta = const VerificationMeta('clearedByName');
  @override
  late final GeneratedColumn<String> clearedByName = GeneratedColumn<String>(
    'cleared_by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    listId,
    name,
    quantity,
    unit,
    note,
    clearedAtMicros,
    clearedById,
    clearedByName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synced_history';
  @override
  VerificationContext validateIntegrity(Insertable<SyncedHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta, quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('cleared_at_micros')) {
      context.handle(
        _clearedAtMicrosMeta,
        clearedAtMicros.isAcceptableOrUnknown(data['cleared_at_micros']!, _clearedAtMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_clearedAtMicrosMeta);
    }
    if (data.containsKey('cleared_by_id')) {
      context.handle(_clearedByIdMeta, clearedById.isAcceptableOrUnknown(data['cleared_by_id']!, _clearedByIdMeta));
    } else if (isInserting) {
      context.missing(_clearedByIdMeta);
    }
    if (data.containsKey('cleared_by_name')) {
      context.handle(
        _clearedByNameMeta,
        clearedByName.isAcceptableOrUnknown(data['cleared_by_name']!, _clearedByNameMeta),
      );
    } else if (isInserting) {
      context.missing(_clearedByNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  SyncedHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncedHistoryData(
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      quantity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}quantity']),
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      clearedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cleared_at_micros'],
      )!,
      clearedById: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cleared_by_id'])!,
      clearedByName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cleared_by_name'])!,
    );
  }

  @override
  $SyncedHistoryTable createAlias(String alias) {
    return $SyncedHistoryTable(attachedDatabase, alias);
  }
}

class SyncedHistoryData extends DataClass implements Insertable<SyncedHistoryData> {
  final String itemId;
  final String listId;
  final String name;
  final String? quantity;

  /// The [ItemUnit] wire value.
  final String? unit;
  final String? note;

  /// Microseconds since the epoch (UTC), the order history shows in.
  final int clearedAtMicros;
  final String clearedById;
  final String clearedByName;
  const SyncedHistoryData({
    required this.itemId,
    required this.listId,
    required this.name,
    this.quantity,
    this.unit,
    this.note,
    required this.clearedAtMicros,
    required this.clearedById,
    required this.clearedByName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['cleared_at_micros'] = Variable<int>(clearedAtMicros);
    map['cleared_by_id'] = Variable<String>(clearedById);
    map['cleared_by_name'] = Variable<String>(clearedByName);
    return map;
  }

  SyncedHistoryCompanion toCompanion(bool nullToAbsent) {
    return SyncedHistoryCompanion(
      itemId: Value(itemId),
      listId: Value(listId),
      name: Value(name),
      quantity: quantity == null && nullToAbsent ? const Value.absent() : Value(quantity),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      clearedAtMicros: Value(clearedAtMicros),
      clearedById: Value(clearedById),
      clearedByName: Value(clearedByName),
    );
  }

  factory SyncedHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncedHistoryData(
      itemId: serializer.fromJson<String>(json['itemId']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      unit: serializer.fromJson<String?>(json['unit']),
      note: serializer.fromJson<String?>(json['note']),
      clearedAtMicros: serializer.fromJson<int>(json['clearedAtMicros']),
      clearedById: serializer.fromJson<String>(json['clearedById']),
      clearedByName: serializer.fromJson<String>(json['clearedByName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String?>(quantity),
      'unit': serializer.toJson<String?>(unit),
      'note': serializer.toJson<String?>(note),
      'clearedAtMicros': serializer.toJson<int>(clearedAtMicros),
      'clearedById': serializer.toJson<String>(clearedById),
      'clearedByName': serializer.toJson<String>(clearedByName),
    };
  }

  SyncedHistoryData copyWith({
    String? itemId,
    String? listId,
    String? name,
    Value<String?> quantity = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? clearedAtMicros,
    String? clearedById,
    String? clearedByName,
  }) => SyncedHistoryData(
    itemId: itemId ?? this.itemId,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    unit: unit.present ? unit.value : this.unit,
    note: note.present ? note.value : this.note,
    clearedAtMicros: clearedAtMicros ?? this.clearedAtMicros,
    clearedById: clearedById ?? this.clearedById,
    clearedByName: clearedByName ?? this.clearedByName,
  );
  SyncedHistoryData copyWithCompanion(SyncedHistoryCompanion data) {
    return SyncedHistoryData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      note: data.note.present ? data.note.value : this.note,
      clearedAtMicros: data.clearedAtMicros.present ? data.clearedAtMicros.value : this.clearedAtMicros,
      clearedById: data.clearedById.present ? data.clearedById.value : this.clearedById,
      clearedByName: data.clearedByName.present ? data.clearedByName.value : this.clearedByName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncedHistoryData(')
          ..write('itemId: $itemId, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('clearedAtMicros: $clearedAtMicros, ')
          ..write('clearedById: $clearedById, ')
          ..write('clearedByName: $clearedByName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, listId, name, quantity, unit, note, clearedAtMicros, clearedById, clearedByName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncedHistoryData &&
          other.itemId == this.itemId &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.note == this.note &&
          other.clearedAtMicros == this.clearedAtMicros &&
          other.clearedById == this.clearedById &&
          other.clearedByName == this.clearedByName);
}

class SyncedHistoryCompanion extends UpdateCompanion<SyncedHistoryData> {
  final Value<String> itemId;
  final Value<String> listId;
  final Value<String> name;
  final Value<String?> quantity;
  final Value<String?> unit;
  final Value<String?> note;
  final Value<int> clearedAtMicros;
  final Value<String> clearedById;
  final Value<String> clearedByName;
  final Value<int> rowid;
  const SyncedHistoryCompanion({
    this.itemId = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.clearedAtMicros = const Value.absent(),
    this.clearedById = const Value.absent(),
    this.clearedByName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncedHistoryCompanion.insert({
    required String itemId,
    required String listId,
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    required int clearedAtMicros,
    required String clearedById,
    required String clearedByName,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       listId = Value(listId),
       name = Value(name),
       clearedAtMicros = Value(clearedAtMicros),
       clearedById = Value(clearedById),
       clearedByName = Value(clearedByName);
  static Insertable<SyncedHistoryData> custom({
    Expression<String>? itemId,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<String>? unit,
    Expression<String>? note,
    Expression<int>? clearedAtMicros,
    Expression<String>? clearedById,
    Expression<String>? clearedByName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (note != null) 'note': note,
      if (clearedAtMicros != null) 'cleared_at_micros': clearedAtMicros,
      if (clearedById != null) 'cleared_by_id': clearedById,
      if (clearedByName != null) 'cleared_by_name': clearedByName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncedHistoryCompanion copyWith({
    Value<String>? itemId,
    Value<String>? listId,
    Value<String>? name,
    Value<String?>? quantity,
    Value<String?>? unit,
    Value<String?>? note,
    Value<int>? clearedAtMicros,
    Value<String>? clearedById,
    Value<String>? clearedByName,
    Value<int>? rowid,
  }) {
    return SyncedHistoryCompanion(
      itemId: itemId ?? this.itemId,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      clearedAtMicros: clearedAtMicros ?? this.clearedAtMicros,
      clearedById: clearedById ?? this.clearedById,
      clearedByName: clearedByName ?? this.clearedByName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (clearedAtMicros.present) {
      map['cleared_at_micros'] = Variable<int>(clearedAtMicros.value);
    }
    if (clearedById.present) {
      map['cleared_by_id'] = Variable<String>(clearedById.value);
    }
    if (clearedByName.present) {
      map['cleared_by_name'] = Variable<String>(clearedByName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncedHistoryCompanion(')
          ..write('itemId: $itemId, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('clearedAtMicros: $clearedAtMicros, ')
          ..write('clearedById: $clearedById, ')
          ..write('clearedByName: $clearedByName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta('mutationId');
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MutationType, String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<MutationType>($OutboxTable.$convertertype);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemFields, String> fields = GeneratedColumn<String>(
    'fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ItemFields>($OutboxTable.$converterfields);
  static const VerificationMeta _clientTimestampMicrosMeta = const VerificationMeta('clientTimestampMicros');
  @override
  late final GeneratedColumn<int> clientTimestampMicros = GeneratedColumn<int>(
    'client_timestamp_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byIdMeta = const VerificationMeta('byId');
  @override
  late final GeneratedColumn<String> byId = GeneratedColumn<String>(
    'by_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byNameMeta = const VerificationMeta('byName');
  @override
  late final GeneratedColumn<String> byName = GeneratedColumn<String>(
    'by_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedMeta = const VerificationMeta('applied');
  @override
  late final GeneratedColumn<bool> applied = GeneratedColumn<bool>(
    'applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("applied" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    mutationId,
    type,
    itemId,
    listId,
    fields,
    clientTimestampMicros,
    byId,
    byName,
    applied,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    if (data.containsKey('mutation_id')) {
      context.handle(_mutationIdMeta, mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta));
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(_listIdMeta, listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta));
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('client_timestamp_micros')) {
      context.handle(
        _clientTimestampMicrosMeta,
        clientTimestampMicros.isAcceptableOrUnknown(data['client_timestamp_micros']!, _clientTimestampMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_clientTimestampMicrosMeta);
    }
    if (data.containsKey('by_id')) {
      context.handle(_byIdMeta, byId.isAcceptableOrUnknown(data['by_id']!, _byIdMeta));
    } else if (isInserting) {
      context.missing(_byIdMeta);
    }
    if (data.containsKey('by_name')) {
      context.handle(_byNameMeta, byName.isAcceptableOrUnknown(data['by_name']!, _byNameMeta));
    } else if (isInserting) {
      context.missing(_byNameMeta);
    }
    if (data.containsKey('applied')) {
      context.handle(_appliedMeta, applied.isAcceptableOrUnknown(data['applied']!, _appliedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      mutationId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mutation_id'])!,
      type: $OutboxTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      ),
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      listId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}list_id'])!,
      fields: $OutboxTable.$converterfields.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}fields'])!,
      ),
      clientTimestampMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}client_timestamp_micros'],
      )!,
      byId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}by_id'])!,
      byName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}by_name'])!,
      applied: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}applied'])!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }

  static TypeConverter<MutationType, String> $convertertype = const _MutationTypeConverter();
  static TypeConverter<ItemFields, String> $converterfields = const _ItemFieldsConverter();
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  /// Order the changes were made in, which is the order they are pushed in.
  final int seq;

  /// The client mutation ID, so retrying a push applies it once.
  final String mutationId;

  /// Stored as the [MutationType] wire value.
  final MutationType type;
  final String itemId;
  final String listId;

  /// The changed fields, stored as [ItemFields] JSON.
  final ItemFields fields;
  final int clientTimestampMicros;

  /// The signed-in User when the change was made: shown as who added or checked it.
  final String byId;
  final String byName;

  /// True once the server applied it; it is dropped after the next full pull.
  final bool applied;
  const OutboxData({
    required this.seq,
    required this.mutationId,
    required this.type,
    required this.itemId,
    required this.listId,
    required this.fields,
    required this.clientTimestampMicros,
    required this.byId,
    required this.byName,
    required this.applied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation_id'] = Variable<String>(mutationId);
    {
      map['type'] = Variable<String>($OutboxTable.$convertertype.toSql(type));
    }
    map['item_id'] = Variable<String>(itemId);
    map['list_id'] = Variable<String>(listId);
    {
      map['fields'] = Variable<String>($OutboxTable.$converterfields.toSql(fields));
    }
    map['client_timestamp_micros'] = Variable<int>(clientTimestampMicros);
    map['by_id'] = Variable<String>(byId);
    map['by_name'] = Variable<String>(byName);
    map['applied'] = Variable<bool>(applied);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      mutationId: Value(mutationId),
      type: Value(type),
      itemId: Value(itemId),
      listId: Value(listId),
      fields: Value(fields),
      clientTimestampMicros: Value(clientTimestampMicros),
      byId: Value(byId),
      byName: Value(byName),
      applied: Value(applied),
    );
  }

  factory OutboxData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      type: serializer.fromJson<MutationType>(json['type']),
      itemId: serializer.fromJson<String>(json['itemId']),
      listId: serializer.fromJson<String>(json['listId']),
      fields: serializer.fromJson<ItemFields>(json['fields']),
      clientTimestampMicros: serializer.fromJson<int>(json['clientTimestampMicros']),
      byId: serializer.fromJson<String>(json['byId']),
      byName: serializer.fromJson<String>(json['byName']),
      applied: serializer.fromJson<bool>(json['applied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutationId': serializer.toJson<String>(mutationId),
      'type': serializer.toJson<MutationType>(type),
      'itemId': serializer.toJson<String>(itemId),
      'listId': serializer.toJson<String>(listId),
      'fields': serializer.toJson<ItemFields>(fields),
      'clientTimestampMicros': serializer.toJson<int>(clientTimestampMicros),
      'byId': serializer.toJson<String>(byId),
      'byName': serializer.toJson<String>(byName),
      'applied': serializer.toJson<bool>(applied),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? mutationId,
    MutationType? type,
    String? itemId,
    String? listId,
    ItemFields? fields,
    int? clientTimestampMicros,
    String? byId,
    String? byName,
    bool? applied,
  }) => OutboxData(
    seq: seq ?? this.seq,
    mutationId: mutationId ?? this.mutationId,
    type: type ?? this.type,
    itemId: itemId ?? this.itemId,
    listId: listId ?? this.listId,
    fields: fields ?? this.fields,
    clientTimestampMicros: clientTimestampMicros ?? this.clientTimestampMicros,
    byId: byId ?? this.byId,
    byName: byName ?? this.byName,
    applied: applied ?? this.applied,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutationId: data.mutationId.present ? data.mutationId.value : this.mutationId,
      type: data.type.present ? data.type.value : this.type,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      listId: data.listId.present ? data.listId.value : this.listId,
      fields: data.fields.present ? data.fields.value : this.fields,
      clientTimestampMicros: data.clientTimestampMicros.present
          ? data.clientTimestampMicros.value
          : this.clientTimestampMicros,
      byId: data.byId.present ? data.byId.value : this.byId,
      byName: data.byName.present ? data.byName.value : this.byName,
      applied: data.applied.present ? data.applied.value : this.applied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('listId: $listId, ')
          ..write('fields: $fields, ')
          ..write('clientTimestampMicros: $clientTimestampMicros, ')
          ..write('byId: $byId, ')
          ..write('byName: $byName, ')
          ..write('applied: $applied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, mutationId, type, itemId, listId, fields, clientTimestampMicros, byId, byName, applied);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.mutationId == this.mutationId &&
          other.type == this.type &&
          other.itemId == this.itemId &&
          other.listId == this.listId &&
          other.fields == this.fields &&
          other.clientTimestampMicros == this.clientTimestampMicros &&
          other.byId == this.byId &&
          other.byName == this.byName &&
          other.applied == this.applied);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> mutationId;
  final Value<MutationType> type;
  final Value<String> itemId;
  final Value<String> listId;
  final Value<ItemFields> fields;
  final Value<int> clientTimestampMicros;
  final Value<String> byId;
  final Value<String> byName;
  final Value<bool> applied;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.type = const Value.absent(),
    this.itemId = const Value.absent(),
    this.listId = const Value.absent(),
    this.fields = const Value.absent(),
    this.clientTimestampMicros = const Value.absent(),
    this.byId = const Value.absent(),
    this.byName = const Value.absent(),
    this.applied = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String mutationId,
    required MutationType type,
    required String itemId,
    required String listId,
    required ItemFields fields,
    required int clientTimestampMicros,
    required String byId,
    required String byName,
    this.applied = const Value.absent(),
  }) : mutationId = Value(mutationId),
       type = Value(type),
       itemId = Value(itemId),
       listId = Value(listId),
       fields = Value(fields),
       clientTimestampMicros = Value(clientTimestampMicros),
       byId = Value(byId),
       byName = Value(byName);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? mutationId,
    Expression<String>? type,
    Expression<String>? itemId,
    Expression<String>? listId,
    Expression<String>? fields,
    Expression<int>? clientTimestampMicros,
    Expression<String>? byId,
    Expression<String>? byName,
    Expression<bool>? applied,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutationId != null) 'mutation_id': mutationId,
      if (type != null) 'type': type,
      if (itemId != null) 'item_id': itemId,
      if (listId != null) 'list_id': listId,
      if (fields != null) 'fields': fields,
      if (clientTimestampMicros != null) 'client_timestamp_micros': clientTimestampMicros,
      if (byId != null) 'by_id': byId,
      if (byName != null) 'by_name': byName,
      if (applied != null) 'applied': applied,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? mutationId,
    Value<MutationType>? type,
    Value<String>? itemId,
    Value<String>? listId,
    Value<ItemFields>? fields,
    Value<int>? clientTimestampMicros,
    Value<String>? byId,
    Value<String>? byName,
    Value<bool>? applied,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      mutationId: mutationId ?? this.mutationId,
      type: type ?? this.type,
      itemId: itemId ?? this.itemId,
      listId: listId ?? this.listId,
      fields: fields ?? this.fields,
      clientTimestampMicros: clientTimestampMicros ?? this.clientTimestampMicros,
      byId: byId ?? this.byId,
      byName: byName ?? this.byName,
      applied: applied ?? this.applied,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>($OutboxTable.$convertertype.toSql(type.value));
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (fields.present) {
      map['fields'] = Variable<String>($OutboxTable.$converterfields.toSql(fields.value));
    }
    if (clientTimestampMicros.present) {
      map['client_timestamp_micros'] = Variable<int>(clientTimestampMicros.value);
    }
    if (byId.present) {
      map['by_id'] = Variable<String>(byId.value);
    }
    if (byName.present) {
      map['by_name'] = Variable<String>(byName.value);
    }
    if (applied.present) {
      map['applied'] = Variable<bool>(applied.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('type: $type, ')
          ..write('itemId: $itemId, ')
          ..write('listId: $listId, ')
          ..write('fields: $fields, ')
          ..write('clientTimestampMicros: $clientTimestampMicros, ')
          ..write('byId: $byId, ')
          ..write('byName: $byName, ')
          ..write('applied: $applied')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorTable extends SyncCursor with TableInfo<$SyncCursorTable, SyncCursorData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursor';
  @override
  VerificationContext validateIntegrity(Insertable<SyncCursorData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cursor')) {
      context.handle(_cursorMeta, cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta));
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncCursorData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursorData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cursor: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cursor'])!,
    );
  }

  @override
  $SyncCursorTable createAlias(String alias) {
    return $SyncCursorTable(attachedDatabase, alias);
  }
}

class SyncCursorData extends DataClass implements Insertable<SyncCursorData> {
  final int id;
  final String cursor;
  const SyncCursorData({required this.id, required this.cursor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cursor'] = Variable<String>(cursor);
    return map;
  }

  SyncCursorCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorCompanion(id: Value(id), cursor: Value(cursor));
  }

  factory SyncCursorData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursorData(
      id: serializer.fromJson<int>(json['id']),
      cursor: serializer.fromJson<String>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id), 'cursor': serializer.toJson<String>(cursor)};
  }

  SyncCursorData copyWith({int? id, String? cursor}) =>
      SyncCursorData(id: id ?? this.id, cursor: cursor ?? this.cursor);
  SyncCursorData copyWithCompanion(SyncCursorCompanion data) {
    return SyncCursorData(
      id: data.id.present ? data.id.value : this.id,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorData(')
          ..write('id: $id, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncCursorData && other.id == this.id && other.cursor == this.cursor);
}

class SyncCursorCompanion extends UpdateCompanion<SyncCursorData> {
  final Value<int> id;
  final Value<String> cursor;
  const SyncCursorCompanion({this.id = const Value.absent(), this.cursor = const Value.absent()});
  SyncCursorCompanion.insert({this.id = const Value.absent(), required String cursor}) : cursor = Value(cursor);
  static Insertable<SyncCursorData> custom({Expression<int>? id, Expression<String>? cursor}) {
    return RawValuesInsertable({if (id != null) 'id': id, if (cursor != null) 'cursor': cursor});
  }

  SyncCursorCompanion copyWith({Value<int>? id, Value<String>? cursor}) {
    return SyncCursorCompanion(id: id ?? this.id, cursor: cursor ?? this.cursor);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorCompanion(')
          ..write('id: $id, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KnownHealthTable knownHealth = $KnownHealthTable(this);
  late final $SignedInUserTable signedInUser = $SignedInUserTable(this);
  late final $KnownListsTable knownLists = $KnownListsTable(this);
  late final $SyncedItemsTable syncedItems = $SyncedItemsTable(this);
  late final $SyncedHistoryTable syncedHistory = $SyncedHistoryTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncCursorTable syncCursor = $SyncCursorTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    knownHealth,
    signedInUser,
    knownLists,
    syncedItems,
    syncedHistory,
    outbox,
    syncCursor,
  ];
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
typedef $$SignedInUserTableCreateCompanionBuilder = SignedInUserCompanion Function({
  Value<int> id,
  required String authUid,
  required String userId,
  required String email,
  required String displayName,
  required bool displayNameConfirmed,
});
typedef $$SignedInUserTableUpdateCompanionBuilder = SignedInUserCompanion Function({
  Value<int> id,
  Value<String> authUid,
  Value<String> userId,
  Value<String> email,
  Value<String> displayName,
  Value<bool> displayNameConfirmed,
});

class $$SignedInUserTableFilterComposer extends Composer<_$AppDatabase, $SignedInUserTable> {
  $$SignedInUserTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authUid =>
      $composableBuilder(column: $table.authUid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get displayNameConfirmed =>
      $composableBuilder(column: $table.displayNameConfirmed, builder: (column) => ColumnFilters(column));
}

class $$SignedInUserTableOrderingComposer extends Composer<_$AppDatabase, $SignedInUserTable> {
  $$SignedInUserTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authUid =>
      $composableBuilder(column: $table.authUid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get displayNameConfirmed =>
      $composableBuilder(column: $table.displayNameConfirmed, builder: (column) => ColumnOrderings(column));
}

class $$SignedInUserTableAnnotationComposer extends Composer<_$AppDatabase, $SignedInUserTable> {
  $$SignedInUserTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authUid => $composableBuilder(column: $table.authUid, builder: (column) => column);

  GeneratedColumn<String> get userId => $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email => $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName =>
      $composableBuilder(column: $table.displayName, builder: (column) => column);

  GeneratedColumn<bool> get displayNameConfirmed =>
      $composableBuilder(column: $table.displayNameConfirmed, builder: (column) => column);
}

class $$SignedInUserTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SignedInUserTable,
          SignedInUserData,
          $$SignedInUserTableFilterComposer,
          $$SignedInUserTableOrderingComposer,
          $$SignedInUserTableAnnotationComposer,
          $$SignedInUserTableCreateCompanionBuilder,
          $$SignedInUserTableUpdateCompanionBuilder,
          (SignedInUserData, BaseReferences<_$AppDatabase, $SignedInUserTable, SignedInUserData>),
          SignedInUserData,
          PrefetchHooks Function()
        > {
  $$SignedInUserTableTableManager(_$AppDatabase db, $SignedInUserTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SignedInUserTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SignedInUserTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SignedInUserTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> authUid = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> displayNameConfirmed = const Value.absent(),
              }) => SignedInUserCompanion(
                id: id,
                authUid: authUid,
                userId: userId,
                email: email,
                displayName: displayName,
                displayNameConfirmed: displayNameConfirmed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String authUid,
                required String userId,
                required String email,
                required String displayName,
                required bool displayNameConfirmed,
              }) => SignedInUserCompanion.insert(
                id: id,
                authUid: authUid,
                userId: userId,
                email: email,
                displayName: displayName,
                displayNameConfirmed: displayNameConfirmed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SignedInUserTable, SignedInUserData>(table),
                  BaseReferences<_$AppDatabase, $SignedInUserTable, SignedInUserData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignedInUserTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SignedInUserTable,
      SignedInUserData,
      $$SignedInUserTableFilterComposer,
      $$SignedInUserTableOrderingComposer,
      $$SignedInUserTableAnnotationComposer,
      $$SignedInUserTableCreateCompanionBuilder,
      $$SignedInUserTableUpdateCompanionBuilder,
      (SignedInUserData, BaseReferences<_$AppDatabase, $SignedInUserTable, SignedInUserData>),
      SignedInUserData,
      PrefetchHooks Function()
    >;
typedef $$KnownListsTableCreateCompanionBuilder = KnownListsCompanion Function({
  required String id,
  required String name,
  required Role role,
  required int uncheckedItemCount,
  required int memberCount,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$KnownListsTableUpdateCompanionBuilder = KnownListsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<Role> role,
  Value<int> uncheckedItemCount,
  Value<int> memberCount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$KnownListsTableFilterComposer extends Composer<_$AppDatabase, $KnownListsTable> {
  $$KnownListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Role, Role, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get uncheckedItemCount =>
      $composableBuilder(column: $table.uncheckedItemCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get memberCount =>
      $composableBuilder(column: $table.memberCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$KnownListsTableOrderingComposer extends Composer<_$AppDatabase, $KnownListsTable> {
  $$KnownListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get uncheckedItemCount =>
      $composableBuilder(column: $table.uncheckedItemCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get memberCount =>
      $composableBuilder(column: $table.memberCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$KnownListsTableAnnotationComposer extends Composer<_$AppDatabase, $KnownListsTable> {
  $$KnownListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Role, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get uncheckedItemCount =>
      $composableBuilder(column: $table.uncheckedItemCount, builder: (column) => column);

  GeneratedColumn<int> get memberCount => $composableBuilder(column: $table.memberCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$KnownListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnownListsTable,
          KnownList,
          $$KnownListsTableFilterComposer,
          $$KnownListsTableOrderingComposer,
          $$KnownListsTableAnnotationComposer,
          $$KnownListsTableCreateCompanionBuilder,
          $$KnownListsTableUpdateCompanionBuilder,
          (KnownList, BaseReferences<_$AppDatabase, $KnownListsTable, KnownList>),
          KnownList,
          PrefetchHooks Function()
        > {
  $$KnownListsTableTableManager(_$AppDatabase db, $KnownListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KnownListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KnownListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$KnownListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Role> role = const Value.absent(),
                Value<int> uncheckedItemCount = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownListsCompanion(
                id: id,
                name: name,
                role: role,
                uncheckedItemCount: uncheckedItemCount,
                memberCount: memberCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required Role role,
                required int uncheckedItemCount,
                required int memberCount,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => KnownListsCompanion.insert(
                id: id,
                name: name,
                role: role,
                uncheckedItemCount: uncheckedItemCount,
                memberCount: memberCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnownListsTable, KnownList>(table),
                  BaseReferences<_$AppDatabase, $KnownListsTable, KnownList>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnownListsTable,
      KnownList,
      $$KnownListsTableFilterComposer,
      $$KnownListsTableOrderingComposer,
      $$KnownListsTableAnnotationComposer,
      $$KnownListsTableCreateCompanionBuilder,
      $$KnownListsTableUpdateCompanionBuilder,
      (KnownList, BaseReferences<_$AppDatabase, $KnownListsTable, KnownList>),
      KnownList,
      PrefetchHooks Function()
    >;
typedef $$SyncedItemsTableCreateCompanionBuilder = SyncedItemsCompanion Function({
  required String id,
  required String listId,
  required String name,
  Value<String?> quantity,
  Value<String?> unit,
  Value<String?> note,
  required String addedById,
  required String addedByName,
  required int addedAtMicros,
  Value<int?> checkedAtMicros,
  Value<String?> checkedById,
  Value<String?> checkedByName,
  Value<int> rowid,
});
typedef $$SyncedItemsTableUpdateCompanionBuilder = SyncedItemsCompanion Function({
  Value<String> id,
  Value<String> listId,
  Value<String> name,
  Value<String?> quantity,
  Value<String?> unit,
  Value<String?> note,
  Value<String> addedById,
  Value<String> addedByName,
  Value<int> addedAtMicros,
  Value<int?> checkedAtMicros,
  Value<String?> checkedById,
  Value<String?> checkedByName,
  Value<int> rowid,
});

class $$SyncedItemsTableFilterComposer extends Composer<_$AppDatabase, $SyncedItemsTable> {
  $$SyncedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addedById =>
      $composableBuilder(column: $table.addedById, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addedByName =>
      $composableBuilder(column: $table.addedByName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAtMicros =>
      $composableBuilder(column: $table.addedAtMicros, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get checkedAtMicros =>
      $composableBuilder(column: $table.checkedAtMicros, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkedById =>
      $composableBuilder(column: $table.checkedById, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkedByName =>
      $composableBuilder(column: $table.checkedByName, builder: (column) => ColumnFilters(column));
}

class $$SyncedItemsTableOrderingComposer extends Composer<_$AppDatabase, $SyncedItemsTable> {
  $$SyncedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addedById =>
      $composableBuilder(column: $table.addedById, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addedByName =>
      $composableBuilder(column: $table.addedByName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAtMicros =>
      $composableBuilder(column: $table.addedAtMicros, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get checkedAtMicros =>
      $composableBuilder(column: $table.checkedAtMicros, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkedById =>
      $composableBuilder(column: $table.checkedById, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkedByName =>
      $composableBuilder(column: $table.checkedByName, builder: (column) => ColumnOrderings(column));
}

class $$SyncedItemsTableAnnotationComposer extends Composer<_$AppDatabase, $SyncedItemsTable> {
  $$SyncedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity => $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get addedById => $composableBuilder(column: $table.addedById, builder: (column) => column);

  GeneratedColumn<String> get addedByName =>
      $composableBuilder(column: $table.addedByName, builder: (column) => column);

  GeneratedColumn<int> get addedAtMicros =>
      $composableBuilder(column: $table.addedAtMicros, builder: (column) => column);

  GeneratedColumn<int> get checkedAtMicros =>
      $composableBuilder(column: $table.checkedAtMicros, builder: (column) => column);

  GeneratedColumn<String> get checkedById =>
      $composableBuilder(column: $table.checkedById, builder: (column) => column);

  GeneratedColumn<String> get checkedByName =>
      $composableBuilder(column: $table.checkedByName, builder: (column) => column);
}

class $$SyncedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncedItemsTable,
          SyncedItem,
          $$SyncedItemsTableFilterComposer,
          $$SyncedItemsTableOrderingComposer,
          $$SyncedItemsTableAnnotationComposer,
          $$SyncedItemsTableCreateCompanionBuilder,
          $$SyncedItemsTableUpdateCompanionBuilder,
          (SyncedItem, BaseReferences<_$AppDatabase, $SyncedItemsTable, SyncedItem>),
          SyncedItem,
          PrefetchHooks Function()
        > {
  $$SyncedItemsTableTableManager(_$AppDatabase db, $SyncedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> addedById = const Value.absent(),
                Value<String> addedByName = const Value.absent(),
                Value<int> addedAtMicros = const Value.absent(),
                Value<int?> checkedAtMicros = const Value.absent(),
                Value<String?> checkedById = const Value.absent(),
                Value<String?> checkedByName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedItemsCompanion(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                note: note,
                addedById: addedById,
                addedByName: addedByName,
                addedAtMicros: addedAtMicros,
                checkedAtMicros: checkedAtMicros,
                checkedById: checkedById,
                checkedByName: checkedByName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String name,
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String addedById,
                required String addedByName,
                required int addedAtMicros,
                Value<int?> checkedAtMicros = const Value.absent(),
                Value<String?> checkedById = const Value.absent(),
                Value<String?> checkedByName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedItemsCompanion.insert(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                note: note,
                addedById: addedById,
                addedByName: addedByName,
                addedAtMicros: addedAtMicros,
                checkedAtMicros: checkedAtMicros,
                checkedById: checkedById,
                checkedByName: checkedByName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedItemsTable, SyncedItem>(table),
                  BaseReferences<_$AppDatabase, $SyncedItemsTable, SyncedItem>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncedItemsTable,
      SyncedItem,
      $$SyncedItemsTableFilterComposer,
      $$SyncedItemsTableOrderingComposer,
      $$SyncedItemsTableAnnotationComposer,
      $$SyncedItemsTableCreateCompanionBuilder,
      $$SyncedItemsTableUpdateCompanionBuilder,
      (SyncedItem, BaseReferences<_$AppDatabase, $SyncedItemsTable, SyncedItem>),
      SyncedItem,
      PrefetchHooks Function()
    >;
typedef $$SyncedHistoryTableCreateCompanionBuilder = SyncedHistoryCompanion Function({
  required String itemId,
  required String listId,
  required String name,
  Value<String?> quantity,
  Value<String?> unit,
  Value<String?> note,
  required int clearedAtMicros,
  required String clearedById,
  required String clearedByName,
  Value<int> rowid,
});
typedef $$SyncedHistoryTableUpdateCompanionBuilder = SyncedHistoryCompanion Function({
  Value<String> itemId,
  Value<String> listId,
  Value<String> name,
  Value<String?> quantity,
  Value<String?> unit,
  Value<String?> note,
  Value<int> clearedAtMicros,
  Value<String> clearedById,
  Value<String> clearedByName,
  Value<int> rowid,
});

class $$SyncedHistoryTableFilterComposer extends Composer<_$AppDatabase, $SyncedHistoryTable> {
  $$SyncedHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get clearedAtMicros =>
      $composableBuilder(column: $table.clearedAtMicros, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clearedById =>
      $composableBuilder(column: $table.clearedById, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clearedByName =>
      $composableBuilder(column: $table.clearedByName, builder: (column) => ColumnFilters(column));
}

class $$SyncedHistoryTableOrderingComposer extends Composer<_$AppDatabase, $SyncedHistoryTable> {
  $$SyncedHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get clearedAtMicros =>
      $composableBuilder(column: $table.clearedAtMicros, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clearedById =>
      $composableBuilder(column: $table.clearedById, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clearedByName =>
      $composableBuilder(column: $table.clearedByName, builder: (column) => ColumnOrderings(column));
}

class $$SyncedHistoryTableAnnotationComposer extends Composer<_$AppDatabase, $SyncedHistoryTable> {
  $$SyncedHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity => $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get clearedAtMicros =>
      $composableBuilder(column: $table.clearedAtMicros, builder: (column) => column);

  GeneratedColumn<String> get clearedById =>
      $composableBuilder(column: $table.clearedById, builder: (column) => column);

  GeneratedColumn<String> get clearedByName =>
      $composableBuilder(column: $table.clearedByName, builder: (column) => column);
}

class $$SyncedHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncedHistoryTable,
          SyncedHistoryData,
          $$SyncedHistoryTableFilterComposer,
          $$SyncedHistoryTableOrderingComposer,
          $$SyncedHistoryTableAnnotationComposer,
          $$SyncedHistoryTableCreateCompanionBuilder,
          $$SyncedHistoryTableUpdateCompanionBuilder,
          (SyncedHistoryData, BaseReferences<_$AppDatabase, $SyncedHistoryTable, SyncedHistoryData>),
          SyncedHistoryData,
          PrefetchHooks Function()
        > {
  $$SyncedHistoryTableTableManager(_$AppDatabase db, $SyncedHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncedHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncedHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncedHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> clearedAtMicros = const Value.absent(),
                Value<String> clearedById = const Value.absent(),
                Value<String> clearedByName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncedHistoryCompanion(
                itemId: itemId,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                note: note,
                clearedAtMicros: clearedAtMicros,
                clearedById: clearedById,
                clearedByName: clearedByName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String listId,
                required String name,
                Value<String?> quantity = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int clearedAtMicros,
                required String clearedById,
                required String clearedByName,
                Value<int> rowid = const Value.absent(),
              }) => SyncedHistoryCompanion.insert(
                itemId: itemId,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                note: note,
                clearedAtMicros: clearedAtMicros,
                clearedById: clearedById,
                clearedByName: clearedByName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncedHistoryTable, SyncedHistoryData>(table),
                  BaseReferences<_$AppDatabase, $SyncedHistoryTable, SyncedHistoryData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncedHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncedHistoryTable,
      SyncedHistoryData,
      $$SyncedHistoryTableFilterComposer,
      $$SyncedHistoryTableOrderingComposer,
      $$SyncedHistoryTableAnnotationComposer,
      $$SyncedHistoryTableCreateCompanionBuilder,
      $$SyncedHistoryTableUpdateCompanionBuilder,
      (SyncedHistoryData, BaseReferences<_$AppDatabase, $SyncedHistoryTable, SyncedHistoryData>),
      SyncedHistoryData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String mutationId,
  required MutationType type,
  required String itemId,
  required String listId,
  required ItemFields fields,
  required int clientTimestampMicros,
  required String byId,
  required String byName,
  Value<bool> applied,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> mutationId,
  Value<MutationType> type,
  Value<String> itemId,
  Value<String> listId,
  Value<ItemFields> fields,
  Value<int> clientTimestampMicros,
  Value<String> byId,
  Value<String> byName,
  Value<bool> applied,
});

class $$OutboxTableFilterComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mutationId =>
      $composableBuilder(column: $table.mutationId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MutationType, MutationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ItemFields, ItemFields, String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get clientTimestampMicros =>
      $composableBuilder(column: $table.clientTimestampMicros, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get byId => $composableBuilder(column: $table.byId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get byName =>
      $composableBuilder(column: $table.byName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => ColumnFilters(column));
}

class $$OutboxTableOrderingComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mutationId =>
      $composableBuilder(column: $table.mutationId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get clientTimestampMicros =>
      $composableBuilder(column: $table.clientTimestampMicros, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get byId =>
      $composableBuilder(column: $table.byId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get byName =>
      $composableBuilder(column: $table.byName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => ColumnOrderings(column));
}

class $$OutboxTableAnnotationComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(column: $table.mutationId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MutationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get listId => $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemFields, String> get fields =>
      $composableBuilder(column: $table.fields, builder: (column) => column);

  GeneratedColumn<int> get clientTimestampMicros =>
      $composableBuilder(column: $table.clientTimestampMicros, builder: (column) => column);

  GeneratedColumn<String> get byId => $composableBuilder(column: $table.byId, builder: (column) => column);

  GeneratedColumn<String> get byName => $composableBuilder(column: $table.byName, builder: (column) => column);

  GeneratedColumn<bool> get applied => $composableBuilder(column: $table.applied, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<MutationType> type = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<ItemFields> fields = const Value.absent(),
                Value<int> clientTimestampMicros = const Value.absent(),
                Value<String> byId = const Value.absent(),
                Value<String> byName = const Value.absent(),
                Value<bool> applied = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                mutationId: mutationId,
                type: type,
                itemId: itemId,
                listId: listId,
                fields: fields,
                clientTimestampMicros: clientTimestampMicros,
                byId: byId,
                byName: byName,
                applied: applied,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String mutationId,
                required MutationType type,
                required String itemId,
                required String listId,
                required ItemFields fields,
                required int clientTimestampMicros,
                required String byId,
                required String byName,
                Value<bool> applied = const Value.absent(),
              }) => OutboxCompanion.insert(
                seq: seq,
                mutationId: mutationId,
                type: type,
                itemId: itemId,
                listId: listId,
                fields: fields,
                clientTimestampMicros: clientTimestampMicros,
                byId: byId,
                byName: byName,
                applied: applied,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorTableCreateCompanionBuilder = SyncCursorCompanion Function({Value<int> id, required String cursor});
typedef $$SyncCursorTableUpdateCompanionBuilder = SyncCursorCompanion Function({Value<int> id, Value<String> cursor});

class $$SyncCursorTableFilterComposer extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => ColumnFilters(column));
}

class $$SyncCursorTableOrderingComposer extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => ColumnOrderings(column));
}

class $$SyncCursorTableAnnotationComposer extends Composer<_$AppDatabase, $SyncCursorTable> {
  $$SyncCursorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cursor => $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$SyncCursorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorTable,
          SyncCursorData,
          $$SyncCursorTableFilterComposer,
          $$SyncCursorTableOrderingComposer,
          $$SyncCursorTableAnnotationComposer,
          $$SyncCursorTableCreateCompanionBuilder,
          $$SyncCursorTableUpdateCompanionBuilder,
          (SyncCursorData, BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorData>),
          SyncCursorData,
          PrefetchHooks Function()
        > {
  $$SyncCursorTableTableManager(_$AppDatabase db, $SyncCursorTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncCursorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncCursorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncCursorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> cursor = const Value.absent(),
          }) => SyncCursorCompanion(id: id, cursor: cursor),
          createCompanionCallback: ({Value<int> id = const Value.absent(), required String cursor}) =>
              SyncCursorCompanion.insert(id: id, cursor: cursor),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorTable, SyncCursorData>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorTable,
      SyncCursorData,
      $$SyncCursorTableFilterComposer,
      $$SyncCursorTableOrderingComposer,
      $$SyncCursorTableAnnotationComposer,
      $$SyncCursorTableCreateCompanionBuilder,
      $$SyncCursorTableUpdateCompanionBuilder,
      (SyncCursorData, BaseReferences<_$AppDatabase, $SyncCursorTable, SyncCursorData>),
      SyncCursorData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KnownHealthTableTableManager get knownHealth => $$KnownHealthTableTableManager(_db, _db.knownHealth);
  $$SignedInUserTableTableManager get signedInUser => $$SignedInUserTableTableManager(_db, _db.signedInUser);
  $$KnownListsTableTableManager get knownLists => $$KnownListsTableTableManager(_db, _db.knownLists);
  $$SyncedItemsTableTableManager get syncedItems => $$SyncedItemsTableTableManager(_db, _db.syncedItems);
  $$SyncedHistoryTableTableManager get syncedHistory => $$SyncedHistoryTableTableManager(_db, _db.syncedHistory);
  $$OutboxTableTableManager get outbox => $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncCursorTableTableManager get syncCursor => $$SyncCursorTableTableManager(_db, _db.syncCursor);
}
