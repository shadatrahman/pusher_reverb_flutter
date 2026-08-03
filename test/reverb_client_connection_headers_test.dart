@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

/// End-to-end coverage for the handshake headers on native platforms.
///
/// Unlike the other client tests, these do NOT pass a `channelFactory` — that
/// parameter short-circuits the platform factory, so a test using it cannot
/// observe what `connect()` actually sends over the wire. A real local
/// `HttpServer` is used instead, so the assertions fail if `connect()` ever
/// stops handing the apiKey header to the platform factory.
void main() {
  late HttpServer server;
  late int port;
  late Completer<HttpHeaders> receivedHeaders;

  setUp(() async {
    ReverbClient.resetInstance();
    receivedHeaders = Completer<HttpHeaders>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    port = server.port;
    server.listen((request) async {
      if (!receivedHeaders.isCompleted) {
        receivedHeaders.complete(request.headers);
      }
      final socket = await WebSocketTransformer.upgrade(request);
      await socket.close();
    });
  });

  tearDown(() async {
    ReverbClient.resetInstance();
    await server.close(force: true);
  });

  test('connect() sends the apiKey as an Authorization header', () async {
    final client = ReverbClient.forTesting(
      host: '127.0.0.1',
      port: port,
      appKey: 'test-app',
      apiKey: 'my-api-key',
      onError: (_) {},
    );

    await client.connect();
    final headers = await receivedHeaders.future.timeout(
      const Duration(seconds: 5),
    );

    expect(headers.value('authorization'), 'Bearer my-api-key');
    client.disconnect();
  });

  test('connect() sends no Authorization header without an apiKey', () async {
    final client = ReverbClient.forTesting(
      host: '127.0.0.1',
      port: port,
      appKey: 'test-app',
      onError: (_) {},
    );

    await client.connect();
    final headers = await receivedHeaders.future.timeout(
      const Duration(seconds: 5),
    );

    expect(headers.value('authorization'), isNull);
    client.disconnect();
  });
}
