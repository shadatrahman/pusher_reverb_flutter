import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ReverbClient Private Channel Integration', () {
    late ReverbClient client;
    late Authorizer mockAuthorizer;

    setUp(() {
      mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token'};
      };

      client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer, authEndpoint: 'https://example.com/auth');
    });

    group('subscribeToPrivateChannel', () {
      test('should throw error if authorizer is not configured', () {
        final clientWithoutAuthorizer = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authEndpoint: 'https://example.com/auth');

        expect(
          () => clientWithoutAuthorizer.subscribeToPrivateChannel('private-test-channel'),
          throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Authorizer function is required'))),
        );
      });

      test('should throw error if authEndpoint is not configured', () {
        final clientWithoutEndpoint = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer);

        expect(
          () => clientWithoutEndpoint.subscribeToPrivateChannel('private-test-channel'),
          throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Authentication endpoint is required'))),
        );
      });

      test('should throw error if socketId is not available', () {
        expect(() => client.subscribeToPrivateChannel('private-test-channel'), throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Socket ID is not available'))));
      });

      test('should throw error for invalid private channel name', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        expect(() => client.subscribeToPrivateChannel('public-channel'), throwsA(isA<ArgumentError>()));
      });
    });

    group('mixed channel types', () {
      test('should handle both public and private channels', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Subscribe to public channel
        final publicChannel = client.subscribeToChannel('public-channel');
        expect(publicChannel, isA<Channel>());
        expect(publicChannel, isNot(isA<PrivateChannel>()));

        // Subscribe to private channel
        final privateChannel = client.subscribeToPrivateChannel('private-channel');
        expect(privateChannel, isA<PrivateChannel>());

        // Both should be in subscribed channels
        expect(client.subscribedChannels.length, 2);
        expect(client.subscribedChannels, contains(publicChannel));
        expect(client.subscribedChannels, contains(privateChannel));
      });

      test('should handle unsubscription for both channel types', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Subscribe to both types
        client.subscribeToChannel('public-channel');
        client.subscribeToPrivateChannel('private-channel');

        expect(client.subscribedChannels.length, 2);

        // Unsubscribe from both
        client.unsubscribeFromChannel('public-channel');
        client.unsubscribeFromChannel('private-channel');

        expect(client.subscribedChannels.length, 0);
      });
    });

    group('channel management', () {
      test('should return correct channel type from getChannel', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create channels
        final publicChannel = client.subscribeToChannel('public-channel');
        final privateChannel = client.subscribeToPrivateChannel('private-channel');

        // Test getChannel returns correct types
        expect(client.getChannel('public-channel'), publicChannel);
        expect(client.getChannel('private-channel'), privateChannel);
        expect(client.getChannel('nonexistent'), isNull);
      });

      test('should return existing private channel on duplicate subscription', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final firstChannel = client.subscribeToPrivateChannel('private-test-channel');
        final secondChannel = client.subscribeToPrivateChannel('private-test-channel');

        expect(firstChannel, same(secondChannel));
        expect(client.subscribedChannels.length, 1);
      });

      test('should throw error if trying to convert public to private channel', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // First subscribe to public channel
        client.subscribeToChannel('private-test-channel');

        // Then try to subscribe to private channel with same name
        expect(() => client.subscribeToPrivateChannel('private-test-channel'), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('already exists as a public channel'))));
      });
    });
  });
}
