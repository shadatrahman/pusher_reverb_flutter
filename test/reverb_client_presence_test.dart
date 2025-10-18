import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ReverbClient Presence Channel Integration', () {
    late ReverbClient client;
    late Authorizer mockAuthorizer;
    late Map<String, dynamic> testChannelData;

    setUp(() {
      mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token'};
      };

      testChannelData = {
        'user_id': '123',
        'user_info': {'name': 'John Doe'},
      };

      client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer, authEndpoint: 'https://example.com/auth');
    });

    group('subscribeToPresenceChannel', () {
      test('should throw error if authorizer is not configured', () {
        final clientWithoutAuthorizer = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authEndpoint: 'https://example.com/auth');

        expect(
          () => clientWithoutAuthorizer.subscribeToPresenceChannel('presence-room'),
          throwsA(isA<ChannelException>().having((e) => e.message, 'message', contains('Authorizer and authEndpoint must be configured'))),
        );
      });

      test('should throw error if authEndpoint is not configured', () {
        final clientWithoutEndpoint = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer);

        expect(
          () => clientWithoutEndpoint.subscribeToPresenceChannel('presence-room'),
          throwsA(isA<ChannelException>().having((e) => e.message, 'message', contains('Authorizer and authEndpoint must be configured'))),
        );
      });

      test('should throw error if socketId is not available', () {
        expect(() => client.subscribeToPresenceChannel('presence-room'), throwsA(isA<ConnectionException>().having((e) => e.message, 'message', contains('not connected to server'))));
      });

      test('should throw error for invalid presence channel name', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        expect(() => client.subscribeToPresenceChannel('private-channel'), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should create PresenceChannel with valid name', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room');

        expect(channel, isA<PresenceChannel>());
        expect(channel.name, 'presence-room');
        expect(channel.state, ChannelState.subscribing);
      });

      test('should create PresenceChannel with channel data', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room', channelData: testChannelData);

        expect(channel, isA<PresenceChannel>());
        expect(channel.channelData, testChannelData);
      });

      test('should create PresenceChannel without channel data', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room');

        expect(channel, isA<PresenceChannel>());
        expect(channel.channelData, isNull);
      });

      test('should return existing PresenceChannel on duplicate subscription', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel1 = client.subscribeToPresenceChannel('presence-room');
        final channel2 = client.subscribeToPresenceChannel('presence-room');

        expect(identical(channel1, channel2), isTrue);
        expect(client.subscribedChannels.length, 1);
      });

      test('should throw error when trying to convert existing channel to presence', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create a public channel first
        client.subscribeToChannel('presence-room');

        // Try to subscribe to same name as presence channel
        expect(() => client.subscribeToPresenceChannel('presence-room'), throwsA(isA<ChannelException>().having((e) => e.message, 'message', contains('already exists as a different channel type'))));
      });
    });

    group('mixed channel types', () {
      test('should handle public, private, and presence channels', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Subscribe to different channel types
        final publicChannel = client.subscribeToChannel('public-channel');
        final privateChannel = client.subscribeToPrivateChannel('private-channel');
        final presenceChannel = client.subscribeToPresenceChannel('presence-room');

        expect(publicChannel, isA<Channel>());
        expect(publicChannel, isNot(isA<PrivateChannel>()));
        expect(privateChannel, isA<PrivateChannel>());
        expect(privateChannel, isNot(isA<PresenceChannel>()));
        expect(presenceChannel, isA<PresenceChannel>());

        // All should be in subscribed channels
        expect(client.subscribedChannels.length, 3);
        expect(client.subscribedChannels, contains(publicChannel));
        expect(client.subscribedChannels, contains(privateChannel));
        expect(client.subscribedChannels, contains(presenceChannel));
      });

      test('should handle unsubscription for all channel types', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Subscribe to all types
        client.subscribeToChannel('public-channel');
        client.subscribeToPrivateChannel('private-channel');
        client.subscribeToPresenceChannel('presence-room');

        expect(client.subscribedChannels.length, 3);

        // Unsubscribe from all
        client.unsubscribeFromChannel('public-channel');
        client.unsubscribeFromChannel('private-channel');
        client.unsubscribeFromChannel('presence-room');

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
        final presenceChannel = client.subscribeToPresenceChannel('presence-room');

        // Test getChannel returns correct types
        expect(client.getChannel('public-channel'), publicChannel);
        expect(client.getChannel('private-channel'), privateChannel);
        expect(client.getChannel('presence-room'), presenceChannel);
        expect(client.getChannel('nonexistent'), isNull);
      });

      test('should prevent duplicate presence channel subscriptions', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Subscribe twice to same presence channel
        final channel1 = client.subscribeToPresenceChannel('presence-room');
        final channel2 = client.subscribeToPresenceChannel('presence-room');

        // Should return the same instance
        expect(identical(channel1, channel2), isTrue);
        expect(client.subscribedChannels.length, 1);
      });

      test('should store presence channels in channel map', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room');

        expect(client.getChannel('presence-room'), channel);
        expect(client.subscribedChannels, contains(channel));
      });
    });

    group('presence channel authentication flow', () {
      test('should pass channel data to authentication', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room', channelData: testChannelData);

        // Verify channel was created with channel data
        expect(channel.channelData, testChannelData);
        expect(channel.channelData?['user_id'], '123');
        expect(channel.channelData?['user_info'], isA<Map<String, dynamic>>());
      });

      test('should handle presence channel without channel data', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        final channel = client.subscribeToPresenceChannel('presence-room');

        // Verify channel was created without channel data
        expect(channel.channelData, isNull);
      });
    });

    group('presence channel member tracking integration', () {
      test('should maintain member list across multiple presence channels', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create multiple presence channels
        final room1 = client.subscribeToPresenceChannel('presence-room1');
        final room2 = client.subscribeToPresenceChannel('presence-room2');

        // Simulate subscription success with different members
        room1.handleSubscriptionSucceeded({
          'channel': 'presence-room1',
          'presence': {
            'hash': {
              '123': {'name': 'John'},
              '456': {'name': 'Jane'},
            },
          },
        });

        room2.handleSubscriptionSucceeded({
          'channel': 'presence-room2',
          'presence': {
            'hash': {
              '789': {'name': 'Bob'},
            },
          },
        });

        // Each channel should have independent member lists
        expect(room1.memberCount, 2);
        expect(room2.memberCount, 1);
        expect(room1.members.any((m) => m.id == '123'), isTrue);
        expect(room1.members.any((m) => m.id == '789'), isFalse);
        expect(room2.members.any((m) => m.id == '789'), isTrue);
        expect(room2.members.any((m) => m.id == '123'), isFalse);
      });

      test('should handle member events independently per channel', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create two presence channels
        final room1 = client.subscribeToPresenceChannel('presence-room1');
        final room2 = client.subscribeToPresenceChannel('presence-room2');

        // Add members to room1
        room1.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John'},
        });

        // Add members to room2
        room2.handleEvent('pusher:member_added', {
          'user_id': '456',
          'user_info': {'name': 'Jane'},
        });

        // Each channel should have its own member
        expect(room1.memberCount, 1);
        expect(room2.memberCount, 1);
        expect(room1.members.first.id, '123');
        expect(room2.members.first.id, '456');
      });
    });

    group('error handling', () {
      test('should handle invalid presence channel names', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Test various invalid names
        expect(() => client.subscribeToPresenceChannel(''), throwsA(isA<InvalidChannelNameException>()));
        expect(() => client.subscribeToPresenceChannel('public-room'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => client.subscribeToPresenceChannel('private-room'), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should validate presence channel name starts with presence-', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        expect(() => client.subscribeToPresenceChannel('room'), throwsA(isA<InvalidChannelNameException>()));
      });
    });

    group('disconnect behavior', () {
      test('should clear presence channels on disconnect', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create presence channel
        client.subscribeToPresenceChannel('presence-room');
        expect(client.subscribedChannels.length, 1);

        // Disconnect
        client.disconnect();

        // All channels should be cleared
        expect(client.subscribedChannels.length, 0);
      });

      test('should handle disconnect with multiple presence channels', () {
        // Set socket ID to bypass the socket ID check
        client.socketId = 'test-socket-id';

        // Create multiple channels
        client.subscribeToChannel('public-channel');
        client.subscribeToPrivateChannel('private-channel');
        client.subscribeToPresenceChannel('presence-room1');
        client.subscribeToPresenceChannel('presence-room2');

        expect(client.subscribedChannels.length, 4);

        // Disconnect
        client.disconnect();

        // All channels should be cleared
        expect(client.subscribedChannels.length, 0);
      });
    });
  });
}
