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
