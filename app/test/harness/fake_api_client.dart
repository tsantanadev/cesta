import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:dio/dio.dart';

/// Seam 2 fake: stands in for the generated [ApiClient].
///
/// It answers from in-memory state and can be switched [offline], in which
/// case every call fails the way Dio does when the network is unreachable.
class FakeApiClient implements ApiClient {
  FakeApiClient({this.health = const Health(status: HealthStatus.ok, database: HealthDatabase.up)});

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
