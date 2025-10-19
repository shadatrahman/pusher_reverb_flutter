import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ReverbClient API Key and Cluster Tests', () {
    setUp(() {
      ReverbClient.resetInstance();
    });

    tearDown(() {
      ReverbClient.resetInstance();
    });

    group('API Key Support', () {
      test('should store API key when provided', () {
        const apiKey = 'test-api-key';

        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', apiKey: apiKey);

        expect(client.apiKey, equals(apiKey));
      });

      test('should work without API key (backward compatibility)', () {
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          // No API key provided
        );

        expect(client.apiKey, isNull);
      });

      test('should throw exception for empty API key', () {
        expect(
          () => ReverbClient.forTesting(
            host: 'localhost',
            port: 8080,
            appKey: 'test-app-key',
            apiKey: '', // Empty API key
          ),
          throwsA(isA<ConnectionException>()),
        );
      });
    });

    group('Cluster Support', () {
      test('should resolve us-east-1 cluster configuration', () {
        final client = ReverbClient.forTesting(
          host: 'localhost', // This should be overridden
          port: 8080, // This should be overridden
          appKey: 'test-app-key',
          cluster: 'us-east-1',
          useTLS: false, // This should be overridden
        );

        expect(client.effectiveHost, equals('reverb-us-east-1.pusher.com'));
        expect(client.effectivePort, equals(443));
        expect(client.effectiveUseTLS, equals(true));
        expect(client.isUsingCluster, equals(true));
      });

      test('should resolve eu-west-1 cluster configuration', () {
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', cluster: 'eu-west-1');

        expect(client.effectiveHost, equals('reverb-eu-west-1.pusher.com'));
        expect(client.effectivePort, equals(443));
        expect(client.effectiveUseTLS, equals(true));
      });

      test('should resolve local cluster configuration', () {
        final client = ReverbClient.forTesting(host: 'remote-host', port: 9000, appKey: 'test-app-key', cluster: 'local');

        expect(client.effectiveHost, equals('localhost'));
        expect(client.effectivePort, equals(8080));
        expect(client.effectiveUseTLS, equals(false));
      });

      test('should throw exception for invalid cluster', () {
        expect(() => ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', cluster: 'invalid-cluster'), throwsA(isA<ConnectionException>()));
      });

      test('should return available clusters', () {
        final clusters = ReverbClient.availableClusters;
        expect(clusters, contains('us-east-1'));
        expect(clusters, contains('eu-west-1'));
        expect(clusters, contains('local'));
        expect(clusters, isNotEmpty);
      });

      test('should get cluster configuration', () {
        final config = ReverbClient.getClusterConfig('us-east-1');
        expect(config, isNotNull);
        expect(config!.host, equals('reverb-us-east-1.pusher.com'));
        expect(config.port, equals(443));
        expect(config.useTLS, equals(true));
      });
    });

    group('Parameter Priority', () {
      test('should use cluster configuration when cluster is specified', () {
        final client = ReverbClient.forTesting(
          host: 'custom-host.com',
          port: 9000,
          appKey: 'test-app-key',
          cluster: 'us-east-1', // Should override explicit parameters
          useTLS: false, // Should be overridden
        );

        // Note: In the current implementation, cluster settings override explicit parameters
        // This test documents the current behavior
        expect(client.effectiveHost, equals('reverb-us-east-1.pusher.com'));
        expect(client.effectivePort, equals(443));
        expect(client.effectiveUseTLS, equals(true));
      });
    });

    group('Backward Compatibility', () {
      test('should work with existing parameters only', () {
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app-key',
          // No new parameters
        );

        expect(client.effectiveHost, equals('localhost'));
        expect(client.effectivePort, equals(8080));
        expect(client.effectiveUseTLS, equals(false));
        expect(client.isUsingCluster, equals(false));
      });

      test('should work with singleton pattern', () {
        final client1 = ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'test-app-key', apiKey: 'test-api-key', cluster: 'us-east-1');

        final client2 = ReverbClient.instance();

        expect(identical(client1, client2), equals(true));
        expect(client2.effectiveHost, equals('reverb-us-east-1.pusher.com'));
      });
    });

    group('Configuration Access', () {
      test('should provide access to resolved configuration', () {
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', cluster: 'us-east-1');

        final resolvedConfig = client.resolvedConfig;
        expect(resolvedConfig.host, equals('reverb-us-east-1.pusher.com'));
        expect(resolvedConfig.port, equals(443));
        expect(resolvedConfig.useTLS, equals(true));
      });
    });

    group('Edge Cases', () {
      test('should handle null API key gracefully', () {
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', apiKey: null);

        expect(client.apiKey, isNull);
      });

      test('should handle empty cluster gracefully', () {
        expect(
          () => ReverbClient.forTesting(
            host: 'localhost',
            port: 8080,
            appKey: 'test-app-key',
            cluster: '', // Empty cluster should throw exception
          ),
          throwsA(isA<ConnectionException>()),
        );
      });

      test('should handle special characters in API key', () {
        const apiKey = 'test-api-key-with-special-chars!@#\$%^&*()';

        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', apiKey: apiKey);

        expect(client.apiKey, equals(apiKey));
      });

      test('should handle very long API key', () {
        final apiKey = 'a' * 1000; // Very long API key

        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-app-key', apiKey: apiKey);

        expect(client.apiKey, equals(apiKey));
      });
    });
  });
}
