# Pusher Reverb Flutter

A Flutter/Dart client for Laravel Reverb, providing real-time WebSocket communication using the Pusher Protocol. This package offers a native Dart implementation optimized for Flutter applications, enabling seamless bidirectional communication with Laravel backends.

## Features

- 🔌 **WebSocket Connection** - Connect to Laravel Reverb servers with automatic reconnection
- 📡 **Public Channels** - Subscribe to and receive events on public channels
- 🔐 **Private Channels** - Secure private channel authentication with custom authorizers
- 🎯 **Singleton Pattern** - Convenient singleton access with `ReverbClient.instance()`
- 🌊 **Stream-Based API** - Idiomatic Dart streams for connection state and channel events
- 🔄 **Backward Compatible** - Traditional callback-based API still supported
- 🛠️ **Custom Configuration** - Support for custom WebSocket paths and authentication
- 📊 **Connection State Monitoring** - Real-time connection state updates via streams
- ✅ **Well-Tested** - Over 90% test coverage with comprehensive unit and integration tests

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  pusher_reverb_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Getting Started

### Prerequisites

- Flutter SDK >=1.17.0
- Dart SDK ^3.9.2
- Laravel application with Reverb server running

### Basic Setup

Import the package in your Dart code:

```dart
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
```

## Usage

### Example 1: Basic Connection to Reverb Server Using Singleton

```dart
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

// Initialize the client (first time)
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
);

// Connect to the server
await client.connect();

// Access singleton elsewhere in your app
final sameClient = ReverbClient.instance();
```

### Example 2: Subscribe to a Public Channel with Callback-Based API

```dart
// Subscribe to a public channel
final channel = client.channel('notifications');
await channel.subscribe();

// Listen for events using callbacks
channel.bind('new-message', (data) {
  print('Received message: $data');
});

// Unbind specific event
channel.unbind('new-message');

// Unsubscribe from channel
await channel.unsubscribe();
```

### Example 3: Subscribe to a Public Channel with Stream-Based API

```dart
// Subscribe to a channel
final channel = client.channel('updates');
await channel.subscribe();

// Listen to all events via stream
channel.stream.listen((event) {
  print('Event: ${event.eventName}, Data: ${event.data}');
});

// Listen to specific events via stream
channel.stream
  .where((event) => event.eventName == 'user-joined')
  .listen((event) {
    print('User joined: ${event.data}');
  });
```

### Example 4: Subscribe to a Private Channel with Authentication

```dart
// Define an authorizer function for authentication
Future<Map<String, String>> myAuthorizer(String channelName, String socketId) async {
  // Return authentication headers (e.g., Bearer token)
  return {
    'Authorization': 'Bearer YOUR_AUTH_TOKEN',
  };
}

// Initialize client with authorizer
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
  authorizer: myAuthorizer,
  authEndpoint: 'http://localhost:8000/broadcasting/auth',
);

await client.connect();

// Subscribe to private channel
final privateChannel = client.privateChannel('private-user-123');
await privateChannel.subscribe();

// Listen for events
privateChannel.bind('private-event', (data) {
  print('Private data: $data');
});
```

### Example 5: Using StreamBuilder in Flutter Widgets

```dart
import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

class RealtimeWidget extends StatefulWidget {
  @override
  _RealtimeWidgetState createState() => _RealtimeWidgetState();
}

class _RealtimeWidgetState extends State<RealtimeWidget> {
  late ReverbClient client;
  late Channel channel;

  @override
  void initState() {
    super.initState();
    client = ReverbClient.instance(
      host: 'localhost',
      port: 8080,
      appKey: 'your-app-key',
    );
    client.connect();

    channel = client.channel('notifications');
    channel.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Realtime Updates')),
      body: Column(
        children: [
          // Monitor connection state
          StreamBuilder<ConnectionState>(
            stream: client.onConnectionStateChange,
            builder: (context, snapshot) {
              final state = snapshot.data ?? ConnectionState.disconnected;
              return Container(
                padding: EdgeInsets.all(8),
                color: state == ConnectionState.connected
                    ? Colors.green
                    : Colors.red,
                child: Text(
                  'Status: ${state.toString().split('.').last}',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),

          // Display channel events
          Expanded(
            child: StreamBuilder<ChannelEvent>(
              stream: channel.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Waiting for events...'));
                }

                final event = snapshot.data!;
                return ListTile(
                  title: Text(event.eventName),
                  subtitle: Text(event.data.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    channel.unsubscribe();
    client.disconnect();
    super.dispose();
  }
}
```

