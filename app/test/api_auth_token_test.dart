import 'dart:convert';
import 'dart:typed_data';

import 'package:cesta/src/api/api_transport.dart';
import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A backend that accepts only [validToken] on /api/me.
class _FakeBackend implements HttpClientAdapter {
  String validToken = 'token-2';
  final requests = <RequestOptions>[];

  /// The Authorization header of each request as it was sent.
  final sentAuthorization = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    sentAuthorization.add(options.headers['Authorization']);
    if (options.path == '/health') return _json(200, {'status': 'ok', 'database': 'up'});
    if (options.headers['Authorization'] != 'Bearer $validToken') {
      return _json(401, {'code': 'unauthenticated', 'message': 'nope'});
    }
    return _json(200, {'id': 'u1', 'email': 'ana@example.com', 'displayName': 'Ana', 'displayNameConfirmed': true});
  }

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Hands out token-1, then token-2 after each forced refresh.
class _Tokens {
  bool signedIn = true;
  int issued = 1;
  int forcedRefreshes = 0;

  Future<String?> idToken({bool forceRefresh = false}) async {
    if (!signedIn) return null;
    if (forceRefresh) {
      forcedRefreshes++;
      issued++;
    }
    return 'token-$issued';
  }
}

void main() {
  late _FakeBackend backend;
  late _Tokens tokens;
  late ApiClient api;

  setUp(() {
    backend = _FakeBackend();
    tokens = _Tokens();
    final dio = createApiTransport(baseUrl: 'http://api.test', idToken: tokens.idToken)..httpClientAdapter = backend;
    api = CestaApi(dio).api;
  });

  test('calls that need sign-in carry the ID token', () async {
    backend.validToken = 'token-1';

    final result = await api.getMe();

    expect(result, isA<GetMe200>());
    expect(backend.requests.single.headers['Authorization'], 'Bearer token-1');
  });

  test('public calls carry no token', () async {
    await api.getHealth();

    expect(backend.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('a rejected token is refreshed once and the call retried', () async {
    final result = await api.getMe();

    expect(result, isA<GetMe200>());
    expect(tokens.forcedRefreshes, 1);
    expect(backend.sentAuthorization, ['Bearer token-1', 'Bearer token-2']);
  });

  test('a token still rejected after refreshing is reported, not retried forever', () async {
    backend.validToken = 'never';

    final result = await api.getMe();

    expect(result, isA<GetMe401>());
    expect(backend.requests, hasLength(2));
  });

  test('signed out, calls go without a token', () async {
    tokens.signedIn = false;

    final result = await api.getMe();

    expect(result, isA<GetMe401>());
    expect(backend.requests.single.headers.containsKey('Authorization'), isFalse);
  });
}
