import 'package:flutter_test/flutter_test.dart';

import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ReverbClient', () {
    test('creates instance with required parameters', () {
      final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key');

      expect(client.host, 'localhost');
      expect(client.port, 8080);
      expect(client.appKey, 'test-app-key');
    });
  });
}
