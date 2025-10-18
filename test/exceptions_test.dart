import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('PusherException', () {
    test('should create exception with message', () {
      // Arrange & Act
      final exception = PusherException('Test error');

      // Assert
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), equals('PusherException: Test error'));
      expect(exception, isA<Exception>());
    });

    test('should be const constructible', () {
      // Arrange & Act
      const exception = PusherException('Const error');

      // Assert
      expect(exception.message, equals('Const error'));
    });
  });

  group('ConnectionException', () {
    test('should create exception with message only', () {
      // Arrange & Act
      final exception = ConnectionException('Connection failed');

      // Assert
      expect(exception.message, equals('Connection failed'));
      expect(exception.cause, isNull);
      expect(exception.toString(), equals('ConnectionException: Connection failed'));
      expect(exception, isA<PusherException>());
      expect(exception, isA<Exception>());
    });

    test('should create exception with message and cause', () {
      // Arrange
      final cause = Exception('Network error');

      // Act
      final exception = ConnectionException('Connection failed', cause: cause);

      // Assert
      expect(exception.message, equals('Connection failed'));
      expect(exception.cause, equals(cause));
      expect(exception, isA<PusherException>());
      expect(exception.toString(), contains('Connection failed'));
      expect(exception.toString(), contains('Caused by:'));
    });

    test('should be const constructible without cause', () {
      // Arrange & Act
      const exception = ConnectionException('Const connection error');

      // Assert
      expect(exception.message, equals('Const connection error'));
      expect(exception.cause, isNull);
    });

    test('toString should format cause information correctly', () {
      // Arrange
      final cause = 'String cause';

      // Act
      final exception = ConnectionException('Failed', cause: cause);

      // Assert
      expect(exception.toString(), equals('ConnectionException: Failed (Caused by: String cause)'));
    });
  });

  group('ChannelException', () {
    test('should create exception with message only', () {
      // Arrange & Act
      final exception = ChannelException('Channel error');

      // Assert
      expect(exception.message, equals('Channel error'));
      expect(exception.channelName, isNull);
      expect(exception.toString(), equals('ChannelException: Channel error'));
      expect(exception, isA<PusherException>());
    });

    test('should create exception with message and channel name', () {
      // Arrange & Act
      final exception = ChannelException('Subscription failed', channelName: 'private-chat');

      // Assert
      expect(exception.message, equals('Subscription failed'));
      expect(exception.channelName, equals('private-chat'));
      expect(exception.toString(), contains('Subscription failed'));
      expect(exception.toString(), contains('private-chat'));
      expect(exception, isA<PusherException>());
    });

    test('should be const constructible', () {
      // Arrange & Act
      const exception = ChannelException('Const error', channelName: 'test-channel');

      // Assert
      expect(exception.message, equals('Const error'));
      expect(exception.channelName, equals('test-channel'));
    });

    test('toString should format channel name correctly', () {
      // Arrange & Act
      final exception = ChannelException('Error', channelName: 'my-channel');

      // Assert
      expect(exception.toString(), equals('ChannelException: Error for channel "my-channel"'));
    });
  });

  group('InvalidChannelNameException', () {
    test('should create exception with message and channel name', () {
      // Arrange & Act
      final exception = InvalidChannelNameException('Channel name is invalid', 'bad-name');

      // Assert
      expect(exception.message, equals('Channel name is invalid'));
      expect(exception.channelName, equals('bad-name'));
      expect(exception.toString(), contains('InvalidChannelNameException'));
      expect(exception.toString(), contains('Channel name is invalid'));
      expect(exception.toString(), contains('bad-name'));
      expect(exception, isA<PusherException>());
    });

    test('should be const constructible', () {
      // Arrange & Act
      const exception = InvalidChannelNameException('Invalid', 'test');

      // Assert
      expect(exception.message, equals('Invalid'));
      expect(exception.channelName, equals('test'));
    });

    test('toString should format correctly', () {
      // Arrange & Act
      final exception = InvalidChannelNameException('Must start with prefix', 'invalid');

      // Assert
      expect(exception.toString(), equals('InvalidChannelNameException: Must start with prefix (Channel: "invalid")'));
    });
  });

  group('AuthenticationException', () {
    test('should create exception with message and channel name', () {
      // Arrange & Act
      final exception = AuthenticationException(message: 'Auth failed', channelName: 'private-chat');

      // Assert
      expect(exception.message, equals('Auth failed'));
      expect(exception.channelName, equals('private-chat'));
      expect(exception.statusCode, isNull);
      expect(exception.toString(), contains('AuthenticationException'));
      expect(exception.toString(), contains('Auth failed'));
      expect(exception.toString(), contains('private-chat'));
      expect(exception, isA<PusherException>());
    });

    test('should create exception with status code', () {
      // Arrange & Act
      final exception = AuthenticationException(message: 'Forbidden', statusCode: 403, channelName: 'private-chat');

      // Assert
      expect(exception.message, equals('Forbidden'));
      expect(exception.statusCode, equals(403));
      expect(exception.channelName, equals('private-chat'));
      expect(exception.toString(), contains('HTTP 403'));
    });

    test('should be const constructible', () {
      // Arrange & Act
      const exception = AuthenticationException(message: 'Const auth error', channelName: 'test-channel');

      // Assert
      expect(exception.message, equals('Const auth error'));
      expect(exception.channelName, equals('test-channel'));
    });

    test('toString should format correctly without status code', () {
      // Arrange & Act
      final exception = AuthenticationException(message: 'Failed', channelName: 'private-test');

      // Assert
      expect(exception.toString(), equals('AuthenticationException: Failed for channel "private-test"'));
    });

    test('toString should format correctly with status code', () {
      // Arrange & Act
      final exception = AuthenticationException(message: 'Forbidden', statusCode: 403, channelName: 'private-chat');

      // Assert
      expect(exception.toString(), equals('AuthenticationException: Forbidden (HTTP 403) for channel "private-chat"'));
    });
  });

  group('Exception Hierarchy', () {
    test('should have correct exception hierarchy', () {
      // Arrange & Act
      final pusherEx = PusherException('base');
      final connectionEx = ConnectionException('connection');
      final authEx = AuthenticationException(message: 'auth', channelName: 'private-test');
      final channelEx = ChannelException('channel');
      final invalidNameEx = InvalidChannelNameException('invalid', 'bad-name');

      // Assert - All should be Exception
      expect(pusherEx, isA<Exception>());
      expect(connectionEx, isA<Exception>());
      expect(authEx, isA<Exception>());
      expect(channelEx, isA<Exception>());
      expect(invalidNameEx, isA<Exception>());

      // Assert - All except base should be PusherException
      expect(connectionEx, isA<PusherException>());
      expect(authEx, isA<PusherException>());
      expect(channelEx, isA<PusherException>());
      expect(invalidNameEx, isA<PusherException>());

      // Assert - Each should be its specific type
      expect(connectionEx, isA<ConnectionException>());
      expect(authEx, isA<AuthenticationException>());
      expect(channelEx, isA<ChannelException>());
      expect(invalidNameEx, isA<InvalidChannelNameException>());
    });

    test('should allow catching all exceptions with PusherException', () {
      // Arrange
      final exceptions = <PusherException>[
        ConnectionException('connection'),
        AuthenticationException(message: 'auth', channelName: 'test'),
        ChannelException('channel'),
        InvalidChannelNameException('invalid', 'test'),
      ];

      // Act & Assert
      for (final exception in exceptions) {
        expect(exception, isA<PusherException>());
        expect(exception.message, isNotEmpty);
        expect(exception.toString(), contains(exception.message));
      }
    });

    test('should allow type checking in catch blocks', () {
      // Arrange
      dynamic thrownException;

      // Act - ConnectionException
      try {
        throw ConnectionException('test');
      } catch (e) {
        thrownException = e;
      }

      // Assert
      expect(thrownException is ConnectionException, isTrue);
      expect(thrownException is PusherException, isTrue);
      expect(thrownException is AuthenticationException, isFalse);

      // Act - AuthenticationException
      try {
        throw AuthenticationException(message: 'test', channelName: 'test');
      } catch (e) {
        thrownException = e;
      }

      // Assert
      expect(thrownException is AuthenticationException, isTrue);
      expect(thrownException is PusherException, isTrue);
      expect(thrownException is ConnectionException, isFalse);
    });
  });
}
