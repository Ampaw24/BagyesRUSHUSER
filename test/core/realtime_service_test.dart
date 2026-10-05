import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/services/realtime_config.dart';
import 'package:bagyesrushappusernew/core/services/realtime_repository.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';

/// Holds each `getConfig()` open until [release] — the window in which a
/// logout can race a connect.
class _GatedRepository extends Fake implements RealtimeRepository {
  final _pending = <Completer<RealtimeConfig>>[];

  int get calls => _pending.length;

  @override
  Future<RealtimeConfig> getConfig() {
    final gate = Completer<RealtimeConfig>();
    _pending.add(gate);
    return gate.future;
  }

  void release() => _pending.last.complete(const RealtimeConfig(
        driver: 'reverb',
        key: 'key',
        host: 'localhost',
        port: 1,
        useTls: false,
        authEndpoint: '/broadcasting/auth',
        channelTemplates: {},
      ));
}

void main() {
  test('a disconnect during connect leaves no socket behind', () async {
    final repository = _GatedRepository();
    final service = RealtimeService(repository: repository, authDio: Dio());

    final connecting = service.connect();
    await service.disconnect();
    repository.release();
    await connecting;

    expect(service.orderChannelName('1'), isNull,
        reason: 'the abandoned attempt must not adopt its config');
  });

  test('a connect abandoned by logout does not block the next one', () async {
    final repository = _GatedRepository();
    final service = RealtimeService(repository: repository, authDio: Dio());

    final first = service.connect();
    await service.disconnect();
    repository.release();
    await first;

    final second = service.connect();
    expect(repository.calls, 2);

    await service.disconnect();
    repository.release();
    await second;
  });
}
