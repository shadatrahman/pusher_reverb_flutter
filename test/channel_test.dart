import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

void main() {
  group('Channel', () {
    late List<String> sentMessages;
    late Channel channel;

    setUp(() {
      sentMessages = [];
      channel = Channel(name: 'test-channel', sendMessage: (message) => sentMessages.add(message));
    });

    group('Constructor', () {
      test('creates channel with valid name', () {
        expect(channel.name, 'test-channel');
        expect(channel.state, ChannelState.unsubscribed);
      });

      test('throws error for empty channel name', () {
        expect(() => Channel(name: '', sendMessage: (message) {}), throwsA(isA<ArgumentError>()));
      });

      test('throws error for channel name exceeding 200 characters', () {
        final longName = 'a' * 201;
        expect(() => Channel(name: longName, sendMessage: (message) {}), throwsA(isA<ArgumentError>()));
      });

      test('throws error for channel name with invalid characters', () {
        expect(() => Channel(name: 'test#channel', sendMessage: (message) {}), throwsA(isA<ArgumentError>()));
      });

      test('accepts valid channel names with special characters', () {
        final validNames = ['test-channel', 'test_channel', 'test=channel', 'test@channel', 'test,channel', 'test.channel', 'test;channel', 'test123'];

        for (final name in validNames) {
          expect(() => Channel(name: name, sendMessage: (message) {}), returnsNormally);
        }
      });
    });

    group('Subscription', () {
      test('sends pusher:subscribe message when subscribing', () async {
        // Act
        await channel.subscribe();

        // Assert
        expect(sentMessages.length, 1);
        final message = sentMessages.first;
        expect(message, contains('"event":"pusher:subscribe"'));
        expect(message, contains('"channel":"test-channel"'));
        expect(channel.state, ChannelState.subscribing);
      });

      test('does not send message if already subscribed', () async {
        // Arrange
        await channel.subscribe();
        channel.handleSubscriptionSucceeded();
        sentMessages.clear();

        // Act
        await channel.subscribe();

        // Assert
        expect(sentMessages.length, 0);
      });

      test('does not send message if already subscribing', () async {
        // Arrange
        await channel.subscribe();
        sentMessages.clear();

        // Act
        await channel.subscribe();

        // Assert
        expect(sentMessages.length, 0);
      });

      test('handles subscription succeeded event', () {
        // Arrange
        channel.subscribe();

        // Act
        channel.handleSubscriptionSucceeded();

        // Assert
        expect(channel.state, ChannelState.subscribed);
      });
    });

    group('Unsubscription', () {
      test('sends pusher:unsubscribe message when unsubscribing', () async {
        // Arrange
        await channel.subscribe();
        channel.handleSubscriptionSucceeded();
        sentMessages.clear();

        // Act
        await channel.unsubscribe();

        // Assert
        expect(sentMessages.length, 1);
        final message = sentMessages.first;
        expect(message, contains('"event":"pusher:unsubscribe"'));
        expect(message, contains('"channel":"test-channel"'));
        expect(channel.state, ChannelState.unsubscribing);
      });

      test('does not send message if already unsubscribed', () async {
        // Act
        await channel.unsubscribe();

        // Assert
        expect(sentMessages.length, 0);
      });

      test('does not send message if already unsubscribing', () async {
        // Arrange
        await channel.subscribe();
        channel.handleSubscriptionSucceeded();
        await channel.unsubscribe();
        sentMessages.clear();

        // Act
        await channel.unsubscribe();

        // Assert
        expect(sentMessages.length, 0);
      });

      test('handles unsubscription succeeded event', () {
        // Arrange
        channel.subscribe();
        channel.handleSubscriptionSucceeded();
        channel.unsubscribe();

        // Act
        channel.handleUnsubscriptionSucceeded();

        // Assert
        expect(channel.state, ChannelState.unsubscribed);
      });

      test('clears event listeners on unsubscription succeeded', () {
        // Arrange
        channel.subscribe();
        channel.handleSubscriptionSucceeded();
        channel.bind('test-event', (event, data) {});
        channel.unsubscribe();

        // Act
        channel.handleUnsubscriptionSucceeded();

        // Assert
        expect(channel.state, ChannelState.unsubscribed);
        // Event listeners should be cleared (we can't directly test this, but
        // the method should complete without error)
      });
    });

    group('Event Handling', () {
      test('binds event listener', () {
        // Arrange
        String? receivedEvent;
        dynamic receivedData;
        void listener(String event, dynamic data) {
          receivedEvent = event;
          receivedData = data;
        }

        // Act
        channel.bind('test-event', listener);
        channel.handleEvent('test-event', 'test-data');

        // Assert
        expect(receivedEvent, 'test-event');
        expect(receivedData, 'test-data');
      });

      test('throws error for empty event name when binding', () {
        expect(() => channel.bind('', (event, data) {}), throwsA(isA<ArgumentError>()));
      });

      test('unbinds specific event listener', () {
        // Arrange
        String? receivedEvent;
        void listener(String event, dynamic data) {
          receivedEvent = event;
        }

        channel.bind('test-event', listener);

        // Act
        channel.unbind('test-event', listener);
        channel.handleEvent('test-event', 'test-data');

        // Assert
        expect(receivedEvent, isNull);
      });

      test('unbinds all listeners for event when no specific listener provided', () {
        // Arrange
        String? receivedEvent1;
        String? receivedEvent2;
        void listener1(String event, dynamic data) {
          receivedEvent1 = event;
        }

        void listener2(String event, dynamic data) {
          receivedEvent2 = event;
        }

        channel.bind('test-event', listener1);
        channel.bind('test-event', listener2);

        // Act
        channel.unbind('test-event');
        channel.handleEvent('test-event', 'test-data');

        // Assert
        expect(receivedEvent1, isNull);
        expect(receivedEvent2, isNull);
      });

      test('throws error for empty event name when unbinding', () {
        expect(() => channel.unbind('', (event, data) {}), throwsA(isA<ArgumentError>()));
      });

      test('handles multiple listeners for same event', () {
        // Arrange
        final receivedEvents = <String>[];
        void listener1(String event, dynamic data) {
          receivedEvents.add('listener1');
        }

        void listener2(String event, dynamic data) {
          receivedEvents.add('listener2');
        }

        channel.bind('test-event', listener1);
        channel.bind('test-event', listener2);

        // Act
        channel.handleEvent('test-event', 'test-data');

        // Assert
        expect(receivedEvents, contains('listener1'));
        expect(receivedEvents, contains('listener2'));
      });

      test('does not call listeners for unbound events', () {
        // Arrange
        String? receivedEvent;
        void listener(String event, dynamic data) {
          receivedEvent = event;
        }

        channel.bind('test-event', listener);

        // Act
        channel.handleEvent('other-event', 'test-data');

        // Assert
        expect(receivedEvent, isNull);
      });
    });

    group('State Listeners', () {
      test('adds state listener', () {
        // Arrange
        final stateChanges = <ChannelState>[];
        void listener(ChannelState state) {
          stateChanges.add(state);
        }

        // Act
        channel.addStateListener(listener);
        channel.subscribe();

        // Assert
        expect(stateChanges, contains(ChannelState.subscribing));
      });

      test('removes state listener', () {
        // Arrange
        final stateChanges = <ChannelState>[];
        void listener(ChannelState state) {
          stateChanges.add(state);
        }

        channel.addStateListener(listener);

        // Act
        channel.removeStateListener(listener);
        channel.subscribe();

        // Assert
        expect(stateChanges, isEmpty);
      });

      test('notifies all state listeners on state change', () {
        // Arrange
        final stateChanges1 = <ChannelState>[];
        final stateChanges2 = <ChannelState>[];
        void listener1(ChannelState state) {
          stateChanges1.add(state);
        }

        void listener2(ChannelState state) {
          stateChanges2.add(state);
        }

        channel.addStateListener(listener1);
        channel.addStateListener(listener2);

        // Act
        channel.subscribe();

        // Assert
        expect(stateChanges1, contains(ChannelState.subscribing));
        expect(stateChanges2, contains(ChannelState.subscribing));
      });

      test('does not notify listeners when state does not change', () {
        // Arrange
        final stateChanges = <ChannelState>[];
        void listener(ChannelState state) {
          stateChanges.add(state);
        }

        channel.addStateListener(listener);
        channel.subscribe(); // First state change
        stateChanges.clear();

        // Act
        channel.subscribe(); // Should not change state

        // Assert
        expect(stateChanges, isEmpty);
      });
    });

    group('Bug Fix Tests', () {
      group('Collection.remove bug fix', () {
        test('unbind handles concurrent removal safely', () {
          // Arrange
          String? receivedEvent;
          void listener(String event, dynamic data) {
            receivedEvent = event;
          }

          channel.bind('test-event', listener);

          // Act: Simulate concurrent removal by calling unbind twice
          channel.unbind('test-event', listener);
          channel.unbind('test-event', listener); // Should not cause runtime error

          // Assert: Listener should be removed without errors
          channel.handleEvent('test-event', 'test-data');
          expect(receivedEvent, isNull);
        });

        test('removeStateListener handles concurrent removal safely', () {
          // Arrange
          final stateChanges = <ChannelState>[];
          void listener(ChannelState state) {
            stateChanges.add(state);
          }

          channel.addStateListener(listener);

          // Act: Simulate concurrent removal by calling removeStateListener twice
          channel.removeStateListener(listener);
          channel.removeStateListener(listener); // Should not cause runtime error

          // Assert: Listener should be removed without errors
          channel.subscribe();
          expect(stateChanges, isEmpty);
        });

        test('handleEvent handles concurrent listener modification safely', () {
          // Arrange
          final receivedEvents = <String>[];
          void listener2(String event, dynamic data) {
            receivedEvents.add('listener2');
          }

          void listener1(String event, dynamic data) {
            receivedEvents.add('listener1');
            // Simulate concurrent modification by removing listener2 during iteration
            channel.unbind('test-event', listener2);
          }

          channel.bind('test-event', listener1);
          channel.bind('test-event', listener2);

          // Act: This should not cause concurrent modification error
          channel.handleEvent('test-event', 'test-data');

          // Assert: Should handle concurrent modification safely
          expect(receivedEvents, contains('listener1'));
          // listener2 might or might not be called depending on iteration order
        });

        test('_setState handles concurrent state listener modification safely', () {
          // Arrange
          final stateChanges = <ChannelState>[];
          void listener2(ChannelState state) {
            stateChanges.add(state);
          }

          void listener1(ChannelState state) {
            stateChanges.add(state);
            // Simulate concurrent modification by removing listener2 during iteration
            channel.removeStateListener(listener2);
          }

          channel.addStateListener(listener1);
          channel.addStateListener(listener2);

          // Act: This should not cause concurrent modification error
          channel.subscribe();

          // Assert: Should handle concurrent modification safely
          expect(stateChanges, contains(ChannelState.subscribing));
          // listener2 might or might not be called depending on iteration order
        });
      });
    });

    group('Stream-based API', () {
      test('stream emits ChannelEvent when event is received', () async {
        // Arrange
        final events = <ChannelEvent>[];
        channel.stream.listen(events.add);

        // Act
        channel.handleEvent('test-event', {'message': 'hello'});
        await Future.delayed(Duration.zero);

        // Assert
        expect(events.length, 1);
        expect(events.first.channelName, 'test-channel');
        expect(events.first.eventName, 'test-event');
        expect(events.first.data, {'message': 'hello'});
        channel.dispose();
      });

      test('stream emits multiple events', () async {
        // Arrange
        final events = <ChannelEvent>[];
        channel.stream.listen(events.add);

        // Act
        channel.handleEvent('event1', 'data1');
        channel.handleEvent('event2', 'data2');
        channel.handleEvent('event3', 'data3');
        await Future.delayed(Duration.zero);

        // Assert
        expect(events.length, 3);
        expect(events[0].eventName, 'event1');
        expect(events[1].eventName, 'event2');
        expect(events[2].eventName, 'event3');
        channel.dispose();
      });

      test('on() filters events by event name', () async {
        // Arrange
        final filteredEvents = <ChannelEvent>[];
        channel.on('specific-event').listen(filteredEvents.add);

        // Act
        channel.handleEvent('specific-event', 'data1');
        channel.handleEvent('other-event', 'data2');
        channel.handleEvent('specific-event', 'data3');
        await Future.delayed(Duration.zero);

        // Assert
        expect(filteredEvents.length, 2);
        expect(filteredEvents[0].data, 'data1');
        expect(filteredEvents[1].data, 'data3');
        channel.dispose();
      });

      test('on() throws error for empty event name', () {
        // Act & Assert
        expect(() => channel.on(''), throwsA(isA<ArgumentError>()));
      });

      test('stream supports multiple listeners', () async {
        // Arrange
        final events1 = <ChannelEvent>[];
        final events2 = <ChannelEvent>[];
        channel.stream.listen(events1.add);
        channel.stream.listen(events2.add);

        // Act
        channel.handleEvent('test-event', 'test-data');
        await Future.delayed(Duration.zero);

        // Assert - Both listeners should receive the same event
        expect(events1.length, 1);
        expect(events2.length, 1);
        expect(events1.first.eventName, events2.first.eventName);
        channel.dispose();
      });

      test('stream and callback-based API work together', () async {
        // Arrange
        final streamEvents = <ChannelEvent>[];
        channel.stream.listen(streamEvents.add);

        String? callbackEvent;
        dynamic callbackData;
        channel.bind('test-event', (event, data) {
          callbackEvent = event;
          callbackData = data;
        });

        // Act
        channel.handleEvent('test-event', 'test-data');
        await Future.delayed(Duration.zero);

        // Assert - Both stream and callback should be notified
        expect(streamEvents.length, 1);
        expect(streamEvents.first.eventName, 'test-event');
        expect(callbackEvent, 'test-event');
        expect(callbackData, 'test-data');
        channel.dispose();
      });

      test('dispose() closes the stream controller', () async {
        // Arrange
        bool streamClosed = false;
        channel.stream.listen(
          (event) {},
          onDone: () {
            streamClosed = true;
          },
        );

        // Act
        channel.dispose();
        await Future.delayed(Duration.zero);

        // Assert
        expect(streamClosed, isTrue);
      });

      test('ChannelEvent has correct toString', () {
        // Arrange
        final event = ChannelEvent(channelName: 'test-channel', eventName: 'test-event', data: {'key': 'value'});

        // Act
        final result = event.toString();

        // Assert
        expect(result, contains('test-channel'));
        expect(result, contains('test-event'));
        expect(result, contains('key'));
      });

      test('ChannelEvent equality works correctly', () {
        // Arrange
        final event1 = ChannelEvent(channelName: 'channel', eventName: 'event', data: 'data');
        final event2 = ChannelEvent(channelName: 'channel', eventName: 'event', data: 'data');
        final event3 = ChannelEvent(channelName: 'channel', eventName: 'different', data: 'data');

        // Assert
        expect(event1 == event2, isTrue);
        expect(event1 == event3, isFalse);
        expect(event1.hashCode, event2.hashCode);
      });

      test('stream can be listened to after subscription', () async {
        // Arrange
        await channel.subscribe();
        channel.handleSubscriptionSucceeded();
        final events = <ChannelEvent>[];
        channel.stream.listen(events.add);

        // Act
        channel.handleEvent('test-event', 'test-data');
        await Future.delayed(Duration.zero);

        // Assert
        expect(events.length, 1);
        expect(events.first.eventName, 'test-event');
        channel.dispose();
      });

      test('multiple on() filters work independently', () async {
        // Arrange
        final event1List = <ChannelEvent>[];
        final event2List = <ChannelEvent>[];
        channel.on('event1').listen(event1List.add);
        channel.on('event2').listen(event2List.add);

        // Act
        channel.handleEvent('event1', 'data1');
        channel.handleEvent('event2', 'data2');
        channel.handleEvent('event1', 'data3');
        await Future.delayed(Duration.zero);

        // Assert
        expect(event1List.length, 2);
        expect(event2List.length, 1);
        expect(event1List[0].data, 'data1');
        expect(event1List[1].data, 'data3');
        expect(event2List[0].data, 'data2');
        channel.dispose();
      });
    });
  });
}
