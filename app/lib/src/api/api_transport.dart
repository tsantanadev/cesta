import 'dart:math';

import 'package:dio/dio.dart';

/// Builds the Dio transport the generated client runs on: base URL, timeouts
/// and W3C trace context on every request.
///
/// Usage: `CestaApi(createApiTransport(baseUrl: ...)).api`.
Dio createApiTransport({required String baseUrl}) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ),
)..interceptors.add(TraceContextInterceptor());

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
