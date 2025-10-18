import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('ReverbClient Encrypted Channel Integration', () {
    late ReverbClient client;
    late Authorizer mockAuthorizer;
    late String testEncryptionKey;

    setUp(() {
      mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token'};
      };

      // Valid base64-encoded 32-byte key
      testEncryptionKey = base64.encode(List<int>.generate(32, (i) => i));

      client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer, authEndpoint: 'https://example.com/auth');
    });

    tearDown(() async {
      // Disconnect and wait a bit for any pending async operations to complete
      client.disconnect();
      await Future.delayed(Duration(milliseconds: 100));
    });

    group('encryptedChannel', () {
      test('should throw error if authorizer is not configured', () {
        // Arrange
        final clientWithoutAuthorizer = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authEndpoint: 'https://example.com/auth');

        // Act & Assert
        expect(
          () => clientWithoutAuthorizer.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey),
          throwsA(isA<ChannelException>().having((e) => e.message, 'message', contains('Authorizer and authEndpoint must be configured'))),
        );
      });

      test('should throw error if authEndpoint is not configured', () {
        // Arrange
        final clientWithoutEndpoint = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: mockAuthorizer);

        // Act & Assert
        expect(
          () => clientWithoutEndpoint.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey),
          throwsA(isA<ChannelException>().having((e) => e.message, 'message', contains('Authorizer and authEndpoint must be configured'))),
        );
      });

      test('should throw error if socketId is not available', () {
        // Arrange & Act & Assert
        expect(
          () => client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey),
          throwsA(isA<ConnectionException>().having((e) => e.message, 'message', contains('not connected to server'))),
        );
      });

      test('should throw error for invalid encrypted channel name', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act & Assert - Wrong prefix
        expect(() => client.encryptedChannel('private-messages', encryptionMasterKey: testEncryptionKey), throwsA(isA<InvalidChannelNameException>()));

        expect(() => client.encryptedChannel('public-encrypted-messages', encryptionMasterKey: testEncryptionKey), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should throw error for invalid encryption key', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act & Assert - Empty key
        expect(() => client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: ''), throwsA(isA<ArgumentError>()));

        // Wrong length key
        final shortKey = base64.encode(List<int>.generate(16, (i) => i));
        expect(() => client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: shortKey), throwsA(isA<ArgumentError>()));

        // Invalid base64
        expect(() => client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: 'not-valid-base64!!!'), throwsA(isA<ArgumentError>()));
      });

      test('should create encrypted channel with valid parameters', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act
        final channel = client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);

        // Assert
        expect(channel, isA<EncryptedChannel>());
        expect(channel.name, 'private-encrypted-messages');
        expect(channel.encryptionMasterKey, testEncryptionKey);
        expect(channel.state, ChannelState.unsubscribed);
      });

      test('should return existing channel if already subscribed', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act
        final channel1 = client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);
        final channel2 = client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);

        // Assert
        expect(channel1, same(channel2));
        expect(client.subscribedChannels.length, 1);
      });

      test('should throw error if channel exists as different type', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Create a public channel first with a name that could be encrypted
        // (This tests that we can't convert an existing channel to encrypted)
        client.subscribeToChannel('private-encrypted-test');

        // Act & Assert
        expect(() => client.encryptedChannel('private-encrypted-test', encryptionMasterKey: testEncryptionKey), throwsA(isA<ChannelException>()));
      });
    });

    group('mixed channel types', () {
      test('should handle public, private, and encrypted channels', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act
        final publicChannel = client.subscribeToChannel('public-channel');
        final encryptedChannel = client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);

        // Assert
        expect(publicChannel, isA<Channel>());
        expect(publicChannel, isNot(isA<PrivateChannel>()));
        expect(publicChannel, isNot(isA<EncryptedChannel>()));

        expect(encryptedChannel, isA<EncryptedChannel>());
        expect(encryptedChannel, isA<PrivateChannel>()); // EncryptedChannel extends PrivateChannel

        expect(client.subscribedChannels.length, 2);
        expect(client.subscribedChannels, contains(publicChannel));
        expect(client.subscribedChannels, contains(encryptedChannel));
      });

      test('should handle unsubscription for all channel types', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Subscribe to all types (avoid auto-subscription for private channels)
        client.subscribeToChannel('public-channel');
        client.subscribeToChannel('public-channel-2');
        client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);

        expect(client.subscribedChannels.length, 3);

        // Act - Unsubscribe from all
        client.unsubscribeFromChannel('public-channel');
        client.unsubscribeFromChannel('public-channel-2');
        client.unsubscribeFromChannel('private-encrypted-messages');

        // Assert
        expect(client.subscribedChannels.length, 0);
      });
    });

    group('channel management', () {
      test('should return correct channel type from getChannel', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Create channels (avoid subscribeToPrivateChannel to prevent auto-subscribe)
        final publicChannel = client.subscribeToChannel('public-channel');
        final encryptedChannel = client.encryptedChannel('private-encrypted-messages', encryptionMasterKey: testEncryptionKey);

        // Act & Assert
        expect(client.getChannel('public-channel'), publicChannel);
        expect(client.getChannel('private-encrypted-messages'), encryptedChannel);
        expect(client.getChannel('nonexistent'), isNull);
      });

      test('should track all subscribed channels correctly', () {
        // Arrange
        client.socketId = 'test-socket-id';

        // Act (avoid subscribeToPrivateChannel to prevent auto-subscribe)
        client.subscribeToChannel('public-1');
        client.subscribeToChannel('public-2');
        client.encryptedChannel('private-encrypted-1', encryptionMasterKey: testEncryptionKey);

        // Assert
        expect(client.subscribedChannels.length, 3);

        final channelNames = client.subscribedChannels.map((c) => c.name).toList();
        expect(channelNames, contains('public-1'));
        expect(channelNames, contains('public-2'));
        expect(channelNames, contains('private-encrypted-1'));
      });
    });

    group('authentication flow', () {
      test('should call authorizer with correct parameters for encrypted channel', () async {
        // Arrange
        client.socketId = 'test-socket-id';
        bool authorizerCalled = false;
        String? calledChannelName;
        String? calledSocketId;

        Future<Map<String, String>> customAuthorizer(String channelName, String socketId) async {
          authorizerCalled = true;
          calledChannelName = channelName;
          calledSocketId = socketId;
          return {'Authorization': 'Bearer test-token'};
        }

        final customClient = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', authorizer: customAuthorizer, authEndpoint: 'https://example.com/auth');
        customClient.socketId = 'test-socket-id';

        // Act
        final channel = customClient.encryptedChannel('private-encrypted-test', encryptionMasterKey: testEncryptionKey);

        try {
          await channel.subscribe();
        } catch (e) {
          // Expected to fail due to HTTP call
        }

        // Assert
        expect(authorizerCalled, true);
        expect(calledChannelName, 'private-encrypted-test');
        expect(calledSocketId, 'test-socket-id');
      });
    });
  });
}
