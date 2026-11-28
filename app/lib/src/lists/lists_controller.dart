import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../api/generated/cesta_api.dart';
import '../api/network.dart';
import '../db/app_database.dart';
import '../session/session_controller.dart';

/// The longest List name the server accepts, in characters.
const maxListNameLength = 60;

/// How long after deletion the Owner can still restore a List (the Restore window).
const restoreWindow = Duration(days: 30);

/// Why a change to a List (create, rename, delete, restore) or a load didn't
/// go through. Operations return null when they did.
sealed class ListFailure {
  const ListFailure();

  /// The server rejected the name.
  static const invalidName = ListInvalidName();

  /// The List is gone for good, or the User is no longer a Member.
  static const notFound = ListNotFound();

  /// The List was deleted (and can still be restored from Recently deleted).
  static const deleted = ListDeleted();

  /// Restoring found the List gone; the app can't tell why.
  static const notRestorable = ListNotRestorable();

  static const rateLimited = ListRateLimited();
  static const offline = ListOffline();
  static const failed = ListFailed();
}

final class ListInvalidName extends ListFailure {
  const ListInvalidName();
}

/// The User already owns the configured maximum number of live Lists.
final class ListLimitReached extends ListFailure {
  const ListLimitReached(this.limit);

  /// The maximum reported by the server, if provided.
  final int? limit;
}

final class ListNotFound extends ListFailure {
  const ListNotFound();
}

final class ListDeleted extends ListFailure {
  const ListDeleted();
}

final class ListNotRestorable extends ListFailure {
  const ListNotRestorable();
}

final class ListRateLimited extends ListFailure {
  const ListRateLimited();
}

final class ListOffline extends ListFailure {
  const ListOffline();
}

final class ListFailed extends ListFailure {
  const ListFailed();
}

/// The signed-in User's Lists: what the Lists screen shows, and the changes
/// the User makes to them.
///
/// Lists come from the API and are cached on the device, so the Lists screen
/// still shows them offline. What changes about them on the device (a List
/// deleted elsewhere, a new count of Items to buy, even offline) shows at once,
/// through [changed]. Changes to Lists themselves still need the network
/// (ADR-0001).
class ListsController extends ChangeNotifier {
  ListsController({required this._api, required this._db, required this._session}) {
    _session.addListener(_onSessionChanged);
  }

  final ApiClient _api;
  final AppDatabase _db;
  final SessionController _session;

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

  /// Shows the cached Lists, then reloads them from the server. On failure
  /// the cached Lists stay, and the result says why.
  Future<ListFailure?> refresh() async {
    if (!_loaded) {
      _show(await _db.readKnownLists());
    }
    return _attempt(() async {
      switch (await _api.listLists()) {
        case ListLists200(:final value):
          await _db.saveKnownLists(value.lists);
          _show(value.lists);
          return null;
        case ListLists429():
          return ListFailure.rateLimited;
        case ListLists401():
          return ListFailure.failed;
      }
    });
  }

  /// A new List's ID, which the client picks. Reuse it when retrying the same
  /// create, so the server makes the List once however often it's sent.
  static String newListId() => const Uuid().v4();

  /// Creates a List named [name] with ID [id] (from [newListId]), owned by the User.
  Future<ListFailure?> create(String id, String name) => _attempt(() async {
    final body = ListCreate(id: id, name: ListName(name.trim()));
    return switch (await _api.createList(body: body)) {
      CreateList201(:final value) || CreateList200(:final value) => _keep(value),
      CreateList400() => ListFailure.invalidName,
      CreateList409(:final value) => _conflict(value),
      CreateList429() => ListFailure.rateLimited,
      CreateList401() => ListFailure.failed,
    };
  });

  Future<ListFailure?> rename(ListSummary list, String name) => _attempt(() async {
    final result = await _api.renameList(
      listId: list.id,
      body: ListRename(name: ListName(name.trim())),
    );
    return switch (result) {
      RenameList200(:final value) => _keep(value),
      RenameList400() => ListFailure.invalidName,
      RenameList404() => _gone(list.id, ListFailure.notFound),
      RenameList409() => _gone(list.id, ListFailure.deleted),
      RenameList429() => ListFailure.rateLimited,
      RenameList401() || RenameList403() => ListFailure.failed,
    };
  });

  Future<ListFailure?> delete(ListSummary list) => _attempt(() async {
    return switch (await _api.deleteList(listId: list.id)) {
      DeleteList200() => _gone(list.id, null),
      DeleteList404() => _gone(list.id, ListFailure.notFound),
      DeleteList429() => ListFailure.rateLimited,
      DeleteList400() || DeleteList401() || DeleteList403() => ListFailure.failed,
    };
  });

  /// Brings back the deleted List [id].
  Future<ListFailure?> restore(String id) => _attempt(() async {
    return switch (await _api.restoreList(listId: id)) {
      RestoreList200(:final value) => _keep(value),
      RestoreList404() => ListFailure.notRestorable,
      RestoreList409(:final value) => _conflict(value),
      RestoreList429() => ListFailure.rateLimited,
      RestoreList400() || RestoreList401() || RestoreList403() => ListFailure.failed,
    };
  });

  /// The User became a Member of [list] (e.g. by accepting an Invitation), so
  /// it shows on the Lists screen at once.
  Future<void> joined(ListSummary list) => _keep(list);

  /// The Lists the User deleted and can still restore, newest deletion first.
  /// Null when they couldn't be loaded, with why.
  Future<(List<DeletedList>?, ListFailure?)> recentlyDeleted() async {
    try {
      return switch (await _api.listDeletedLists()) {
        ListDeletedLists200(:final value) => (value.lists, null),
        ListDeletedLists429() => (null, ListFailure.rateLimited),
        ListDeletedLists401() => (null, ListFailure.failed),
      };
    } on DioException catch (e) {
      return (null, isOffline(e) ? ListFailure.offline : ListFailure.failed);
    }
  }

  Future<ListFailure?> _attempt(Future<ListFailure?> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      return isOffline(e) ? ListFailure.offline : ListFailure.failed;
    }
  }

  Future<ListFailure?> _keep(ListSummary list) async {
    await _db.saveKnownList(list);
    _show([list, ..._lists.where((l) => l.id != list.id)]);
    return null;
  }

  /// Takes List [id] off the Lists screen and returns [failure].
  Future<ListFailure?> _gone(String id, ListFailure? failure) async {
    await _db.forgetKnownList(id);
    _show(_lists.where((l) => l.id != id).toList());
    return failure;
  }

  static ListFailure _conflict(ApiError error) => switch (error.code) {
    ApiErrorCode.limitExceeded => ListLimitReached(error.limit),
    _ => ListFailure.failed,
  };

  /// The Lists [gone] are deleted (or the User is no longer a Member), and
  /// others have a new count of Items to buy ([toBuy], by List ID). The
  /// device's cache already says so.
  void changed({required Set<String> gone, required Map<String, int> toBuy}) {
    if (!_loaded || (gone.isEmpty && toBuy.isEmpty)) return;
    _show([
      for (final l in _lists)
        if (!gone.contains(l.id))
          switch (toBuy[l.id]) {
            final n? when n != l.uncheckedItemCount => ListSummary(
              id: l.id,
              name: l.name,
              role: l.role,
              uncheckedItemCount: n,
              memberCount: l.memberCount,
              createdAt: l.createdAt,
            ),
            _ => l,
          },
    ]);
  }

  void _show(List<ListSummary> lists) {
    _lists = [...lists]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
