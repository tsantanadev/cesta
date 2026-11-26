import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:cesta/src/session/auth_messages.dart' show maxDisplayNameLength;
import 'package:dio/dio.dart';

import 'fake_auth_gateway.dart';

/// Seam 2 fake: stands in for the generated [ApiClient].
///
/// It answers from in-memory state and can be switched [offline], in which
/// case every call fails the way Dio does when the network is unreachable.
/// It acts on behalf of whoever is signed in to [auth], as the real client
/// does by sending that User's ID token.
class FakeApiClient implements ApiClient {
  FakeApiClient({required this.auth, this.health = const Health(status: HealthStatus.ok, database: HealthDatabase.up)});

  final FakeAuthGateway auth;

  /// When true, display name updates are rejected as invalid (400).
  bool rejectDisplayNames = false;

  /// When true, display name updates are rate limited (429).
  bool rateLimited = false;

  /// Users the fake backend knows, by identity provider uid.
  final _users = <String, User>{};

  /// The health the fake backend reports.
  Health health;

  /// When true, every call throws a connection error.
  bool offline = false;

  /// When set, every call throws this instead of answering, e.g. a parse
  /// failure on a malformed response.
  Object? failure;

  void goOffline() => offline = true;
  void goOnline() => offline = false;

  @override
  Future<GetHealthResult> getHealth({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _failIfOffline('/health');
    if (failure case final failure?) throw failure;
    return health.status == HealthStatus.ok ? GetHealth200(health) : GetHealth503(health);
  }

  /// The backend's User for [email], if it has one.
  User? userFor(String email) => _users.values.where((u) => u.email == email).firstOrNull;

  /// Stores a User for [identity], as if they had used the app before.
  void addUser(FakeIdentity identity, {required String displayName, bool confirmed = true}) =>
      _users[identity.uid] = User(
        id: 'user-${identity.uid}',
        email: identity.email,
        displayName: displayName,
        displayNameConfirmed: confirmed,
      );

  @override
  Future<GetMeResult> getMe({Map<String, Object?> extra = const {}, CancelToken? cancelToken, Options? options}) async {
    _failIfOffline('/api/me');
    final identity = auth.current;
    if (identity == null) return const GetMe401(_unauthenticated);
    // Like the server: create the User on first sight with a suggested name.
    if (!_users.containsKey(identity.uid)) {
      addUser(identity, displayName: identity.name ?? identity.email.split('@').first, confirmed: false);
    }
    return GetMe200(_users[identity.uid]!);
  }

  @override
  Future<UpdateMeResult> updateMe({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required UserUpdate body,
  }) async {
    _failIfOffline('/api/me');
    final identity = auth.current;
    final user = identity == null ? null : _users[identity.uid];
    if (identity == null || user == null) return const UpdateMe401(_unauthenticated);
    if (rateLimited) {
      return const UpdateMe429(ApiError(code: ApiErrorCode.rateLimited, message: 'too many requests'));
    }
    final name = body.displayName.trim();
    if (rejectDisplayNames || name.isEmpty || name.runes.length > maxDisplayNameLength) {
      return const UpdateMe400(ApiError(code: ApiErrorCode.invalidDisplayName, message: 'invalid display name'));
    }
    final updated = User(id: user.id, email: user.email, displayName: name, displayNameConfirmed: true);
    _users[identity.uid] = updated;
    return UpdateMe200(updated);
  }

  // ---- Lists -------------------------------------------------------------

  /// How many Lists a User may own (not deleted), like the server's 100.
  int listLimit = 100;

  /// Every List the fake backend knows, deleted or not, in creation order.
  final _lists = <String, _FakeList>{};
  int _nextListId = 1;

  /// Names of the Lists [identity] is a Member of and that aren't deleted.
  List<String> listNamesOf(FakeIdentity identity) => [
    for (final l in _lists.values)
      if (l.deletedAt == null && l.members.contains(identity.uid)) l.name,
  ];

  /// Stores a List owned by [owner], as if created earlier. [sharedWith] adds
  /// Editors; [otherMembers] adds Members who aren't Users of this test.
  String addList(
    FakeIdentity owner, {
    required String name,
    int uncheckedItemCount = 0,
    List<FakeIdentity> sharedWith = const [],
    int otherMembers = 0,
    Duration? deletedAgo,
  }) {
    final id = '00000000-0000-4000-8000-${(_nextListId++).toString().padLeft(12, '0')}';
    _lists[id] = _FakeList(
      id: id,
      ownerUid: owner.uid,
      name: name,
      createdAt: DateTime.now().toUtc(),
      members: {owner.uid, for (final e in sharedWith) e.uid, for (var i = 0; i < otherMembers; i++) 'other-$id-$i'},
      uncheckedItemCount: uncheckedItemCount,
      deletedAt: deletedAgo == null ? null : DateTime.now().toUtc().subtract(deletedAgo),
    );
    return id;
  }

  /// Stores a List owned by someone else and shared with [editor].
  String addListSharedWith(FakeIdentity editor, {required String name, int uncheckedItemCount = 0}) => addList(
    FakeIdentity(uid: 'owner-of-$name', email: 'owner@example.com'),
    name: name,
    sharedWith: [editor],
    uncheckedItemCount: uncheckedItemCount,
  );

  /// Deletes List [id] behind the app's back, e.g. from another device.
  void deleteListNow(String id) => _lists[id]!.deletedAt = DateTime.now().toUtc();

  static const _restoreWindow = Duration(days: 30);

  ListSummary _summary(_FakeList l, String uid) => ListSummary(
    id: l.id,
    name: l.name,
    role: l.ownerUid == uid ? Role.owner : Role.editor,
    uncheckedItemCount: l.uncheckedItemCount,
    memberCount: l.members.length,
    createdAt: l.createdAt,
  );

  DeletedList _deleted(_FakeList l) =>
      DeletedList(id: l.id, name: l.name, deletedAt: l.deletedAt!, purgeAt: l.deletedAt!.add(_restoreWindow));

  bool _restorable(_FakeList l) => DateTime.now().toUtc().isBefore(l.deletedAt!.add(_restoreWindow));

  int _ownedLive(String uid) => _lists.values.where((l) => l.ownerUid == uid && l.deletedAt == null).length;

  /// The List [listId] as [uid] may see it: null when they aren't a Member or
  /// it is gone for good.
  _FakeList? _visible(String listId, String uid) {
    final l = _lists[listId];
    if (l == null || !l.members.contains(uid)) return null;
    if (l.deletedAt != null && !_restorable(l)) return null;
    return l;
  }

  static ApiError _error(ApiErrorCode code) => ApiError(code: code, message: code.toJson());

  static String? _validName(String raw) {
    final name = raw.trim();
    if (name.isEmpty || name.runes.length > 60 || name.runes.any((r) => r < 0x20 || r == 0x7f)) return null;
    return name;
  }

  @override
  Future<ListListsResult> listLists({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _failIfOffline('/api/lists');
    final identity = auth.current;
    if (identity == null) return const ListLists401(_unauthenticated);
    final mine = _lists.values.where((l) => l.deletedAt == null && l.members.contains(identity.uid)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListLists200(ListSummaries(lists: [for (final l in mine) _summary(l, identity.uid)]));
  }

  @override
  Future<CreateListResult> createList({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required ListCreate body,
  }) async {
    _failIfOffline('/api/lists');
    final identity = auth.current;
    if (identity == null) return const CreateList401(_unauthenticated);
    if (rateLimited) return CreateList429(_error(ApiErrorCode.rateLimited));
    final existing = _lists[body.id];
    if (existing != null) {
      if (existing.ownerUid != identity.uid) return CreateList409(_error(ApiErrorCode.listIdTaken));
      if (existing.deletedAt != null) return CreateList409(_error(ApiErrorCode.listDeleted));
      return CreateList200(_summary(existing, identity.uid));
    }
    final name = _validName(body.name.value);
    if (name == null) return CreateList400(_error(ApiErrorCode.invalidListName));
    if (_ownedLive(identity.uid) >= listLimit) return CreateList409(_error(ApiErrorCode.limitExceeded));
    final created = _FakeList(
      id: body.id,
      ownerUid: identity.uid,
      name: name,
      createdAt: DateTime.now().toUtc(),
      members: {identity.uid},
    );
    _lists[body.id] = created;
    return CreateList201(_summary(created, identity.uid));
  }

  @override
  Future<RenameListResult> renameList({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
    required ListRename body,
  }) async {
    _failIfOffline('/api/lists/$listId');
    final identity = auth.current;
    if (identity == null) return const RenameList401(_unauthenticated);
    final l = _visible(listId, identity.uid);
    if (l == null) return RenameList404(_error(ApiErrorCode.listNotFound));
    if (l.ownerUid != identity.uid) return RenameList403(_error(ApiErrorCode.notListOwner));
    if (l.deletedAt != null) return RenameList409(_error(ApiErrorCode.listDeleted));
    final name = _validName(body.name.value);
    if (name == null) return RenameList400(_error(ApiErrorCode.invalidListName));
    l.name = name;
    return RenameList200(_summary(l, identity.uid));
  }

  @override
  Future<DeleteListResult> deleteList({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
  }) async {
    _failIfOffline('/api/lists/$listId');
    final identity = auth.current;
    if (identity == null) return const DeleteList401(_unauthenticated);
    final l = _visible(listId, identity.uid);
    if (l == null) return DeleteList404(_error(ApiErrorCode.listNotFound));
    if (l.ownerUid != identity.uid) return DeleteList403(_error(ApiErrorCode.notListOwner));
    l.deletedAt ??= DateTime.now().toUtc();
    return DeleteList200(_deleted(l));
  }

  @override
  Future<RestoreListResult> restoreList({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
  }) async {
    _failIfOffline('/api/lists/$listId/restore');
    final identity = auth.current;
    if (identity == null) return const RestoreList401(_unauthenticated);
    final l = _visible(listId, identity.uid);
    if (l == null) return RestoreList404(_error(ApiErrorCode.listNotFound));
    if (l.ownerUid != identity.uid) return RestoreList403(_error(ApiErrorCode.notListOwner));
    if (l.deletedAt != null && _ownedLive(identity.uid) >= listLimit) {
      return RestoreList409(_error(ApiErrorCode.limitExceeded));
    }
    l.deletedAt = null;
    return RestoreList200(_summary(l, identity.uid));
  }

  @override
  Future<ListDeletedListsResult> listDeletedLists({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
  }) async {
    _failIfOffline('/api/deleted-lists');
    final identity = auth.current;
    if (identity == null) return const ListDeletedLists401(_unauthenticated);
    final deleted =
        _lists.values.where((l) => l.ownerUid == identity.uid && l.deletedAt != null && _restorable(l)).toList()
          ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return ListDeletedLists200(DeletedLists(lists: [for (final l in deleted) _deleted(l)]));
  }

  static const _unauthenticated = ApiError(code: ApiErrorCode.unauthenticated, message: 'no valid token');

  void _failIfOffline(String path) {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: RequestOptions(path: path),
        reason: 'FakeApiClient is offline',
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeApiClient does not implement ${invocation.memberName} yet');
}

/// A List as the fake backend stores it.
class _FakeList {
  _FakeList({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.createdAt,
    required this.members,
    this.uncheckedItemCount = 0,
    this.deletedAt,
  });

  final String id;
  final String ownerUid;
  String name;
  final DateTime createdAt;
  final Set<String> members;
  final int uncheckedItemCount;
  DateTime? deletedAt;
}
