import 'dart:math';

import 'package:dio/dio.dart';

import '../auth/auth_gateway.dart';

/// Builds the Dio transport the generated client runs on: base URL, timeouts,
/// W3C trace context on every request and, given [auth], the signed-in User's
/// ID token on every call the API contract marks as needing it.
///
/// Usage: `CestaApi(createApiTransport(baseUrl: ..., auth: ...)).api`.
Dio createApiTransport({required String baseUrl, AuthGateway? auth}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(TraceContextInterceptor());
  if (auth != null) dio.interceptors.add(IdTokenInterceptor(auth, dio));
  return dio;
}

/// Sends the Firebase ID token as a bearer token on calls whose contract
/// security is non-empty. When the server rejects a token with 401 (say it
/// expired while the phone slept), it refreshes the token once and retries.
class IdTokenInterceptor extends Interceptor {
  IdTokenInterceptor(this._auth, this._dio);

  final AuthGateway _auth;
  final Dio _dio;

  static const _retriedKey = 'cesta.idTokenRetried';

  static bool _needsToken(RequestOptions options) => switch (options.extra['openapi.security']) {
    final List<Object?> security => security.isNotEmpty,
    _ => false,
  };

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_needsToken(options)) {
      final token = await _auth.idToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final options = response.requestOptions;
    final sentToken = options.headers.containsKey('Authorization');
    if (response.statusCode != 401 || !sentToken || options.extra[_retriedKey] == true) {
      handler.next(response);
      return;
    }
    try {
      final token = await _auth.idToken(forceRefresh: true);
      if (token == null) {
        handler.next(response);
        return;
      }
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.reject(e);
    } catch (_) {
      // Couldn't refresh (e.g. offline): report the original 401.
      handler.next(response);
    }
  }
}

/// Adds a W3C `traceparent` header (https://www.w3.org/TR/trace-context/)
/// to every request, so backend spans join the app's trace. Each request
/// starts a new sampled trace; the app has no tracer of its own yet.
class TraceContextInterceptor extends Interceptor {
  TraceContextInterceptor({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['traceparent'] = '00-${_hex(16)}-${_hex(8)}-01';
    handler.next(options);
  }

  /// Random lowercase hex of [bytes] bytes, never all zeros (invalid per spec).
  String _hex(int bytes) {
    while (true) {
      final values = List<int>.generate(bytes, (_) => _random.nextInt(256));
      if (values.any((b) => b != 0)) {
        return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      }
    }
  }
}