## Configuration

### ReverbClient Options

The `ReverbClient.instance()` method accepts the following parameters:

| Parameter      | Type         | Required         | Default                | Description                                      |
| -------------- | ------------ | ---------------- | ---------------------- | ------------------------------------------------ |
| `host`         | `String`     | Yes (first call) | -                      | Reverb server hostname                           |
| `port`         | `int`        | Yes (first call) | -                      | Reverb server port                               |
| `appKey`       | `String`     | Yes (first call) | -                      | Application key for authentication               |
| `wsPath`       | `String`     | No               | `/`                    | Custom WebSocket path (e.g., `/app/websocket`)   |
| `authorizer`   | `Authorizer` | No               | `null`                 | Custom authorizer function for private channels  |
| `authEndpoint` | `String`     | No               | `'/broadcasting/auth'` | Authentication endpoint URL for private channels |

### Authorizer Function

The authorizer function is used to provide authentication headers for private channel subscriptions:

```dart
typedef Authorizer = Future<Map<String, String>> Function(
  String channelName,
  String socketId,
);
```

Example implementation:

```dart
Future<Map<String, String>> customAuthorizer(String channelName, String socketId) async {
  // Fetch your auth token from secure storage
  final token = await getAuthToken();

  return {
    'Authorization': 'Bearer $token',
    'X-Custom-Header': 'custom-value',
  };
}
```

## API Reference

### ReverbClient

- `ReverbClient.instance(...)` - Get or create singleton instance
- `connect()` - Connect to the Reverb server
- `disconnect()` - Disconnect from the server
- `channel(String name)` - Subscribe to a public channel
- `privateChannel(String name)` - Subscribe to a private channel
- `onConnectionStateChange` - Stream of connection state changes
- `socketId` - Get the current socket ID

### Channel

- `subscribe()` - Subscribe to the channel
- `unsubscribe()` - Unsubscribe from the channel
- `bind(String event, Function callback)` - Listen for specific event (callback API)
- `unbind(String event)` - Stop listening for event (callback API)
- `stream` - Stream of all channel events (Stream API)
- `state` - Current channel state
- `onStateChange` - Stream of channel state changes

### PrivateChannel

Extends `Channel` with authentication support. All `Channel` methods are available.

### ConnectionState

Enum representing connection states:

- `disconnected` - Not connected
- `connecting` - Connection in progress
- `connected` - Successfully connected
- `disconnecting` - Disconnection in progress

### ChannelState

Enum representing channel subscription states:

- `unsubscribed` - Not subscribed
- `subscribing` - Subscription in progress
- `subscribed` - Successfully subscribed

## Testing

### Running Tests

Run all tests:

```bash
flutter test
```

Run tests with coverage:

```bash
flutter test --coverage
```

### Code Quality

Check code quality with analyzer:

```bash
flutter analyze
```

### Test Coverage

This package maintains over 90% test coverage, including:

- Unit tests for all core functionality
- Integration tests for client-channel interactions
- Mock-based testing for WebSocket and HTTP dependencies
- Stream testing with proper async patterns

## Contributing

Contributions are welcome! Here are some ways you can contribute:

1. **Report Bugs** - If you find a bug, please create an issue with details
2. **Suggest Features** - Have an idea? Open an issue to discuss it
3. **Submit Pull Requests** - Fix bugs or add features

### Development Guidelines

- Follow Dart style guide and linting rules
- Write tests for new functionality
- Maintain or improve code coverage
- Update documentation for API changes
- Use meaningful commit messages

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/yourusername/pusher_reverb_flutter.git

# Install dependencies
flutter pub get

# Run tests
flutter test

# Generate mocks (if needed)
flutter pub run build_runner build
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for [Laravel Reverb](https://reverb.laravel.com/)
- Implements the [Pusher Protocol](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/)
- Inspired by the Flutter community's need for a reliable Reverb client

## Support

If you encounter any issues or have questions:

- Check existing [GitHub Issues](https://github.com/yourusername/pusher_reverb_flutter/issues)
- Create a new issue with detailed information
- Include Flutter/Dart versions and error logs when reporting bugs

---
