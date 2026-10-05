import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/services/realtime_service.dart';

/// Answers every request through [handle] after a short delay (so callers
/// overlap the way real network calls do), recording each request it saw.
/// [handle] returns `(status, body)`; throwing a [DioException] from it
/// simulates a transport failure.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handle);

  final (int, Object) Function(RequestOptions options) handle;
  final requests = <RequestOptions>[];

  List<String> get calls =>
      [for (final r in requests) '${r.method} ${r.path}'];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final (status, body) = handle(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio scriptedDio(ScriptedAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;

class CountingRealtime extends Fake implements RealtimeService {
  int connects = 0;
  int disconnects = 0;

  @override
  Future<void> connect() async => connects++;

  @override
  Future<void> disconnect() async => disconnects++;
}
