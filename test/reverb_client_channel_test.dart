import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/src/client/reverb_client.dart';
import 'package:pusher_reverb_flutter/src/channels/channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient Channel Integration', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> streamController;
    late ReverbClient client;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      streamController = StreamController<dynamic>.broadcast();

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);

      client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'app-key', channelFactory: (_) => mockChannel);
    });

    tearDown(() {
      streamController.close();
      client.disconnect();
    });

    group('Channel Subscription', () {
      test('subscribes to a channel and returns Channel instance', () async {
        // Arrange
        await client.connect();

        // Act
        final channel = client.subscribeToChannel('test-channel');

        // Assert
        expect(channel, isA<Channel>());
        expect(channel.name, 'test-channel');
        expect(client.getChannel('test-channel'), channel);
        expect(client.subscribedChannels, contains(channel));
      });

      test('returns existing channel if already subscribed', () async {
        // Arrange
        await client.connect();
        final channel1 = client.subscribeToChannel('test-channel');

        // Act
        final channel2 = client.subscribeToChannel('test-channel');

        // Assert
        expect(channel1, same(channel2));
        expect(client.subscribedChannels.length, 1);
      });

      test('sends pusher:subscribe message when subscribing to channel', () async {
        // Arrange
        await client.connect();

        // Act
        client.subscribeToChannel('test-channel');

        // Assert
        final capturedMessages = verify(mockSink.add(captureAny)).captured;
        expect(capturedMessages.length, 1);
        final capturedMessage = capturedMessages.first as String;
        final message = jsonDecode(capturedMessage);
        expect(message['event'], 'pusher:subscribe');
        expect(message['data']['channel'], 'test-channel');
      });

      test('handles subscription_succeeded event', () async {
        // Arrange
        await client.connect();
        final channel = client.subscribeToChannel('test-channel');
        expect(channel.state, ChannelState.subscribing);

        // Act
        final message = jsonEncode({
          'event': 'pusher_internal:subscription_succeeded',
          'data': jsonEncode({'channel': 'test-channel'}),
        });
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(channel.state, ChannelState.subscribed);
      });
    });

    group('Channel Unsubscription', () {
      test('unsubscribes from a channel', () async {
        // Arrange
        await client.connect();
        client.subscribeToChannel('test-channel');
        clearInteractions(mockSink);

        // Act
        client.unsubscribeFromChannel('test-channel');

        // Assert
        final capturedMessages = verify(mockSink.add(captureAny)).captured;
        expect(capturedMessages.length, 1);
        final capturedMessage = capturedMessages.first as String;
        final message = jsonDecode(capturedMessage);
        expect(message['event'], 'pusher:unsubscribe');
        expect(message['data']['channel'], 'test-channel');
        expect(client.getChannel('test-channel'), isNull);
        expect(client.subscribedChannels, isEmpty);
      });

      test('handles unsubscription_succeeded event', () async {
        // Arrange
        await client.connect();
        final channel = client.subscribeToChannel('test-channel');
        final message = jsonEncode({
          'event': 'pusher_internal:subscription_succeeded',
          'data': jsonEncode({'channel': 'test-channel'}),
        });
        streamController.add(message);
        await Future.delayed(Duration.zero);
        expect(channel.state, ChannelState.subscribed);

        // Act
        final unsubMessage = jsonEncode({
          'event': 'pusher_internal:unsubscription_succeeded',
          'data': jsonEncode({'channel': 'test-channel'}),
        });
        streamController.add(unsubMessage);

        // Assert
        await Future.delayed(Duration.zero);
        expect(channel.state, ChannelState.unsubscribed);
      });

      test('does nothing when unsubscribing from non-existent channel', () async {
        // Arrange
        await client.connect();

        // Act & Assert
        expect(() => client.unsubscribeFromChannel('non-existent'), returnsNormally);
        verifyNever(mockSink.add(any));
      });
    });

    group('Channel Event Handling', () {
      test('forwards channel events to correct channel', () async {
        // Arrange
        await client.connect();
        final channel = client.subscribeToChannel('test-channel');
        String? receivedEvent;
        dynamic receivedData;
        channel.bind('test-event', (event, data) {
          receivedEvent = event;
          receivedData = data;
        });

        // Act
        final message = jsonEncode({'event': 'test-event', 'channel': 'test-channel', 'data': 'test-data'});
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(receivedEvent, 'test-event');
        expect(receivedData, 'test-data');
      });

      test('does not forward events to wrong channel', () async {
        // Arrange
        await client.connect();
        final channel1 = client.subscribeToChannel('channel-1');
        final channel2 = client.subscribeToChannel('channel-2');
        String? receivedEvent1;
        String? receivedEvent2;
        channel1.bind('test-event', (event, data) {
          receivedEvent1 = event;
        });
        channel2.bind('test-event', (event, data) {
          receivedEvent2 = event;
        });

        // Act
        final message = jsonEncode({'event': 'test-event', 'channel': 'channel-1', 'data': 'test-data'});
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(receivedEvent1, 'test-event');
        expect(receivedEvent2, isNull);
      });

      test('ignores events without channel information', () async {
        // Arrange
        await client.connect();
        final channel = client.subscribeToChannel('test-channel');
        String? receivedEvent;
        channel.bind('test-event', (event, data) {
          receivedEvent = event;
        });

        // Act
        final message = jsonEncode({'event': 'test-event', 'data': 'test-data'});
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(receivedEvent, isNull);
      });
    });

    group('Channel Management', () {
      test('returns null for non-existent channel', () {
        // Act & Assert
        expect(client.getChannel('non-existent'), isNull);
      });

      test('returns list of all subscribed channels', () async {
        // Arrange
        await client.connect();
        final channel1 = client.subscribeToChannel('channel-1');
        final channel2 = client.subscribeToChannel('channel-2');

        // Act
        final channels = client.subscribedChannels;

        // Assert
        expect(channels.length, 2);
        expect(channels, contains(channel1));
        expect(channels, contains(channel2));
      });

      test('clears all channels on disconnect', () async {
        // Arrange
        await client.connect();
        client.subscribeToChannel('channel-1');
        client.subscribeToChannel('channel-2');
        expect(client.subscribedChannels.length, 2);

        // Act
        client.disconnect();

        // Assert
        expect(client.subscribedChannels, isEmpty);
      });
    });

    group('Multiple Channels', () {
      test('manages multiple channels independently', () async {
        // Arrange
        await client.connect();
        client.subscribeToChannel('channel-1');
        final channel2 = client.subscribeToChannel('channel-2');

        // Act
        client.unsubscribeFromChannel('channel-1');

        // Assert
        expect(client.getChannel('channel-1'), isNull);
        expect(client.getChannel('channel-2'), channel2);
        expect(client.subscribedChannels.length, 1);
        expect(client.subscribedChannels, contains(channel2));
      });

      test('handles events for multiple channels', () async {
        // Arrange
        await client.connect();
        final channel1 = client.subscribeToChannel('channel-1');
        final channel2 = client.subscribeToChannel('channel-2');
        final events1 = <String>[];
        final events2 = <String>[];
        channel1.bind('event-1', (event, data) => events1.add(event));
        channel2.bind('event-2', (event, data) => events2.add(event));

        // Act
        final message1 = jsonEncode({'event': 'event-1', 'channel': 'channel-1', 'data': 'data1'});
        final message2 = jsonEncode({'event': 'event-2', 'channel': 'channel-2', 'data': 'data2'});
        streamController.add(message1);
        streamController.add(message2);

        // Assert
        await Future.delayed(Duration.zero);
        expect(events1, contains('event-1'));
        expect(events2, contains('event-2'));
      });
    });
  });
}
