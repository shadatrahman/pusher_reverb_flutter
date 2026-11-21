import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream stream) async {}
  @override
  Future close([int? closeCode, String? closeReason]) async {}
  @override
  Future get done async {}
}

class _FakeChannel extends StreamChannelMixin implements WebSocketChannel {
  final StreamController<dynamic> controller = StreamController<dynamic>();
  @override
  Stream get stream => controller.stream;
  @override
  WebSocketSink get sink => _FakeSink();
  @override
  Future<void> get ready async {}
  @override
  int? get closeCode => null;
  @override
  String? get closeReason => null;
  @override
  String? get protocol => null;
}

void main() {
  group('Reconnect lifecycle', () {
    late List<_FakeChannel> channels;

    ReverbClient createClient() => ReverbClient.forTesting(
      host: 'localhost',
      port: 8080,
      appKey: 'test-key',
      channelFactory: (_) {
        final c = _FakeChannel();
        channels.add(c);
        return c;
      },
    );

    setUp(() => channels = []);
    tearDown(ReverbClient.resetInstance);

    test(
      'pending reconnect does not emit or reconnect after resetInstance()',
      () async {
        final errors = <Object>[];
        final done = Completer<void>();
        runZonedGuarded(() async {
          final client = ReverbClient.instance(
            host: 'localhost',
            port: 8080,
            appKey: 'test-key',
            channelFactory: (_) {
              final c = _FakeChannel();
              channels.add(c);
              return c;
            },
          );
          await client.connect();
          expect(channels, hasLength(1));

          // Connection lost -> automatic reconnect starts (2s backoff).
          await channels.first.controller.close();
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Reset while the reconnect delay is pending.
          ReverbClient.resetInstance();

          await Future<void>.delayed(const Duration(milliseconds: 2500));
          done.complete();
        }, (e, _) {
          errors.add(e);
          if (!done.isCompleted) done.complete();
        });
        await done.future;

        expect(errors, isEmpty);
        expect(channels, hasLength(1), reason: 'no new connection attempt');
      },
    );

    test('manual disconnect during backoff stops the reconnect', () async {
      final client = createClient();
      await client.connect();
      await channels.first.controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      expect(channels, hasLength(1));
      expect(client.connectionState, ConnectionState.disconnected);
    });

    test('active client still reconnects after connection loss', () async {
      final client = createClient();
      await client.connect();
      await channels.first.controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      expect(channels, hasLength(2));
      client.disconnect();
    });
  });
}
