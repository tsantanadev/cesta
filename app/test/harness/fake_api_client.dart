import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:cesta/src/sync/network_status.dart';
import 'package:dio/dio.dart';

import 'fake_auth_gateway.dart';

/// The API contract's longest display name, as the server enforces it.
const _maxDisplayNameLength = 50;

/// Seam 2 fake: stands in for the generated [ApiClient].
///
/// It answers from in-memory state and can be switched [offline], in which
/// case every call fails the way Dio does when the network is unreachable,
/// and its [network] reports the phone's connection gone.
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

  /// When true, every call throws a connection error and [network] reports
  /// no connection.
  bool get offline => _offline;
  set offline(bool value) {
    if (value == _offline) return;
    _offline = value;
    _connectivity.add(!value);
  }

  bool _offline = false;
  final _connectivity = StreamController<bool>.broadcast();

  /// The phone's connection as the OS reports it, which follows [offline]: so
  /// tests switch one thing to take the phone off the network.
  late final NetworkStatus network = _FakeNetworkStatus(this);

  Future<void> close() => _connectivity.close();

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
    if (rateLimited) return const GetMe429(ApiError(code: ApiErrorCode.rateLimited, message: 'too many requests'));
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
    if (rejectDisplayNames || name.isEmpty || name.runes.length > _maxDisplayNameLength) {
      return const UpdateMe400(ApiError(code: ApiErrorCode.invalidDisplayName, message: 'invalid display name'));
    }
    final updated = User(id: user.id, email: user.email, displayName: name, displayNameConfirmed: true);
    _users[identity.uid] = updated;
    return UpdateMe200(updated);
  }

  // ---- Lists -------------------------------------------------------------

  /// How many Lists a User may own (not deleted), like the server's 100.
  int listLimit = 100;

  /// When true, the next List create is applied but its response is lost, as
  /// when the connection drops before the answer arrives.
  bool loseNextCreateResponse = false;

  /// When set (401 or 429), loading the User's Lists answers with this status.
  int? listListsStatus;

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

  /// Removes List [id] for good behind the app's back, as the purge does.
  void purgeListNow(String id) => _lists.remove(id);

  /// Deletes List [id] behind the app's back, e.g. from another device.
  void deleteListNow(String id) => _lists[id]!
    ..deletedAt = DateTime.now().toUtc()
    ..deletedSeq = ++_changeSeq;

  static const _restoreWindow = Duration(days: 30);

  ListSummary _summary(_FakeList l, String uid) => ListSummary(
    id: l.id,
    name: l.name,
    role: l.ownerUid == uid ? Role.owner : Role.editor,
    // Counted from its Items once it has any, as the server does.
    uncheckedItemCount: _items.values.any((i) => i.listId == l.id)
        ? _liveItems.where((i) => i.listId == l.id && i.checkedAt == null).length
        : l.uncheckedItemCount,
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

  static ApiError _error(ApiErrorCode code, {int? limit}) => ApiError(code: code, message: code.toJson(), limit: limit);

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
    if (identity == null || listListsStatus == 401) return const ListLists401(_unauthenticated);
    if (listListsStatus == 429) return ListLists429(_error(ApiErrorCode.rateLimited));
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
    final result = _createList(identity, body);
    if (loseNextCreateResponse) {
      loseNextCreateResponse = false;
      throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 30),
        requestOptions: RequestOptions(path: '/api/lists'),
      );
    }
    return result;
  }

  CreateListResult _createList(FakeIdentity identity, ListCreate body) {
    final existing = _lists[body.id];
    if (existing != null) {
      if (existing.ownerUid != identity.uid) return CreateList409(_error(ApiErrorCode.listIdTaken));
      if (existing.deletedAt != null) return CreateList409(_error(ApiErrorCode.listDeleted));
      return CreateList200(_summary(existing, identity.uid));
    }
    final name = _validName(body.name.value);
    if (name == null) return CreateList400(_error(ApiErrorCode.invalidListName));
    if (_ownedLive(identity.uid) >= listLimit) {
      return CreateList409(_error(ApiErrorCode.limitExceeded, limit: listLimit));
    }
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
      return RestoreList409(_error(ApiErrorCode.limitExceeded, limit: listLimit));
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

  // ---- Items and sync ---------------------------------------------------

  /// How many Items a List may hold, like the server's 500.
  int itemLimit = 500;

  /// While set, sync answers reach the app only once it completes, as over a
  /// slow network: the server has already answered by then.
  Completer<void>? slowSync;

  /// When set, the server refuses every push as a whole with this HTTP
  /// status (e.g. 400, 403, 503) instead of answering it.
  int? refusePushes;

  /// When set, every pushed mutation is rejected with this code, as when the
  /// User was removed from the List meanwhile.
  ApiErrorCode? rejectMutations;

  /// When set, only mutations of these types are rejected by
  /// [rejectMutations]; the others are applied as usual.
  Set<MutationType>? rejectOnly;

  /// Every Item the fake backend knows, removed or not, in creation order.
  final _items = <String, _FakeItem>{};
  final _mutationResults = <String, MutationResult>{};
  int _changeSeq = 0;
  int _nextItemId = 1;

  /// Stores an Item on List [listId], as if added earlier by [addedBy].
  /// [checkedBy] checks it.
  String addItem(
    String listId, {
    required String name,
    required FakeIdentity addedBy,
    String? quantity,
    ItemUnit? unit,
    String? note,
    FakeIdentity? checkedBy,
  }) {
    final id = '00000000-0000-4000-9000-${(_nextItemId++).toString().padLeft(12, '0')}';
    final now = DateTime.now().toUtc();
    _items[id] = _FakeItem(
      id: id,
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit?.toJson(),
      note: note,
      addedByUid: addedBy.uid,
      addedAt: now.add(Duration(milliseconds: _nextItemId)),
      checkedByUid: checkedBy?.uid,
      checkedAt: checkedBy == null ? null : now,
      seq: ++_changeSeq,
    );
    return id;
  }

  /// [by] checks the Item named [name] behind the app's back, e.g. on another phone.
  void checkItemNow(String name, {required FakeIdentity by}) => _liveItems.firstWhere((i) => i.name == name)
    ..checkedByUid = by.uid
    ..checkedAt = DateTime.now().toUtc()
    ..seq = ++_changeSeq;

  /// [by] puts the Item named [name] back to buy behind the app's back.
  void uncheckItemNow(String name, {required FakeIdentity by}) => _liveItems.firstWhere((i) => i.name == name)
    ..checkedByUid = null
    ..checkedAt = null
    ..seq = ++_changeSeq;

  /// Someone removes the Item named [name] behind the app's back.
  void removeItemNow(String name) => _liveItems.firstWhere((i) => i.name == name)
    ..deleted = true
    ..seq = ++_changeSeq;

  /// [by] clears the Checked Items of List [listId] behind the app's back,
  /// e.g. on another phone.
  void clearCheckedNow(String listId, {required FakeIdentity by}) {
    for (final i in _liveItems.where((i) => i.listId == listId && i.checkedAt != null).toList()) {
      _clear(i, by: by.uid);
    }
  }

  /// Tombstones [item] and records it in its List's Item history, each with
  /// its own change number, as the server does.
  void _clear(_FakeItem item, {required String by}) {
    item
      ..deleted = true
      ..cleared = true
      ..seq = ++_changeSeq;
    _history.add(
      _FakeHistoryEntry(
        HistoryEntry(
          itemId: item.id,
          listId: item.listId,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit == null ? null : HistoryEntryUnit.fromJson(item.unit),
          note: item.note,
          clearedAt: _clearedAt(),
          clearedBy: UserRef(id: _userIdOf(by), displayName: _displayNameOf(by)),
        ),
        seq: ++_changeSeq,
      ),
    );
  }

  /// The Item history of every List, in the order the Items were cleared.
  final _history = <_FakeHistoryEntry>[];

  /// Now, but after every clear before it, so history order is clear-cut.
  DateTime _clearedAt() {
    final now = DateTime.now().toUtc();
    final last = _history.lastOrNull?.entry.clearedAt;
    return last == null || now.isAfter(last) ? now : last.add(const Duration(microseconds: 1));
  }

  Iterable<_FakeItem> get _liveItems => _items.values.where((i) => !i.deleted);

  /// Names of the Items on List [listId] still to buy, in insertion order.
  List<String> itemsToBuy(String listId) => [
    for (final i in _liveItems)
      if (i.listId == listId && i.checkedAt == null) i.name,
  ];

  /// Names of the Checked Items on List [listId].
  List<String> itemsInBasket(String listId) => [
    for (final i in _liveItems)
      if (i.listId == listId && i.checkedAt != null) i.name,
  ];

  /// The Item named [name], as the server stores it.
  Item serverItem(String name) => _toItem(_liveItems.firstWhere((i) => i.name == name));

  String _displayNameOf(String uid) => _users[uid]?.displayName ?? uid;

  String _userIdOf(String uid) => _users[uid]?.id ?? 'user-$uid';

  Item _toItem(_FakeItem i) => Item(
    id: i.id,
    listId: i.listId,
    name: i.name,
    // Like the server, every optional field is sent, as null when empty.
    quantity: (value: i.quantity),
    unit: (value: i.unit == null ? null : ItemUnit.fromJson(i.unit)),
    note: (value: i.note),
    addedBy: UserRef(id: _userIdOf(i.addedByUid), displayName: _displayNameOf(i.addedByUid)),
    addedAt: i.addedAt,
    checkedAt: (value: i.checkedAt),
    checkedBy: (
      value: i.checkedByUid == null
          ? null
          : ItemCheckedBy(id: _userIdOf(i.checkedByUid!), displayName: _displayNameOf(i.checkedByUid!)),
    ),
    updatedAt: i.addedAt,
  );

  @override
  Future<PushMutationsResult> pushMutations({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required PushRequest body,
  }) async {
    _failIfOffline('/api/sync/push');
    final identity = auth.current;
    if (identity == null) return const PushMutations401(_unauthenticated);
    // Read the request as the server would: from the JSON on the wire.
    body = PushRequest.fromJson(_wire(body.toJson()));
    switch (refusePushes) {
      case null:
        break;
      case 400:
        return PushMutations400(_error(ApiErrorCode.invalidItem));
      case final status:
        final request = RequestOptions(path: '/api/sync/push');
        throw DioException.badResponse(
          statusCode: status,
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: status),
        );
    }
    if (body.mutations.isEmpty || body.mutations.length > 100) {
      return PushMutations400(_error(ApiErrorCode.invalidItem));
    }
    return PushMutations200(
      PushResponse(results: [for (final m in body.mutations) _mutationResults[m.id] ??= _apply(identity, m)]),
    );
  }

  MutationResult _apply(FakeIdentity identity, Mutation m) {
    MutationResult rejected(ApiErrorCode code, {int? limit}) => MutationResult(
      mutationId: m.id,
      status: MutationResultStatus.rejected,
      reason: _error(code, limit: limit),
    );
    final applied = MutationResult(mutationId: m.id, status: MutationResultStatus.applied);
    if (rejectMutations case final code? when rejectOnly?.contains(m.type) ?? true) return rejected(code);
    final fields = m.fields ?? const ItemFields();
    switch (m.type) {
      case MutationType.itemCreate:
        final listId = m.listId;
        final list = listId == null ? null : _visible(listId, identity.uid);
        if (listId == null || list == null) return rejected(ApiErrorCode.listNotFound);
        if (list.deletedAt != null) return rejected(ApiErrorCode.listDeleted);
        if (_items.containsKey(m.entityId)) return rejected(ApiErrorCode.invalidItem);
        final name = fields.name?.trim() ?? '';
        if (name.isEmpty || name.runes.length > 80) return rejected(ApiErrorCode.invalidItem);
        if (_liveItems.where((i) => i.listId == listId).length >= itemLimit) {
          return rejected(ApiErrorCode.limitExceeded, limit: itemLimit);
        }
        _items[m.entityId] = _FakeItem(
          id: m.entityId,
          listId: listId,
          name: name,
          quantity: fields.quantity?.value,
          unit: fields.unit?.value?.toJson(),
          note: fields.note?.value,
          addedByUid: identity.uid,
          addedAt: DateTime.now().toUtc(),
          seq: ++_changeSeq,
        );
        return applied;
      case MutationType.itemUpdate || MutationType.itemDelete:
        final item = _items[m.entityId];
        if (item == null || _visible(item.listId, identity.uid) == null) return rejected(ApiErrorCode.itemNotFound);
        if (item.deleted) return rejected(ApiErrorCode.itemDeleted);
        if (m.type == MutationType.itemDelete) {
          item.deleted = true;
        } else {
          if (fields.name case final name?) item.name = name.trim();
          // A field present as null clears it.
          if (fields.quantity case final q?) item.quantity = q.value;
          if (fields.unit case final u?) item.unit = u.value?.toJson();
          if (fields.note case final n?) item.note = n.value;
          if (fields.checked case final checked?) {
            item.checkedAt = checked ? DateTime.now().toUtc() : null;
            item.checkedByUid = checked ? identity.uid : null;
          }
        }
        item.seq = ++_changeSeq;
        return applied;
      case MutationType.itemClear:
        final item = _items[m.entityId];
        if (item == null || _visible(item.listId, identity.uid) == null) return rejected(ApiErrorCode.itemNotFound);
        if (item.cleared) return applied; // cleared already, e.g. on another phone: nothing more to record
        if (item.deleted) return rejected(ApiErrorCode.itemDeleted);
        if (item.checkedAt == null) return rejected(ApiErrorCode.itemNotChecked);
        _clear(item, by: identity.uid);
        return applied;
    }
  }

  @override
  Future<PullChangesResult> pullChanges({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    String? cursor,
    int? limit,
  }) async {
    _failIfOffline('/api/sync/pull');
    final identity = auth.current;
    if (identity == null) return const PullChanges401(_unauthenticated);
    final since = cursor == null ? 0 : int.parse(cursor);
    bool visible(String listId) {
      final list = _lists[listId];
      return list != null && list.deletedAt == null && list.members.contains(identity.uid);
    }

    // Items and history entries share one stream of change numbers.
    final changed = <({int seq, _FakeItem? item, HistoryEntry? entry})>[
      for (final i in _items.values)
        if (i.seq > since && visible(i.listId)) (seq: i.seq, item: i, entry: null),
      for (final h in _history)
        if (h.seq > since && visible(h.entry.listId)) (seq: h.seq, item: null, entry: h.entry),
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    final page = changed.take(limit ?? 500).toList();
    final items = [for (final c in page) ?c.item];
    // Lists deleted since, sent with the last page.
    final deleted = page.length < changed.length
        ? const <_FakeList>[]
        : _lists.values.where(
            (l) => l.deletedAt != null && (l.deletedSeq ?? 0) > since && l.members.contains(identity.uid),
          );
    final last = [if (page.isNotEmpty) page.last.seq, for (final l in deleted) l.deletedSeq!, since].reduce(math.max);
    final answer = PullChanges200(
      _pullResponse(
        items: [for (final i in items.where((i) => !i.deleted)) _toItem(i)],
        history: [for (final c in page) ?c.entry],
        tombstones: [
          for (final i in items.where((i) => i.deleted))
            Tombstone(type: TombstoneType.item, id: i.id, listId: i.listId),
          for (final l in deleted) Tombstone(type: TombstoneType.list, id: l.id),
        ],
        cursor: '$last',
        hasMore: page.length < changed.length,
      ),
    );
    await slowSync?.future;
    return answer;
  }

  // ---- Invitations --------------------------------------------------------

  /// How many Invitations a User may send in any 24 hours, like the server's 20.
  int invitationLimit = 20;

  /// Every Invitation the fake backend knows, in creation order.
  final _invitations = <_FakeInvitation>[];
  int _nextInvitationId = 1;

  /// The emails, in the language they were sent in, one per Invitation sent.
  final sentInvitationEmails = <({String to, InvitationCreateLanguage language})>[];

  /// The addresses invited to List [listId] and still pending, newest first.
  List<String> pendingInvitationEmails(String listId) => [
    for (final i in _invitations.reversed)
      if (i.listId == listId && i.status == InvitationStatus.pending) i.email,
  ];

  /// Stores a pending Invitation to List [listId] for [email], sent by [by]
  /// (the List's Owner unless given) as if earlier today.
  String addInvitation(String listId, {required String email, FakeIdentity? by}) {
    final list = _lists[listId]!;
    return _invite(list, email: email, byUid: by?.uid ?? list.ownerUid).id;
  }

  /// [by] sends [count] Invitations today to Lists of theirs other than these.
  void sendInvitationsToday(FakeIdentity by, int count) {
    final elsewhere = addList(by, name: 'Elsewhere');
    for (var n = 0; n < count; n++) {
      addInvitation(elsewhere, email: 'someone$n@example.com', by: by);
    }
  }

  _FakeInvitation _invite(_FakeList list, {required String email, required String byUid}) {
    final invitation = _FakeInvitation(
      id: '00000000-0000-4000-a000-${(_nextInvitationId++).toString().padLeft(12, '0')}',
      listId: list.id,
      email: email,
      invitedByUid: byUid,
      createdAt: DateTime.now().toUtc(),
    );
    _invitations.add(invitation);
    return invitation;
  }

  Invitation _toInvitation(_FakeInvitation i) => Invitation(
    id: i.id,
    listId: i.listId,
    listName: _lists[i.listId]!.name,
    email: i.email,
    invitedBy: UserRef(id: _userIdOf(i.invitedByUid), displayName: _displayNameOf(i.invitedByUid)),
    status: i.status,
    createdAt: i.createdAt,
    expiresAt: i.createdAt.add(const Duration(days: 14)),
  );

  /// List [listId] when [uid] owns it and it isn't deleted; otherwise the
  /// error the server answers with, as (status, error).
  (_FakeList?, int, ApiError?) _owned(String listId, String uid) {
    final l = _visible(listId, uid);
    if (l == null) return (null, 404, _error(ApiErrorCode.listNotFound));
    if (l.ownerUid != uid) return (null, 403, _error(ApiErrorCode.notListOwner));
    if (l.deletedAt != null) return (null, 409, _error(ApiErrorCode.listDeleted));
    return (l, 200, null);
  }

  @override
  Future<CreateInvitationResult> createInvitation({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
    required InvitationCreate body,
  }) async {
    _failIfOffline('/api/lists/$listId/invitations');
    final identity = auth.current;
    if (identity == null) return const CreateInvitation401(_unauthenticated);
    final (list, status, error) = _owned(listId, identity.uid);
    switch (status) {
      case 404:
        return CreateInvitation404(error!);
      case 403:
        return CreateInvitation403(error!);
      case 409:
        return CreateInvitation409(error!);
    }
    final email = body.email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return CreateInvitation400(_error(ApiErrorCode.invalidEmail));
    }
    final dayAgo = DateTime.now().toUtc().subtract(const Duration(days: 1));
    final sentToday = _invitations.where((i) => i.invitedByUid == identity.uid && i.createdAt.isAfter(dayAgo));
    if (sentToday.length >= invitationLimit) {
      return CreateInvitation409(_error(ApiErrorCode.limitExceeded, limit: invitationLimit));
    }
    final invitation = _invite(list!, email: email, byUid: identity.uid);
    sentInvitationEmails.add((to: email, language: body.language));
    return CreateInvitation201(_toInvitation(invitation));
  }

  @override
  Future<ListListInvitationsResult> listListInvitations({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
  }) async {
    _failIfOffline('/api/lists/$listId/invitations');
    final identity = auth.current;
    if (identity == null) return const ListListInvitations401(_unauthenticated);
    final (_, status, error) = _owned(listId, identity.uid);
    switch (status) {
      case 404:
        return ListListInvitations404(error!);
      case 403:
        return ListListInvitations403(error!);
      case 409:
        return ListListInvitations409(error!);
    }
    return ListListInvitations200(
      Invitations(
        invitations: [
          for (final i in _invitations.reversed)
            if (i.listId == listId && i.status == InvitationStatus.pending) _toInvitation(i),
        ],
      ),
    );
  }

  @override
  Future<CancelInvitationResult> cancelInvitation({
    Map<String, Object?> extra = const {},
    CancelToken? cancelToken,
    Options? options,
    required String listId,
    required String invitationId,
  }) async {
    _failIfOffline('/api/lists/$listId/invitations/$invitationId');
    final identity = auth.current;
    if (identity == null) return const CancelInvitation401(_unauthenticated);
    final (_, status, error) = _owned(listId, identity.uid);
    switch (status) {
      case 404:
        return CancelInvitation404(error!);
      case 403:
        return CancelInvitation403(error!);
      case 409:
        return CancelInvitation409(error!);
    }
    final invitation = _invitations.where((i) => i.id == invitationId && i.listId == listId).firstOrNull;
    if (invitation == null) return CancelInvitation404(_error(ApiErrorCode.invitationNotFound));
    switch (invitation.status) {
      case InvitationStatus.accepted:
        return CancelInvitation409(_error(ApiErrorCode.invitationAccepted));
      case InvitationStatus.declined:
        return CancelInvitation409(_error(ApiErrorCode.invitationDeclined));
      case _:
        invitation.status = InvitationStatus.cancelled;
        return CancelInvitation200(_toInvitation(invitation));
    }
  }

  static const _unauthenticated = ApiError(code: ApiErrorCode.unauthenticated, message: 'no valid token');

  /// [json] as it arrives after a trip over the wire.
  static Map<String, Object?> _wire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

  /// A pull response as the app's client decodes it from the wire.
  static PullResponse _pullResponse({
    required List<Item> items,
    required List<HistoryEntry> history,
    required List<Tombstone> tombstones,
    required String cursor,
    required bool hasMore,
  }) => PullResponse.fromJson(
    _wire(
      PullResponse(items: items, history: history, tombstones: tombstones, cursor: cursor, hasMore: hasMore).toJson(),
    ),
  );

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

  /// The change number of its deletion behind the app's back, for pulls.
  int? deletedSeq;
  final int uncheckedItemCount;
  DateTime? deletedAt;
}

