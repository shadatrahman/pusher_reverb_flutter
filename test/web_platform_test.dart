@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

/// Regression test for issue #10.
///
/// Before web support, `connect()` reached `IOWebSocketChannel.connect()`,
/// which pulls in `dart:io` and fails on web with
/// "Unsupported operation: Platform._version". Run with:
///
///     flutter test --platform chrome test/web_platform_test.dart
void main() {
  setUp(ReverbClient.resetInstance);
  tearDown(ReverbClient.resetInstance);

  test('connect() does not hit dart:io on web', () async {
    Object? reported;
    final client = ReverbClient.forTesting(
      host: 'localhost',
      port: 8080,
      appKey: 'test-app',
      onError: (error) => reported ??= error,
    );

    try {
      await client.connect();
    } catch (error) {
      reported ??= error;
    }

    expect(reported?.toString() ?? '', isNot(contains('Platform._version')));
    client.disconnect();
  });

  test('connect() with apiKey and pingInterval does not hit dart:io', () async {
    Object? reported;
    final client = ReverbClient.forTesting(
      host: 'localhost',
      port: 8080,
      appKey: 'test-app',
      apiKey: 'my-api-key',
      pingInterval: const Duration(seconds: 15),
      onError: (error) => reported ??= error,
    );

    try {
      await client.connect();
    } catch (error) {
      reported ??= error;
    }

    expect(reported?.toString() ?? '', isNot(contains('Platform._version')));
    client.disconnect();
  });
}
