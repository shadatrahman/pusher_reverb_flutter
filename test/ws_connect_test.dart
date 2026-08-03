@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/src/client/ws_connect_io.dart' as io;
import 'package:pusher_reverb_flutter/src/client/ws_connect_web.dart' as web;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late HttpServer server;
  late Uri uri;
  late Completer<HttpHeaders> receivedHeaders;

  setUp(() async {
    receivedHeaders = Completer<HttpHeaders>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    uri = Uri.parse('ws://127.0.0.1:${server.port}/app/test-app');
    server.listen((request) async {
      if (!receivedHeaders.isCompleted) {
        receivedHeaders.complete(request.headers);
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await socket.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  Future<void> drainAndClose(WebSocketChannel channel) async {
    await channel.ready.catchError((_) {});
    await channel.sink.close();
  }

  group('createWebSocketChannel (native)', () {
    test('sends the Authorization header during the handshake', () async {
      final channel = io.createWebSocketChannel(
        uri,
        headers: const {'Authorization': 'Bearer my-api-key'},
      );
      expect(channel, isA<IOWebSocketChannel>());

      final headers = await receivedHeaders.future.timeout(
        const Duration(seconds: 5),
      );
      expect(headers.value('authorization'), 'Bearer my-api-key');

      await drainAndClose(channel);
    });

    test('sends no Authorization header when headers are null', () async {
      final channel = io.createWebSocketChannel(uri, headers: null);

      final headers = await receivedHeaders.future.timeout(
        const Duration(seconds: 5),
      );
      expect(headers.value('authorization'), isNull);

      await drainAndClose(channel);
    });

    test('accepts a pingInterval without throwing', () async {
      final channel = io.createWebSocketChannel(
        uri,
        pingInterval: const Duration(seconds: 15),
      );
      expect(channel, isA<IOWebSocketChannel>());

      await receivedHeaders.future.timeout(const Duration(seconds: 5));
      await drainAndClose(channel);
    });
  });

  // The web implementation is exercised here on the VM: it imports nothing
  // platform-specific, so the header/pingInterval fallback can be asserted
  // without a browser. The dart:io runtime regression itself is covered by
  // web_platform_test.dart, which runs under `--platform chrome`.
  group('createWebSocketChannel (web)', () {
    final logs = <String>[];
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      logs.clear();
      web.debugResetWebConnectWarnings();
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    test('drops headers and warns exactly once', () async {
      final first = web.createWebSocketChannel(
        uri,
        headers: const {'Authorization': 'Bearer my-api-key'},
      );

      final headers = await receivedHeaders.future.timeout(
        const Duration(seconds: 5),
      );
      expect(
        headers.value('authorization'),
        isNull,
        reason: 'browser WebSocket API cannot send handshake headers',
      );

      final second = web.createWebSocketChannel(
        uri,
        pingInterval: const Duration(seconds: 15),
      );

      expect(logs, hasLength(1));
      expect(logs.single, contains('running on web'));
      expect(logs.single, contains('connection headers'));

      await drainAndClose(first);
      await drainAndClose(second);
    });

    test('does not warn when there is nothing to drop', () async {
      final channel = web.createWebSocketChannel(uri);

      await receivedHeaders.future.timeout(const Duration(seconds: 5));
      expect(logs, isEmpty);

      await drainAndClose(channel);
    });
  });
}
