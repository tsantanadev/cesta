import 'dart:convert';
import 'dart:typed_data';

import 'package:cesta/src/api/api_transport.dart';
import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records outgoing requests and answers every one with a healthy response.
class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'status': 'ok', 'database': 'up'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final traceparent = RegExp(r'^00-[0-9a-f]{32}-[0-9a-f]{16}-01$');

  late _RecordingAdapter adapter;
  late ApiClient api;

  setUp(() {
    adapter = _RecordingAdapter();
    final dio = createApiTransport(baseUrl: 'http://api.test')..httpClientAdapter = adapter;
    api = CestaApi(dio).api;
  });

  test('API calls carry W3C trace context', () async {
    await api.getHealth();

    final request = adapter.requests.single;
    expect(request.uri.toString(), 'http://api.test/health');
    expect(request.headers['traceparent'], matches(traceparent));
  });

  test('each API call starts its own trace', () async {
    await api.getHealth();
    await api.getHealth();

    final [first, second] = [for (final r in adapter.requests) r.headers['traceparent'] as String];
    expect(first.split('-')[1], isNot(second.split('-')[1]));
  });
}