/// An Item as the fake backend stores it.
class _FakeItem {
  _FakeItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.addedByUid,
    required this.addedAt,
    required this.seq,
    this.quantity,
    this.unit,
    this.note,
    this.checkedByUid,
    this.checkedAt,
  });

  final String id;
  final String listId;
  String name;
  String? quantity;
  String? unit;
  String? note;
  final String addedByUid;
  final DateTime addedAt;
  String? checkedByUid;
  DateTime? checkedAt;
  bool deleted = false;

  /// Removed by Clear checked, so it is in its List's Item history.
  bool cleared = false;

  /// The server's change sequence when this Item last changed: the pull cursor.
  int seq;
}

/// An Invitation as the fake backend stores it.
class _FakeInvitation {
  _FakeInvitation({
    required this.id,
    required this.listId,
    required this.email,
    required this.invitedByUid,
    required this.createdAt,
  });

  final String id;
  final String listId;
  final String email;
  final String invitedByUid;
  final DateTime createdAt;
  InvitationStatus status = InvitationStatus.pending;
}

/// An Item history entry as the fake backend stores it.
class _FakeHistoryEntry {
  _FakeHistoryEntry(this.entry, {required this.seq});

  final HistoryEntry entry;

  /// The server's change sequence when it was recorded: the pull cursor.
  final int seq;
}

/// The OS's connectivity report, following [FakeApiClient.offline].
class _FakeNetworkStatus implements NetworkStatus {
  _FakeNetworkStatus(this._api);

  final FakeApiClient _api;

  @override
  Future<bool> isConnected() async => !_api.offline;

  @override
  Stream<bool> get changes => _api._connectivity.stream;
}
