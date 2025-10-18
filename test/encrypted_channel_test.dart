import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('EncryptedChannel', () {
    late Authorizer mockAuthorizer;
    late String testChannelName;
    late String testSocketId;
    late String testAuthEndpoint;
    late String testEncryptionKey;
    late List<String> sentMessages;

    setUp(() {
      testChannelName = 'private-encrypted-messages';
      testSocketId = 'test-socket-id';
      testAuthEndpoint = 'https://example.com/auth';
      // Valid base64-encoded 32-byte key
      testEncryptionKey = base64.encode(List<int>.generate(32, (i) => i));
      sentMessages = [];

      mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token', 'X-Custom-Header': 'test-value'};
      };
    });

    EncryptedChannel createEncryptedChannel({String? channelName, String? encryptionKey}) {
      return EncryptedChannel(
        name: channelName ?? testChannelName,
        authorizer: mockAuthorizer,
        authEndpoint: testAuthEndpoint,
        socketId: testSocketId,
        sendMessage: (String message) {
          sentMessages.add(message);
        },
        encryptionMasterKey: encryptionKey ?? testEncryptionKey,
      );
    }

    group('validateEncryptedChannelName', () {
      test('should accept valid encrypted channel names', () {
        // Arrange & Act & Assert
        expect(() => validateEncryptedChannelName('private-encrypted-messages'), returnsNormally);
        expect(() => validateEncryptedChannelName('private-encrypted-chat'), returnsNormally);
        expect(() => validateEncryptedChannelName('private-encrypted-test_channel'), returnsNormally);
      });

      test('should reject channel names without private-encrypted- prefix', () {
        // Arrange & Act & Assert
        expect(() => validateEncryptedChannelName('private-messages'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validateEncryptedChannelName('public-encrypted-messages'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validateEncryptedChannelName('messages'), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject empty channel names', () {
        // Arrange & Act & Assert
        expect(() => validateEncryptedChannelName(''), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject channel names exceeding 200 characters', () {
        // Arrange
        final longName = 'private-encrypted-${'x' * 200}';

        // Act & Assert
        expect(() => validateEncryptedChannelName(longName), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject channel names with invalid characters', () {
        // Arrange & Act & Assert
        expect(() => validateEncryptedChannelName('private-encrypted-test#channel'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validateEncryptedChannelName('private-encrypted-test channel'), throwsA(isA<InvalidChannelNameException>()));
      });
    });

    group('constructor', () {
      test('should create encrypted channel with valid name and key', () {
        // Arrange & Act
        final channel = createEncryptedChannel();

        // Assert
        expect(channel.name, testChannelName);
        expect(channel.state, ChannelState.unsubscribed);
        expect(channel.encryptionMasterKey, testEncryptionKey);
      });

      test('should throw error for invalid encrypted channel name', () {
        // Arrange & Act & Assert
        expect(() => createEncryptedChannel(channelName: 'private-messages'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => createEncryptedChannel(channelName: 'public-channel'), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should throw error for empty encryption key', () {
        // Arrange & Act & Assert
        expect(() => createEncryptedChannel(encryptionKey: ''), throwsA(isA<ArgumentError>()));
      });

      test('should throw error for invalid base64 encryption key', () {
        // Arrange & Act & Assert
        expect(() => createEncryptedChannel(encryptionKey: 'not-valid-base64!!!'), throwsA(isA<ArgumentError>()));
      });

      test('should throw error for encryption key with wrong length', () {
        // Arrange
        // 16-byte key instead of 32-byte
        final shortKey = base64.encode(List<int>.generate(16, (i) => i));

        // Act & Assert
        expect(() => createEncryptedChannel(encryptionKey: shortKey), throwsA(isA<ArgumentError>()));
      });

      test('should store authorizer and auth endpoint', () {
        // Arrange & Act
        final channel = createEncryptedChannel();

        // Assert
        expect(channel.authorizer, mockAuthorizer);
        expect(channel.authEndpoint, testAuthEndpoint);
        expect(channel.socketId, testSocketId);
      });
    });

    group('event decryption', () {
      test('should decrypt valid encrypted event data', () async {
        // Arrange
        final channel = createEncryptedChannel();

        // Create test data to encrypt
        final originalData = {'message': 'Hello, World!', 'timestamp': 123456};
        final originalJson = jsonEncode(originalData);

        // Encrypt the data using the same key
        // Note: This requires the encrypt package
        final key = base64.decode(testEncryptionKey);
        final iv = Uint8List.fromList(List<int>.generate(16, (i) => i)); // Simple IV for testing

        // Use the encrypt package to encrypt
        final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc));
        final encrypted = encrypter.encrypt(originalJson, iv: encrypt.IV(iv));

        final encryptedEventData = {'ciphertext': encrypted.base64, 'nonce': base64.encode(iv)};

        // Act
        final eventFuture = channel.stream.first;
        channel.handleEvent('message', encryptedEventData);
        final receivedEvent = await eventFuture;

        // Assert
        expect(receivedEvent.eventName, 'message');
        expect(receivedEvent.data, originalData);
      });

      test('should handle decryption error for malformed data structure', () async {
        // Arrange
        final channel = createEncryptedChannel();

        // Act & Assert - Use expectLater for stream events
        final eventFuture = expectLater(
          channel.stream,
          emits(
            predicate<ChannelEvent>((event) {
              return event.eventName == 'pusher:decryption_error' && event.data['error'] == 'decryption_failed';
            }),
          ),
        );

        // Pass invalid data structure
        channel.handleEvent('message', 'not-a-json-object');

        await eventFuture;
      });

      test('should handle decryption error for missing ciphertext field', () async {
        // Arrange
        final channel = createEncryptedChannel();

        final malformedData = {
          'nonce': base64.encode(List<int>.generate(16, (i) => i)),
          // Missing 'ciphertext' field
        };

        // Act & Assert - Use expectLater for stream events
        final eventFuture = expectLater(
          channel.stream,
          emits(
            predicate<ChannelEvent>((event) {
              return event.eventName == 'pusher:decryption_error' && event.data['error'] == 'decryption_failed';
            }),
          ),
        );

        channel.handleEvent('message', malformedData);

        await eventFuture;
      });

      test('should handle decryption error for missing nonce field', () async {
        // Arrange
        final channel = createEncryptedChannel();

        final malformedData = {
          'ciphertext': 'some-encrypted-data',
          // Missing 'nonce' field
        };

        // Act & Assert - Use expectLater for stream events
        final eventFuture = expectLater(
          channel.stream,
          emits(
            predicate<ChannelEvent>((event) {
              return event.eventName == 'pusher:decryption_error' && event.data['error'] == 'decryption_failed';
            }),
          ),
        );

        channel.handleEvent('message', malformedData);

        await eventFuture;
      });

      test('should handle decryption error for invalid encrypted data', () async {
        // Arrange
        final channel = createEncryptedChannel();

        final invalidData = {'ciphertext': 'invalid-base64-encrypted-data', 'nonce': base64.encode(List<int>.generate(16, (i) => i))};

        // Act & Assert - Use expectLater for stream events
        final eventFuture = expectLater(
          channel.stream,
          emits(
            predicate<ChannelEvent>((event) {
              return event.eventName == 'pusher:decryption_error' && event.data['error'] == 'decryption_failed';
            }),
          ),
        );

        channel.handleEvent('message', invalidData);

        await eventFuture;
      });

      test('should forward decrypted events to stream listeners', () async {
        // Arrange
        final channel = createEncryptedChannel();

        // Create test data to encrypt
        final originalData = {'event': 'new-message', 'content': 'Test'};
        final originalJson = jsonEncode(originalData);

        // Encrypt the data
        final key = base64.decode(testEncryptionKey);
        final iv = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
        final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc));
        final encrypted = encrypter.encrypt(originalJson, iv: encrypt.IV(iv));

        final encryptedEventData = {'ciphertext': encrypted.base64, 'nonce': base64.encode(iv)};

        // Act
        final eventFuture = channel.on('new-message').first;
        channel.handleEvent('new-message', encryptedEventData);
        final receivedEvent = await eventFuture;

        // Assert
        expect(receivedEvent.eventName, 'new-message');
        expect(receivedEvent.data, originalData);
      });

      test('should forward decrypted events to callback listeners', () {
        // Arrange
        final channel = createEncryptedChannel();

        // Create test data to encrypt
        final originalData = {'id': 42, 'text': 'Callback test'};
        final originalJson = jsonEncode(originalData);

        // Encrypt the data
        final key = base64.decode(testEncryptionKey);
        final iv = Uint8List.fromList(List<int>.generate(16, (i) => i + 2));
        final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc));
        final encrypted = encrypter.encrypt(originalJson, iv: encrypt.IV(iv));

        final encryptedEventData = {'ciphertext': encrypted.base64, 'nonce': base64.encode(iv)};

        // Track events via callback
        String? receivedEventName;
        dynamic receivedData;
        channel.bind('test-callback', (eventName, data) {
          receivedEventName = eventName;
          receivedData = data;
        });

        // Act
        channel.handleEvent('test-callback', encryptedEventData);

        // Assert
        expect(receivedEventName, 'test-callback');
        expect(receivedData, originalData);
      });
    });

    group('inherited functionality', () {
      test('should support event binding and unbinding', () {
        // Arrange
        final channel = createEncryptedChannel();
        bool eventReceived = false;

        channel.bind('test-event', (String eventName, dynamic data) {
          eventReceived = true;
        });

        // Create encrypted test data
        final originalData = {'test': 'data'};
        final originalJson = jsonEncode(originalData);
        final key = base64.decode(testEncryptionKey);
        final iv = Uint8List.fromList(List<int>.generate(16, (i) => i + 3));
        final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc));
        final encrypted = encrypter.encrypt(originalJson, iv: encrypt.IV(iv));

        final encryptedEventData = {'ciphertext': encrypted.base64, 'nonce': base64.encode(iv)};

        // Act
        channel.handleEvent('test-event', encryptedEventData);

        // Assert
        expect(eventReceived, true);

        // Act - Unbind and test again
        channel.unbind('test-event');
        eventReceived = false;
        channel.handleEvent('test-event', encryptedEventData);

        // Assert
        expect(eventReceived, false);
      });

      test('should support state change listeners', () {
        // Arrange
        final channel = createEncryptedChannel();
        final stateChanges = <ChannelState>[];

        channel.addStateListener((state) {
          stateChanges.add(state);
        });

        // Act - Trigger state change by calling subscribe
        // This will change state to subscribing (though it will fail due to no HTTP mock)
        try {
          channel.subscribe();
        } catch (e) {
          // Expected to fail due to HTTP call
        }

        // Assert - Should have captured state change
        expect(stateChanges.isNotEmpty, true);
        expect(stateChanges.first, ChannelState.subscribing);
      });

      test('should support stream-based event listening', () async {
        // Arrange
        final channel = createEncryptedChannel();

        // Create encrypted test data
        final originalData = {'stream': 'test'};
        final originalJson = jsonEncode(originalData);
        final key = base64.decode(testEncryptionKey);
        final iv = Uint8List.fromList(List<int>.generate(16, (i) => i + 4));
        final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.cbc));
        final encrypted = encrypter.encrypt(originalJson, iv: encrypt.IV(iv));

        final encryptedEventData = {'ciphertext': encrypted.base64, 'nonce': base64.encode(iv)};

        // Act
        final eventFuture = channel.on('stream-test').first;
        channel.handleEvent('stream-test', encryptedEventData);

        // Assert
        final event = await eventFuture;
        expect(event.eventName, 'stream-test');
        expect(event.data, originalData);
      });
    });
  });
}
