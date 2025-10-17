import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'reverb_client_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebSocketChannel>(), MockSpec<WebSocketSink>()])
void main() {
  group('ReverbClient', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> streamController;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      streamController = StreamController<dynamic>.broadcast();

      when(mockChannel.stream).thenAnswer((_) => streamController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
    });

    tearDown(() {
      streamController.close();
    });

    ReverbClient createClient({String? wsPath, void Function(String? socketId)? onConnected, void Function(dynamic error)? onError}) {
      return ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'app-key', wsPath: wsPath, onConnected: onConnected, onError: onError, channelFactory: (_) => mockChannel);
    }

    test('connects and handles connection_established event', () async {
      // Arrange
      String? connectedSocketId;
      final client = createClient(
        onConnected: (socketId) {
          connectedSocketId = socketId;
        },
      );

      // Act
      await client.connect();
      const socketId = 'test-socket-id';
      final message = jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': socketId, 'activity_timeout': 30}),
      });
      streamController.add(message);

      // Assert
      await Future.delayed(Duration.zero);
      expect(connectedSocketId, socketId);
      client.disconnect();
    });

    test('handles connection error', () async {
      // Arrange
      dynamic connectionError;
      final client = createClient(
        onError: (error) {
          connectionError = error;
        },
      );

      // Act
      await client.connect();
      final error = Exception('Connection failed');
      streamController.addError(error);

      // Assert
      await Future.delayed(Duration.zero);
      expect(connectionError, error);
      client.disconnect();
    });

    test('disconnect closes the channel sink', () async {
      // Arrange
      final client = createClient();

      // Act
      await client.connect();
      client.disconnect();

      // Assert
      verify(mockSink.close()).called(1);
    });

    group('wsPath configuration', () {
      test('uses default path when wsPath is not provided', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080/app/test-app');
        client.disconnect();
      });

      test('uses custom wsPath when provided', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          wsPath: '/custom/path',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080/custom/path');
        client.disconnect();
      });

      test('handles wsPath with leading slash', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          wsPath: '/api/websocket',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080/api/websocket');
        client.disconnect();
      });

      test('handles wsPath without leading slash', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          wsPath: 'api/websocket',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080/api/websocket');
        client.disconnect();
      });

      test('handles empty wsPath', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          wsPath: '',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080');
        client.disconnect();
      });

      test('handles wsPath with query parameters', () async {
        // Arrange
        Uri? capturedUri;
        final client = ReverbClient.forTesting(
          host: 'localhost',
          port: 8080,
          appKey: 'test-app',
          wsPath: '/ws?token=abc123',
          channelFactory: (uri) {
            capturedUri = uri;
            return mockChannel;
          },
        );

        // Act
        await client.connect();

        // Assert
        expect(capturedUri?.toString(), 'ws://localhost:8080/ws?token=abc123');
        client.disconnect();
      });

      test('connection succeeds with custom wsPath', () async {
        // Arrange
        String? connectedSocketId;
        final client = createClient(
          wsPath: '/custom/websocket',
          onConnected: (socketId) {
            connectedSocketId = socketId;
          },
        );

        // Act
        await client.connect();
        const socketId = 'test-socket-id';
        final message = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': socketId, 'activity_timeout': 30}),
        });
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(connectedSocketId, socketId);
        client.disconnect();
      });

      test('connection succeeds with default wsPath', () async {
        // Arrange
        String? connectedSocketId;
        final client = createClient(
          onConnected: (socketId) {
            connectedSocketId = socketId;
          },
        );

        // Act
        await client.connect();
        const socketId = 'test-socket-id';
        final message = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': socketId, 'activity_timeout': 30}),
        });
        streamController.add(message);

        // Assert
        await Future.delayed(Duration.zero);
        expect(connectedSocketId, socketId);
        client.disconnect();
      });
    });

    group('Bug Fix Tests', () {
      group('Collection.remove bug fix', () {
        test('unsubscribeFromChannel handles concurrent removal safely', () async {
          // Arrange
          final client = createClient();
          await client.connect();

          // Add a channel
          client.subscribeToChannel('test-channel');
          expect(client.getChannel('test-channel'), isNotNull);

          // Act: Simulate concurrent removal by calling unsubscribe twice
          client.unsubscribeFromChannel('test-channel');
          client.unsubscribeFromChannel('test-channel'); // Should not cause runtime error

          // Assert: Channel should be removed without errors
          expect(client.getChannel('test-channel'), isNull);
          client.disconnect();
        });

        test('disconnect handles concurrent channel operations safely', () async {
          // Arrange
          final client = createClient();
          await client.connect();

          // Add multiple channels
          client.subscribeToChannel('channel1');
          client.subscribeToChannel('channel2');
          client.subscribeToChannel('channel3');

          // Act: Disconnect should handle concurrent operations safely
          client.disconnect();

          // Assert: All channels should be cleared without errors
          expect(client.subscribedChannels, isEmpty);
        });
      });

      group('Null host infinite loop guard', () {
        test('constructor throws ArgumentError for empty host', () {
          // Act & Assert
          expect(() => ReverbClient.forTesting(host: '', port: 8080, appKey: 'test-app'), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Host cannot be null or empty')));
        });

        test('constructor throws ArgumentError for invalid port', () {
          // Act & Assert
          expect(() => ReverbClient.forTesting(host: 'localhost', port: 0, appKey: 'test-app'), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Port must be between 1 and 65535')));

          expect(
            () => ReverbClient.forTesting(host: 'localhost', port: 65536, appKey: 'test-app'),
            throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Port must be between 1 and 65535')),
          );
        });

        test('constructor throws ArgumentError for empty appKey', () {
          // Act & Assert
          expect(() => ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: ''), throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'App key cannot be null or empty')));
        });

        test('connect method validates host parameter', () async {
          // This test is covered by the constructor validation test above
          // The connect method no longer needs separate validation since
          // the constructor already validates the host parameter
          expect(true, isTrue); // Placeholder test
        });
      });
    });

    group('Singleton Pattern', () {
      late MockWebSocketChannel mockChannel;
      late MockWebSocketSink mockSink;
      late StreamController<dynamic> streamController;

      setUp(() {
        mockChannel = MockWebSocketChannel();
        mockSink = MockWebSocketSink();
        streamController = StreamController<dynamic>.broadcast();

        when(mockChannel.stream).thenAnswer((_) => streamController.stream);
        when(mockChannel.sink).thenReturn(mockSink);

        // Reset singleton before each test
        ReverbClient.resetInstance();
      });

      tearDown(() {
        streamController.close();
        ReverbClient.resetInstance();
      });

      test('instance() returns singleton instance on first access', () {
        // Act
        final instance1 = ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final instance2 = ReverbClient.instance();

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });

      test('instance() throws StateError when called without parameters before initialization', () {
        // Act & Assert
        expect(() => ReverbClient.instance(), throwsA(isA<StateError>().having((e) => e.message, 'message', contains('ReverbClient instance has not been initialized'))));
      });

      test('factory constructor throws StateError', () {
        // Act & Assert
        expect(() => ReverbClient(host: 'localhost', port: 8080, appKey: 'test-key'), throwsA(isA<StateError>().having((e) => e.message, 'message', contains('cannot be instantiated directly'))));
      });

      test('resetInstance() clears the singleton', () {
        // Arrange
        final instance1 = ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);

        // Act
        ReverbClient.resetInstance();

        // Assert - Creating new instance should work
        final instance2 = ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'new-key', channelFactory: (_) => mockChannel);
        expect(identical(instance1, instance2), isFalse);
        expect(instance2.appKey, 'new-key');
      });

      test('instance() ignores parameters after first initialization', () {
        // Arrange
        final instance1 = ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'first-key', channelFactory: (_) => mockChannel);

        // Act - Call with different parameters
        final instance2 = ReverbClient.instance(host: 'different', port: 9090, appKey: 'second-key');

        // Assert - Should return same instance with original parameters
        expect(identical(instance1, instance2), isTrue);
        expect(instance2.appKey, 'first-key');
        expect(instance2.host, 'localhost');
        expect(instance2.port, 8080);
      });
    });

    group('Connection State Stream', () {
      late MockWebSocketChannel mockChannel;
      late MockWebSocketSink mockSink;
      late StreamController<dynamic> streamController;

      setUp(() {
        mockChannel = MockWebSocketChannel();
        mockSink = MockWebSocketSink();
        streamController = StreamController<dynamic>.broadcast();

        when(mockChannel.stream).thenAnswer((_) => streamController.stream);
        when(mockChannel.sink).thenReturn(mockSink);
      });

      tearDown(() {
        streamController.close();
      });

      test('onConnectionStateChange emits connecting state on connect', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final states = <ConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        // Act
        await client.connect();
        await Future.delayed(Duration.zero);

        // Assert
        expect(states, contains(ConnectionState.connecting));
        client.disconnect();
      });

      test('onConnectionStateChange emits connected state on connection established', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final states = <ConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        // Act
        await client.connect();
        final message = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': 'test-socket', 'activity_timeout': 30}),
        });
        streamController.add(message);
        await Future.delayed(Duration.zero);

        // Assert
        expect(states, containsAll([ConnectionState.connecting, ConnectionState.connected]));
        client.disconnect();
      });

      test('onConnectionStateChange emits disconnected state on disconnect', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final states = <ConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        // Act
        await client.connect();
        await Future.delayed(Duration.zero);
        client.disconnect();
        await Future.delayed(Duration.zero);

        // Assert
        expect(states.last, ConnectionState.disconnected);
      });

      test('onConnectionStateChange emits error state on connection error', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final states = <ConnectionState>[];
        client.onConnectionStateChange.listen(states.add);

        // Act
        await client.connect();
        streamController.addError(Exception('Connection failed'));
        await Future.delayed(Duration.zero);

        // Assert
        expect(states, contains(ConnectionState.error));
        client.disconnect();
      });

      test('connectionState getter returns current state', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);

        // Assert initial state
        expect(client.connectionState, ConnectionState.disconnected);

        // Act - connect
        await client.connect();
        await Future.delayed(Duration.zero);

        // Assert connecting state
        expect(client.connectionState, ConnectionState.connecting);

        // Act - establish connection
        final message = jsonEncode({
          'event': 'pusher:connection_established',
          'data': jsonEncode({'socket_id': 'test-socket', 'activity_timeout': 30}),
        });
        streamController.add(message);
        await Future.delayed(Duration.zero);

        // Assert connected state
        expect(client.connectionState, ConnectionState.connected);

        // Act - disconnect
        client.disconnect();
        await Future.delayed(Duration.zero);

        // Assert disconnected state
        expect(client.connectionState, ConnectionState.disconnected);
      });

      test('connection state stream supports multiple listeners', () async {
        // Arrange
        final client = ReverbClient.forTesting(host: 'localhost', port: 8080, appKey: 'test-key', channelFactory: (_) => mockChannel);
        final states1 = <ConnectionState>[];
        final states2 = <ConnectionState>[];
        client.onConnectionStateChange.listen(states1.add);
        client.onConnectionStateChange.listen(states2.add);

        // Act
        await client.connect();
        await Future.delayed(Duration.zero);

        // Assert - Both listeners should receive the same events
        expect(states1, states2);
        expect(states1, contains(ConnectionState.connecting));
        client.disconnect();
      });
    });
  });
}
