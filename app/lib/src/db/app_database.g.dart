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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KnownHealthTable knownHealth = $KnownHealthTable(this);
  late final $SignedInUserTable signedInUser = $SignedInUserTable(this);
  late final $KnownListsTable knownLists = $KnownListsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [knownHealth, signedInUser, knownLists];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KnownHealthTableTableManager get knownHealth => $$KnownHealthTableTableManager(_db, _db.knownHealth);
  $$SignedInUserTableTableManager get signedInUser => $$SignedInUserTableTableManager(_db, _db.signedInUser);
  $$KnownListsTableTableManager get knownLists => $$KnownListsTableTableManager(_db, _db.knownLists);
}
