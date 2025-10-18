import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('Authorizer', () {
    group('validatePrivateChannelName', () {
      test('should accept valid private channel names', () {
        expect(() => validatePrivateChannelName('private-channel'), returnsNormally);
        expect(() => validatePrivateChannelName('private-user-123'), returnsNormally);
        expect(() => validatePrivateChannelName('private-room-abc'), returnsNormally);
        expect(() => validatePrivateChannelName('private-test_channel'), returnsNormally);
        expect(() => validatePrivateChannelName('private-channel-with-hyphens'), returnsNormally);
      });

      test('should reject empty channel names', () {
        expect(() => validatePrivateChannelName(''), throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', 'Channel name cannot be empty')));
      });

      test('should reject channel names without private- prefix', () {
        expect(
          () => validatePrivateChannelName('public-channel'),
          throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', contains('Private channel name must start with "private-" prefix'))),
        );

        expect(
          () => validatePrivateChannelName('channel'),
          throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', contains('Private channel name must start with "private-" prefix'))),
        );
      });

      test('should reject channel names that are too long', () {
        final longName = 'private-${'a' * 200}';
        expect(() => validatePrivateChannelName(longName), throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', 'Channel name cannot exceed 200 characters')));
      });

      test('should reject channel names with invalid characters', () {
        expect(
          () => validatePrivateChannelName('private-channel!'),
          throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', contains('Channel name contains invalid characters'))),
        );

        expect(
          () => validatePrivateChannelName('private-channel#'),
          throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', contains('Channel name contains invalid characters'))),
        );

        expect(
          () => validatePrivateChannelName('private-channel\$'),
          throwsA(isA<InvalidChannelNameException>().having((e) => e.message, 'message', contains('Channel name contains invalid characters'))),
        );
      });
    });

    group('AuthenticationException', () {
      test('should create exception with message and channel name', () {
        const exception = AuthenticationException(message: 'Test error', channelName: 'private-test');

        expect(exception.message, 'Test error');
        expect(exception.channelName, 'private-test');
        expect(exception.statusCode, isNull);
      });

      test('should create exception with status code', () {
        const exception = AuthenticationException(message: 'Forbidden', channelName: 'private-test', statusCode: 403);

        expect(exception.message, 'Forbidden');
        expect(exception.channelName, 'private-test');
        expect(exception.statusCode, 403);
      });

      test('should format toString correctly without status code', () {
        const exception = AuthenticationException(message: 'Test error', channelName: 'private-test');

        expect(exception.toString(), 'AuthenticationException: Test error for channel "private-test"');
      });

      test('should format toString correctly with status code', () {
        const exception = AuthenticationException(message: 'Forbidden', channelName: 'private-test', statusCode: 403);

        expect(exception.toString(), 'AuthenticationException: Forbidden (HTTP 403) for channel "private-test"');
      });
    });
  });
}
