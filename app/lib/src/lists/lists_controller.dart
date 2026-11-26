import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';
import '../session/session_controller.dart';

/// The longest List name the server accepts, in characters.
const maxListNameLength = 60;

/// Result of a change to a List (create, rename, delete, restore).
enum ListOutcome {
  done,

  /// The server rejected the name.
  invalidName,

  /// The User already owns 100 Lists.
  limitReached,

  /// The List is gone, or the User is no longer a Member.
  notFound,

  /// The List was deleted more than 30 days ago.
  expired,
  rateLimited,
  offline,
  failed,
}

/// The signed-in User's Lists: what the Lists screen shows, and the changes
/// the User makes to them.
///
/// Lists come from the API and are cached on the device, so the Lists screen
/// still shows them offline. Changes need the network.
class ListsController extends ChangeNotifier {
  ListsController({required this._api, required this._db, required this._session}) {
    _session.addListener(_onSessionChanged);
  }

  final ApiClient _api;
  final AppDatabase _db;
  final SessionController _session;
  final _random = Random.secure();

  /// The Lists the User is a Member of, newest first.
  List<ListSummary> get lists => _lists;
  List<ListSummary> _lists = const [];

  /// False until the cache or the server has answered once.
  bool get loaded => _loaded;
  bool _loaded = false;

  void _onSessionChanged() {
    if (_session.status == SessionStatus.signedOut && (_lists.isNotEmpty || _loaded)) {
      _lists = const [];
      _loaded = false;
      notifyListeners();
    }
  }

  /// Shows the cached Lists, then reloads them from the server.
  Future<void> refresh() async {
    if (!_loaded) {
      _show(await _db.readKnownLists());
    }
    try {
      if (await _api.listLists() case ListLists200(:final value)) {
        await _db.saveKnownLists(value.lists);
        _show(value.lists);
      }
    } on DioException {
      // Offline or unreachable: keep the cached Lists.
    }
  }

  /// Creates a List named [name], owned by the User.
  Future<ListOutcome> create(String name) => _attempt(() async {
    final body = ListCreate(id: _newListId(), name: ListName(name.trim()));
    return switch (await _api.createList(body: body)) {
      CreateList201(:final value) || CreateList200(:final value) => _keep(value),
      CreateList400() => ListOutcome.invalidName,
      CreateList409(:final value) => _conflict(value),
      CreateList429() => ListOutcome.rateLimited,
      CreateList401() => ListOutcome.failed,
    };
  });

  Future<ListOutcome> rename(ListSummary list, String name) => _attempt(() async {
    final result = await _api.renameList(
      listId: list.id,
      body: ListRename(name: ListName(name.trim())),
    );
    return switch (result) {
      RenameList200(:final value) => _keep(value),
      RenameList400() => ListOutcome.invalidName,
      RenameList404() || RenameList409() => _gone(list.id),
      RenameList429() => ListOutcome.rateLimited,
      RenameList401() || RenameList403() => ListOutcome.failed,
    };
  });

  Future<ListOutcome> delete(ListSummary list) => _attempt(() async {
    return switch (await _api.deleteList(listId: list.id)) {
      DeleteList200() => _gone(list.id).then((_) => ListOutcome.done),
      DeleteList404() => _gone(list.id),
      DeleteList429() => ListOutcome.rateLimited,
      DeleteList400() || DeleteList401() || DeleteList403() => ListOutcome.failed,
    };
  });

  /// Brings back the deleted List [id].
  Future<ListOutcome> restore(String id) => _attempt(() async {
    return switch (await _api.restoreList(listId: id)) {
      RestoreList200(:final value) => _keep(value),
      RestoreList404() => ListOutcome.expired,
      RestoreList409(:final value) => _conflict(value),
      RestoreList429() => ListOutcome.rateLimited,
      RestoreList400() || RestoreList401() || RestoreList403() => ListOutcome.failed,
    };
  });

  /// The Lists the User deleted and can still restore, newest deletion first.
  /// Null when they couldn't be loaded; [outcome] says why.
  Future<(List<DeletedList>?, ListOutcome)> recentlyDeleted() async {
    try {
      return switch (await _api.listDeletedLists()) {
        ListDeletedLists200(:final value) => (value.lists, ListOutcome.done),
        ListDeletedLists429() => (null, ListOutcome.rateLimited),
        ListDeletedLists401() => (null, ListOutcome.failed),
      };
    } on DioException catch (e) {
      return (null, _isOffline(e) ? ListOutcome.offline : ListOutcome.failed);
    }
  }

  Future<ListOutcome> _attempt(Future<ListOutcome> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return _isOffline(e) ? ListOutcome.offline : ListOutcome.failed;
    }
  }

  Future<ListOutcome> _keep(ListSummary list) async {
    await _db.saveKnownList(list);
    _show([list, ..._lists.where((l) => l.id != list.id)]);
    return ListOutcome.done;
  }

  Future<ListOutcome> _gone(String id) async {
    await _db.forgetKnownList(id);
    _show(_lists.where((l) => l.id != id).toList());
    return ListOutcome.notFound;
  }

  static ListOutcome _conflict(ApiError error) => switch (error.code) {
    ApiErrorCode.limitExceeded => ListOutcome.limitReached,
    _ => ListOutcome.failed,
  };

  void _show(List<ListSummary> lists) {
    _lists = [...lists]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  /// A random (version 4) UUID: the client picks a new List's ID.
  String _newListId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static bool _isOffline(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
