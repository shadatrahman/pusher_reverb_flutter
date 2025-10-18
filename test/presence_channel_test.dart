import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('PresenceChannel', () {
    late Authorizer mockAuthorizer;
    late String testChannelName;
    late String testSocketId;
    late String testAuthEndpoint;
    late List<String> sentMessages;
    late Map<String, dynamic> testChannelData;

    setUp(() {
      testChannelName = 'presence-room';
      testSocketId = 'test-socket-id';
      testAuthEndpoint = 'https://example.com/auth';
      sentMessages = [];
      testChannelData = {
        'user_id': '123',
        'user_info': {'name': 'John Doe', 'avatar': 'https://example.com/avatar.jpg'},
      };

      mockAuthorizer = (String channelName, String socketId) async {
        return {'Authorization': 'Bearer test-token'};
      };
    });

    PresenceChannel createPresenceChannel({Map<String, dynamic>? channelData}) {
      return PresenceChannel(
        name: testChannelName,
        authorizer: mockAuthorizer,
        authEndpoint: testAuthEndpoint,
        socketId: testSocketId,
        sendMessage: (String message) {
          sentMessages.add(message);
        },
        channelData: channelData,
      );
    }

    group('constructor', () {
      test('should create presence channel with valid name', () {
        final channel = createPresenceChannel();
        expect(channel.name, testChannelName);
        expect(channel.state, ChannelState.unsubscribed);
        expect(channel.memberCount, 0);
        expect(channel.members, isEmpty);
      });

      test('should throw error for invalid presence channel name', () {
        expect(
          () => PresenceChannel(name: 'private-channel', authorizer: mockAuthorizer, authEndpoint: testAuthEndpoint, socketId: testSocketId, sendMessage: (String message) {}),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should throw error for empty channel name', () {
        expect(
          () => PresenceChannel(name: '', authorizer: mockAuthorizer, authEndpoint: testAuthEndpoint, socketId: testSocketId, sendMessage: (String message) {}),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should throw error for channel name without presence- prefix', () {
        expect(
          () => PresenceChannel(name: 'public-channel', authorizer: mockAuthorizer, authEndpoint: testAuthEndpoint, socketId: testSocketId, sendMessage: (String message) {}),
          throwsA(isA<InvalidChannelNameException>()),
        );
      });

      test('should store channel data when provided', () {
        final channel = createPresenceChannel(channelData: testChannelData);
        expect(channel.channelData, testChannelData);
      });

      test('should allow null channel data', () {
        final channel = createPresenceChannel();
        expect(channel.channelData, isNull);
      });
    });

    group('validatePresenceChannelName', () {
      test('should accept valid presence channel names', () {
        expect(() => validatePresenceChannelName('presence-room'), returnsNormally);
        expect(() => validatePresenceChannelName('presence-chat-123'), returnsNormally);
        expect(() => validatePresenceChannelName('presence-user_activity'), returnsNormally);
      });

      test('should reject names without presence- prefix', () {
        expect(() => validatePresenceChannelName('private-room'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validatePresenceChannelName('public-room'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validatePresenceChannelName('room'), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject empty channel name', () {
        expect(() => validatePresenceChannelName(''), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject channel names exceeding 200 characters', () {
        final longName = 'presence-${'a' * 200}';
        expect(() => validatePresenceChannelName(longName), throwsA(isA<InvalidChannelNameException>()));
      });

      test('should reject channel names with invalid characters', () {
        expect(() => validatePresenceChannelName('presence-room#123'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validatePresenceChannelName('presence-room!'), throwsA(isA<InvalidChannelNameException>()));
        expect(() => validatePresenceChannelName('presence-room space'), throwsA(isA<InvalidChannelNameException>()));
      });
    });

    group('member tracking', () {
      test('should start with empty member list', () {
        final channel = createPresenceChannel();
        expect(channel.members, isEmpty);
        expect(channel.memberCount, 0);
      });

      test('should parse initial member list from subscription success', () {
        // Arrange
        final channel = createPresenceChannel();
        final subscriptionData = {
          'channel': testChannelName,
          'presence': {
            'hash': {
              '123': {'name': 'John Doe'},
              '456': {'name': 'Jane Smith'},
              '789': {'name': 'Bob Johnson'},
            },
            'count': 3,
          },
        };

        // Act
        channel.handleSubscriptionSucceeded(subscriptionData);

        // Assert
        expect(channel.state, ChannelState.subscribed);
        expect(channel.memberCount, 3);
        expect(channel.members.length, 3);
        expect(channel.members.any((m) => m.id == '123'), isTrue);
        expect(channel.members.any((m) => m.id == '456'), isTrue);
        expect(channel.members.any((m) => m.id == '789'), isTrue);
      });

      test('should handle subscription success with empty member list', () {
        // Arrange
        final channel = createPresenceChannel();
        final subscriptionData = {
          'channel': testChannelName,
          'presence': {'hash': {}, 'count': 0},
        };

        // Act
        channel.handleSubscriptionSucceeded(subscriptionData);

        // Assert
        expect(channel.state, ChannelState.subscribed);
        expect(channel.memberCount, 0);
        expect(channel.members, isEmpty);
      });

      test('should handle subscription success without presence data', () {
        // Arrange
        final channel = createPresenceChannel();
        final subscriptionData = {'channel': testChannelName};

        // Act
        channel.handleSubscriptionSucceeded(subscriptionData);

        // Assert
        expect(channel.state, ChannelState.subscribed);
        expect(channel.memberCount, 0);
        expect(channel.members, isEmpty);
      });

      test('should handle null subscription data', () {
        // Arrange
        final channel = createPresenceChannel();

        // Act
        channel.handleSubscriptionSucceeded(null);

        // Assert
        expect(channel.state, ChannelState.subscribed);
        expect(channel.memberCount, 0);
        expect(channel.members, isEmpty);
      });

      test('should clear previous members on subscription success', () {
        // Arrange
        final channel = createPresenceChannel();

        // First subscription with members
        final firstSubscriptionData = {
          'channel': testChannelName,
          'presence': {
            'hash': {
              '123': {'name': 'John Doe'},
            },
          },
        };
        channel.handleSubscriptionSucceeded(firstSubscriptionData);
        expect(channel.memberCount, 1);

        // Second subscription with different members
        final secondSubscriptionData = {
          'channel': testChannelName,
          'presence': {
            'hash': {
              '456': {'name': 'Jane Smith'},
              '789': {'name': 'Bob Johnson'},
            },
          },
        };

        // Act
        channel.handleSubscriptionSucceeded(secondSubscriptionData);

        // Assert
        expect(channel.memberCount, 2);
        expect(channel.members.any((m) => m.id == '123'), isFalse);
        expect(channel.members.any((m) => m.id == '456'), isTrue);
        expect(channel.members.any((m) => m.id == '789'), isTrue);
      });

      test('should return list copy not original map values', () {
        // Arrange
        final channel = createPresenceChannel();
        final subscriptionData = {
          'channel': testChannelName,
          'presence': {
            'hash': {
              '123': {'name': 'John Doe'},
            },
          },
        };
        channel.handleSubscriptionSucceeded(subscriptionData);

        // Act
        final members1 = channel.members;
        final members2 = channel.members;

        // Assert - should be different list instances
        expect(identical(members1, members2), isFalse);
        expect(members1.length, members2.length);
      });
    });

    group('member_added event', () {
      test('should add member when member_added event is received', () {
        // Arrange
        final channel = createPresenceChannel();
        final memberData = {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        };

        // Act
        channel.handleEvent('pusher:member_added', memberData);

        // Assert
        expect(channel.memberCount, 1);
        expect(channel.members.length, 1);
        expect(channel.members.first.id, '123');
        expect(channel.members.first.info['name'], 'John Doe');
      });

      test('should add multiple members sequentially', () {
        // Arrange
        final channel = createPresenceChannel();

        // Act
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });
        channel.handleEvent('pusher:member_added', {
          'user_id': '456',
          'user_info': {'name': 'Jane Smith'},
        });
        channel.handleEvent('pusher:member_added', {
          'user_id': '789',
          'user_info': {'name': 'Bob Johnson'},
        });

        // Assert
        expect(channel.memberCount, 3);
        expect(channel.members.any((m) => m.id == '123'), isTrue);
        expect(channel.members.any((m) => m.id == '456'), isTrue);
        expect(channel.members.any((m) => m.id == '789'), isTrue);
      });

      test('should update existing member when same user_id is added', () {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });

        // Act - add same user with updated info
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Updated'},
        });

        // Assert - should still only have one member with updated info
        expect(channel.memberCount, 1);
        expect(channel.members.first.id, '123');
        expect(channel.members.first.info['name'], 'John Updated');
      });

      test('should handle member_added with missing user_info', () {
        // Arrange
        final channel = createPresenceChannel();

        // Act
        channel.handleEvent('pusher:member_added', {'user_id': '123'});

        // Assert
        expect(channel.memberCount, 1);
        expect(channel.members.first.id, '123');
        expect(channel.members.first.info, isEmpty);
      });

      test('should handle member_added with null user_id gracefully', () {
        // Arrange
        final channel = createPresenceChannel();

        // Act
        channel.handleEvent('pusher:member_added', {
          'user_info': {'name': 'John Doe'},
        });

        // Assert - should not add member without user_id
        expect(channel.memberCount, 0);
      });

      test('should handle member_added with null data gracefully', () {
        // Arrange
        final channel = createPresenceChannel();

        // Act
        channel.handleEvent('pusher:member_added', null);

        // Assert
        expect(channel.memberCount, 0);
      });

      test('should emit member_added event to stream', () async {
        // Arrange
        final channel = createPresenceChannel();
        final events = <ChannelEvent>[];
        channel.on('pusher:member_added').listen((event) {
          events.add(event);
        });

        final memberData = {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        };

        // Act
        channel.handleEvent('pusher:member_added', memberData);

        // Wait for async stream processing
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(events.length, 1);
        expect(events.first.eventName, 'pusher:member_added');
        expect(events.first.data, memberData);
      });
    });

    group('member_removed event', () {
      test('should remove member when member_removed event is received', () {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });
        expect(channel.memberCount, 1);

        // Act
        channel.handleEvent('pusher:member_removed', {'user_id': '123'});

        // Assert
        expect(channel.memberCount, 0);
        expect(channel.members, isEmpty);
      });

      test('should handle multiple member removals', () {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });
        channel.handleEvent('pusher:member_added', {
          'user_id': '456',
          'user_info': {'name': 'Jane Smith'},
        });
        channel.handleEvent('pusher:member_added', {
          'user_id': '789',
          'user_info': {'name': 'Bob Johnson'},
        });
        expect(channel.memberCount, 3);

        // Act
        channel.handleEvent('pusher:member_removed', {'user_id': '123'});
        channel.handleEvent('pusher:member_removed', {'user_id': '789'});

        // Assert
        expect(channel.memberCount, 1);
        expect(channel.members.first.id, '456');
      });

      test('should handle member_removed for non-existent member gracefully', () {
        // Arrange
        final channel = createPresenceChannel();
        expect(channel.memberCount, 0);

        // Act - remove member that doesn't exist
        channel.handleEvent('pusher:member_removed', {'user_id': '999'});

        // Assert - should not cause errors
        expect(channel.memberCount, 0);
      });

      test('should handle member_removed with null user_id gracefully', () {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });

        // Act
        channel.handleEvent('pusher:member_removed', {});

        // Assert - member should still be present
        expect(channel.memberCount, 1);
      });

      test('should handle member_removed with null data gracefully', () {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });

        // Act
        channel.handleEvent('pusher:member_removed', null);

        // Assert - member should still be present
        expect(channel.memberCount, 1);
      });

      test('should emit member_removed event to stream', () async {
        // Arrange
        final channel = createPresenceChannel();
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });

        final events = <ChannelEvent>[];
        channel.on('pusher:member_removed').listen((event) {
          events.add(event);
        });

        final memberData = {'user_id': '123'};

        // Act
        channel.handleEvent('pusher:member_removed', memberData);

        // Wait for async stream processing
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(events.length, 1);
        expect(events.first.eventName, 'pusher:member_removed');
        expect(events.first.data, memberData);
      });
    });

    group('event forwarding', () {
      test('should forward non-presence events to parent class', () async {
        // Arrange
        final channel = createPresenceChannel();
        final events = <ChannelEvent>[];
        channel.on('custom-event').listen((event) {
          events.add(event);
        });

        final eventData = {'message': 'Hello, World!'};

        // Act
        channel.handleEvent('custom-event', eventData);

        // Wait for async stream processing
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(events.length, 1);
        expect(events.first.eventName, 'custom-event');
        expect(events.first.data, eventData);
      });

      test('should allow listening to all events via stream', () async {
        // Arrange
        final channel = createPresenceChannel();
        final events = <ChannelEvent>[];
        channel.stream.listen((event) {
          events.add(event);
        });

        // Act
        channel.handleEvent('pusher:member_added', {
          'user_id': '123',
          'user_info': {'name': 'John Doe'},
        });
        channel.handleEvent('custom-event', {'message': 'Hello'});
        channel.handleEvent('pusher:member_removed', {'user_id': '123'});

        // Wait for async stream processing
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(events.length, 3);
        expect(events[0].eventName, 'pusher:member_added');
        expect(events[1].eventName, 'custom-event');
        expect(events[2].eventName, 'pusher:member_removed');
      });
    });

    group('integration scenarios', () {
      test('should handle complete member lifecycle', () async {
        // Arrange
        final channel = createPresenceChannel();
        final allEvents = <ChannelEvent>[];
        channel.stream.listen((event) {
          allEvents.add(event);
        });

        // Initial subscription with members
        final subscriptionData = {
          'channel': testChannelName,
          'presence': {
            'hash': {
              '100': {'name': 'Alice'},
              '200': {'name': 'Bob'},
            },
          },
        };

        // Act - full lifecycle
        channel.handleSubscriptionSucceeded(subscriptionData);
        expect(channel.memberCount, 2);

        // New member joins
        channel.handleEvent('pusher:member_added', {
          'user_id': '300',
          'user_info': {'name': 'Charlie'},
        });
        expect(channel.memberCount, 3);

        // Member leaves
        channel.handleEvent('pusher:member_removed', {'user_id': '100'});
        expect(channel.memberCount, 2);

        // Another member joins
        channel.handleEvent('pusher:member_added', {
          'user_id': '400',
          'user_info': {'name': 'David'},
        });
        expect(channel.memberCount, 3);

        // Wait for async stream processing
        await Future.delayed(Duration(milliseconds: 10));

        // Assert final state
        expect(channel.members.any((m) => m.id == '100'), isFalse);
        expect(channel.members.any((m) => m.id == '200'), isTrue);
        expect(channel.members.any((m) => m.id == '300'), isTrue);
        expect(channel.members.any((m) => m.id == '400'), isTrue);
        expect(allEvents.length, 3); // member_added, member_removed, member_added
      });
    });
  });

  group('PresenceMember', () {
    test('should create member with id and info', () {
      final member = PresenceMember(id: '123', info: {'name': 'John Doe'});

      expect(member.id, '123');
      expect(member.info['name'], 'John Doe');
    });

    test('should create member from JSON', () {
      final json = {
        'id': '123',
        'info': {'name': 'John Doe', 'avatar': 'https://example.com/avatar.jpg'},
      };

      final member = PresenceMember.fromJson(json);

      expect(member.id, '123');
      expect(member.info['name'], 'John Doe');
      expect(member.info['avatar'], 'https://example.com/avatar.jpg');
    });

    test('should handle fromJson with missing info field', () {
      final json = {'id': '123'};

      final member = PresenceMember.fromJson(json);

      expect(member.id, '123');
      expect(member.info, isEmpty);
    });

    test('should handle fromJson with invalid info type', () {
      final json = {'id': '123', 'info': 'invalid'};

      final member = PresenceMember.fromJson(json);

      expect(member.id, '123');
      expect(member.info, isEmpty);
    });

    test('should convert member to JSON', () {
      final member = PresenceMember(id: '123', info: {'name': 'John Doe'});

      final json = member.toJson();

      expect(json['id'], '123');
      expect(json['info']['name'], 'John Doe');
    });

    test('should have correct toString representation', () {
      final member = PresenceMember(id: '123', info: {'name': 'John Doe'});

      expect(member.toString(), contains('123'));
      expect(member.toString(), contains('name'));
    });

    test('should compare members by id for equality', () {
      final member1 = PresenceMember(id: '123', info: {'name': 'John'});
      final member2 = PresenceMember(id: '123', info: {'name': 'Jane'});
      final member3 = PresenceMember(id: '456', info: {'name': 'John'});

      expect(member1 == member2, isTrue);
      expect(member1 == member3, isFalse);
    });

    test('should have consistent hashCode based on id', () {
      final member1 = PresenceMember(id: '123', info: {'name': 'John'});
      final member2 = PresenceMember(id: '123', info: {'name': 'Jane'});

      expect(member1.hashCode, member2.hashCode);
    });
  });
}
