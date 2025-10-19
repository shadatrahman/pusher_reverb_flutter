# Pusher Reverb Flutter

A Flutter/Dart client for Laravel Reverb, providing real-time WebSocket communication using the Pusher Protocol. This package offers a native Dart implementation optimized for Flutter applications, enabling seamless bidirectional communication with Laravel backends.

## Features

- 🔌 **WebSocket Connection** - Connect to Laravel Reverb servers with automatic reconnection
- 📡 **Public Channels** - Subscribe to and receive events on public channels
- 🔐 **Private Channels** - Secure private channel authentication with custom authorizers
- 🔒 **Encrypted Channels** - End-to-end encryption for maximum security with AES-256-CBC
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
  pusher_reverb_flutter: ^0.0.3
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

Get up and running in 3 simple steps:

### 1. Basic Connection

```dart
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

// Initialize and connect
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
);

await client.connect();
```

### 2. Subscribe to a Channel

```dart
// Subscribe to a public channel
final channel = client.subscribeToChannel('notifications');

// Listen for events
channel.on('new-message').listen((event) {
  print('Received: ${event.data}');
});
```

### 3. Laravel Setup

```bash
# Install broadcasting
php artisan install:broadcasting

# Start Reverb server
php artisan reverb:start
```

**That's it!** You're now connected to Laravel Reverb. Continue reading for advanced features like private channels, encryption, and API key authentication.

## 📖 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [Getting Started](#getting-started)
- [Usage Examples](#usage)
  - [Basic Connection](#example-1-basic-connection-to-reverb-server-using-singleton)
  - [API Key & Cluster Support](#example-11-using-api-key-and-cluster-support)
  - [Public Channels](#example-2-subscribe-to-a-public-channel-with-callback-based-api)
  - [Private Channels](#example-4-subscribe-to-a-private-channel-with-authentication)
  - [Encrypted Channels](#example-5-subscribe-to-an-encrypted-channel)
  - [Flutter Widget Integration](#example-6-using-streambuilder-in-flutter-widgets)
  - [Connection Lifecycle](#example-7-connection-lifecycle-and-enhanced-callbacks)
- [API Key and Cluster Support](#api-key-and-cluster-support)
- [Configuration](#configuration)
- [Error Handling](#error-handling-and-exceptions)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Contributing](#contributing)

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

## 📚 Usage

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

### Example 5: Subscribe to an Encrypted Channel

Encrypted channels provide end-to-end encryption for maximum security. Events are automatically decrypted before being delivered to your application.

```dart
// Initialize client with authorizer (required for encrypted channels)
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
  authorizer: myAuthorizer,
  authEndpoint: 'http://localhost:8000/broadcasting/auth',
);

await client.connect();

// Subscribe to encrypted channel with encryption key
// The encryption key should be a base64-encoded 32-byte key
final encryptedChannel = client.encryptedChannel(
  'private-encrypted-messages',
  encryptionMasterKey: 'your-32-byte-base64-encoded-key',
);

await encryptedChannel.subscribe();

// Listen for encrypted events (automatically decrypted)
encryptedChannel.on('secure-message').listen((event) {
  // event.data is already decrypted and ready to use
  print('Decrypted message: ${event.data}');
});

// Handle decryption errors
encryptedChannel.on('pusher:decryption_error').listen((event) {
  print('Decryption failed: ${event.data['message']}');
});
```

**Security Best Practices for Encrypted Channels:**

- **Never hardcode encryption keys** - Retrieve keys from your secure backend API
- **Use Flutter Secure Storage** - Store keys securely if persistence is needed
- **Rotate keys regularly** - Implement key rotation for enhanced security
- **Protect key transmission** - Always use HTTPS when fetching encryption keys
- **Match server encryption** - Ensure your key matches the server's encryption key

**Laravel Backend Setup for Encrypted Channels:**

```php
// In your Laravel application
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('private-encrypted-messages', function ($user) {
    return ['id' => $user->id, 'name' => $user->name];
});

// Broadcasting encrypted events
broadcast(new SecureMessageEvent($data))
    ->toOthers();
```

### Example 6: Using StreamBuilder in Flutter Widgets

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

### Example 7: Connection Lifecycle and Enhanced Callbacks

The client provides granular connection lifecycle callbacks that enable building responsive UIs based on connection status:

```dart
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

// Initialize client with connection lifecycle callbacks
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',

  // Callback fired when connection attempt starts
  onConnecting: () {
    print('Connecting to server...');
    // Update UI to show connecting indicator
  },

  // Callback fired when successfully connected
  onConnected: (socketId) {
    print('Connected! Socket ID: $socketId');
    // Update UI to show connected status
  },

  // Callback fired when attempting to reconnect after connection loss
  onReconnecting: () {
    print('Connection lost. Reconnecting...');
    // Update UI to show reconnecting status
  },

  // Callback fired when disconnected
  onDisconnected: () {
    print('Disconnected from server');
    // Update UI to show disconnected status
  },

  // Callback fired on connection errors
  onError: (error) {
    print('Connection error: $error');
    // Show error message to user
  },
);

await client.connect();
```

**Connection State Flow:**

```
[disconnected]
     ↓ connect()
[connecting] ← onConnecting() callback
     ↓ success
[connected] ← onConnected() callback
     ↓ connection lost
[disconnected] ← onDisconnected() callback
     ↓ auto-reconnect
[reconnecting] ← onReconnecting() callback
     ↓ retry after delay
[connecting] → [connected] ← onConnected() callback
```

**Automatic Reconnection:**

The client automatically attempts to reconnect when the connection is lost unexpectedly:

- **Exponential Backoff:** Delays increase from 2s to 30s maximum
- **Infinite Retries:** The client will keep trying until reconnected
- **Manual Override:** Calling `disconnect()` prevents automatic reconnection

**Building Responsive UIs with Connection Callbacks:**

```dart
import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

class ConnectionStatusWidget extends StatefulWidget {
  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  String _status = 'Disconnected';
  Color _statusColor = Colors.red;

  @override
  void initState() {
    super.initState();

    final client = ReverbClient.instance(
      host: 'localhost',
      port: 8080,
      appKey: 'your-app-key',

      onConnecting: () {
        setState(() {
          _status = 'Connecting...';
          _statusColor = Colors.orange;
        });
      },

      onConnected: (socketId) {
        setState(() {
          _status = 'Connected';
          _statusColor = Colors.green;
        });
      },

      onReconnecting: () {
        setState(() {
          _status = 'Reconnecting...';
          _statusColor = Colors.amber;
        });
      },

      onDisconnected: () {
        setState(() {
          _status = 'Disconnected';
          _statusColor = Colors.red;
        });
      },

      onError: (error) {
        setState(() {
          _status = 'Error: $error';
          _statusColor = Colors.red;
        });
      },
    );

    client.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.2),
        border: Border.all(color: _statusColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: _statusColor, size: 12),
          SizedBox(width: 8),
          Text(
            _status,
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Using Connection State Stream:**

Alternatively, you can use the `onConnectionStateChange` stream for reactive programming:

```dart
import 'package:flutter/material.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

class ConnectionMonitor extends StatelessWidget {
  final ReverbClient client;

  const ConnectionMonitor({required this.client});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionState>(
      stream: client.onConnectionStateChange,
      initialData: ConnectionState.disconnected,
      builder: (context, snapshot) {
        final state = snapshot.data!;

        String statusText;
        Color statusColor;
        IconData statusIcon;

        switch (state) {
          case ConnectionState.connecting:
            statusText = 'Connecting';
            statusColor = Colors.orange;
            statusIcon = Icons.sync;
            break;
          case ConnectionState.connected:
            statusText = 'Connected';
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case ConnectionState.reconnecting:
            statusText = 'Reconnecting';
            statusColor = Colors.amber;
            statusIcon = Icons.refresh;
            break;
          case ConnectionState.disconnected:
            statusText = 'Disconnected';
            statusColor = Colors.red;
            statusIcon = Icons.cloud_off;
            break;
          case ConnectionState.error:
            statusText = 'Error';
            statusColor = Colors.red;
            statusIcon = Icons.error;
            break;
        }

        return Chip(
          avatar: Icon(statusIcon, color: statusColor, size: 18),
          label: Text(statusText),
          backgroundColor: statusColor.withOpacity(0.1),
        );
      },
    );
  }
}
```

## 🔑 API Key and Cluster Support

### API Key Authentication

The package now supports API key-based authentication for enhanced security:

```dart
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
  apiKey: 'your-api-key',  // NEW: API key for authentication
);
```

The API key is automatically included in:

- WebSocket connection headers as `Authorization: Bearer {apiKey}`
- Private channel authentication headers

### Cluster Configuration

Use predefined cluster configurations for easier deployment:

```dart
final client = ReverbClient.instance(
  cluster: 'us-east-1',    // Automatically configures host, port, TLS
  appKey: 'your-app-key',
  apiKey: 'your-api-key',
);
```

#### Available Clusters

| Cluster          | Region                   | Host                               | Port | TLS |
| ---------------- | ------------------------ | ---------------------------------- | ---- | --- |
| `us-east-1`      | US East (N. Virginia)    | `reverb-us-east-1.pusher.com`      | 443  | ✅  |
| `us-west-2`      | US West (Oregon)         | `reverb-us-west-2.pusher.com`      | 443  | ✅  |
| `eu-west-1`      | Europe (Ireland)         | `reverb-eu-west-1.pusher.com`      | 443  | ✅  |
| `ap-southeast-1` | Asia Pacific (Singapore) | `reverb-ap-southeast-1.pusher.com` | 443  | ✅  |
| `local`          | Local Development        | `localhost`                        | 8080 | ❌  |
| `staging`        | Staging Environment      | `staging-reverb.pusher.com`        | 443  | ✅  |

### Mixed Configuration

You can combine cluster settings with explicit parameters:

```dart
final client = ReverbClient.instance(
  cluster: 'us-east-1',           // Sets host, port, TLS
  appKey: 'your-app-key',
  apiKey: 'your-api-key',
  wsPath: '/custom/path',         // Override cluster default
);
```

### Configuration Resolution

The package intelligently resolves configuration with the following priority:

1. **Explicit parameters** (host, port, useTLS) - highest priority
2. **Cluster configuration** - applied when cluster is specified
3. **Default values** - fallback for unspecified parameters

### Helper Methods

Access configuration information:

```dart
final client = ReverbClient.instance(/* ... */);

// Get available clusters
final clusters = client.availableClusters;
print('Available clusters: $clusters');

// Get cluster configuration
final config = client.getClusterConfig('us-east-1');
print('Host: ${config?.host}, Port: ${config?.port}');

// Check if using cluster
if (client.isUsingCluster) {
  print('Using cluster: ${client.cluster}');
}

// Get effective configuration
print('Effective host: ${client.effectiveHost}');
print('Effective port: ${client.effectivePort}');
print('Using TLS: ${client.effectiveUseTLS}');
```

### Backward Compatibility

All existing code continues to work without changes:

```dart
// This still works exactly as before
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',
);
```

## ⚙️ Configuration

### ReverbClient Options

The `ReverbClient.instance()` method accepts the following parameters:

| Parameter        | Type                               | Required         | Default                | Description                                      |
| ---------------- | ---------------------------------- | ---------------- | ---------------------- | ------------------------------------------------ |
| `host`           | `String`                           | Yes (first call) | -                      | Reverb server hostname                           |
| `port`           | `int`                              | Yes (first call) | -                      | Reverb server port                               |
| `appKey`         | `String`                           | Yes (first call) | -                      | Application key for authentication               |
| `apiKey`         | `String?`                          | No               | `null`                 | API key for authentication (NEW)                 |
| `cluster`        | `String?`                          | No               | `null`                 | Cluster identifier for predefined configs (NEW)  |
| `wsPath`         | `String`                           | No               | `/`                    | Custom WebSocket path (e.g., `/app/websocket`)   |
| `authorizer`     | `Authorizer`                       | No               | `null`                 | Custom authorizer function for private channels  |
| `authEndpoint`   | `String`                           | No               | `'/broadcasting/auth'` | Authentication endpoint URL for private channels |
| `onConnecting`   | `void Function()?`                 | No               | `null`                 | Callback fired when connection attempt starts    |
| `onConnected`    | `void Function(String? socketId)?` | No               | `null`                 | Callback fired when successfully connected       |
| `onReconnecting` | `void Function()?`                 | No               | `null`                 | Callback fired when attempting to reconnect      |
| `onDisconnected` | `void Function()?`                 | No               | `null`                 | Callback fired when disconnected                 |
| `onError`        | `void Function(dynamic error)?`    | No               | `null`                 | Callback fired on connection errors              |

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

## 🚨 Error Handling and Exceptions

The package provides a comprehensive hierarchy of typed exceptions that allow you to programmatically handle different failure modes. All package-specific exceptions extend from `PusherException`, enabling you to catch all errors with a single handler or handle specific error types individually.

### Exception Hierarchy

```
Exception (Dart built-in)
  └── PusherException (base for all package exceptions)
      ├── ConnectionException (WebSocket connection errors)
      ├── ChannelException (channel operation errors)
      ├── InvalidChannelNameException (channel name validation)
      └── AuthenticationException (authentication failures)
```

### Exception Types

#### PusherException

Base exception for all Pusher Reverb Flutter errors. Catch this to handle all package-specific exceptions.

```dart
try {
  await client.connect();
} on PusherException catch (e) {
  print('Pusher error occurred: $e');
} catch (e) {
  print('Other error: $e');
}
```

#### ConnectionException

Thrown when WebSocket connection fails. Includes an optional `cause` field for the underlying error.

**When thrown:**

- Unable to establish initial connection to the server
- Network errors during connection attempts
- Invalid connection configuration (empty host, invalid port)

```dart
try {
  await client.connect();
} on ConnectionException catch (e) {
  print('Connection failed: ${e.message}');
  if (e.cause != null) {
    print('Caused by: ${e.cause}');
  }
  // Retry logic, show offline UI, etc.
}
```

#### AuthenticationException

Thrown when authentication fails for private, presence, or encrypted channels.

**When thrown:**

- Authentication endpoint returns 403 (Forbidden)
- Authentication endpoint returns non-200 status
- Authentication response missing required 'auth' key
- Network errors during authentication request

```dart
try {
  await client.subscribeToPrivateChannel('private-chat');
} on AuthenticationException catch (e) {
  if (e.statusCode == 403) {
    print('Access forbidden for ${e.channelName}');
    // Redirect to login
  } else {
    print('Auth failed: ${e.message}');
    // Retry authentication
  }
}
```

#### ChannelException

Thrown when channel operations fail.

**When thrown:**

- Authorizer not configured for private/presence/encrypted channels
- Attempting to convert existing channel to different type
- Channel subscription failures

```dart
try {
  final channel = client.subscribeToPrivateChannel('private-chat');
} on ChannelException catch (e) {
  print('Channel error: ${e.message}');
  if (e.channelName != null) {
    print('Affected channel: ${e.channelName}');
  }
  // Show error message to user
}
```

#### InvalidChannelNameException

Thrown when a channel name fails validation.

**When thrown:**

- Channel name is empty
- Channel name exceeds 200 characters
- Channel name contains invalid characters
- Private channel missing "private-" prefix
- Presence channel missing "presence-" prefix
- Encrypted channel missing "private-encrypted-" prefix

```dart
try {
  client.subscribeToPrivateChannel('invalid-name');
} on InvalidChannelNameException catch (e) {
  print('Invalid channel name: ${e.channelName}');
  print('Reason: ${e.message}');
  // Show validation error to user
}
```

### Best Practices for Error Handling

#### Catch Specific Exception Types

Handle specific exceptions for targeted error recovery:

```dart
try {
  final client = ReverbClient.instance(
    host: 'localhost',
    port: 8080,
    appKey: 'your-app-key',
  );
  await client.connect();

  final channel = client.subscribeToPrivateChannel('private-chat');
  await channel.subscribe();

} on ConnectionException catch (e) {
  // Handle connection failures
  showSnackBar('Unable to connect to server');
  scheduleRetry();

} on AuthenticationException catch (e) {
  // Handle authentication failures
  if (e.statusCode == 403) {
    redirectToLogin();
  } else {
    refreshToken();
  }

} on InvalidChannelNameException catch (e) {
  // Handle validation errors
  showError('Invalid channel name: ${e.channelName}');

} on ChannelException catch (e) {
  // Handle channel operation errors
  showError('Channel error: ${e.message}');

} on PusherException catch (e) {
  // Handle any other package-specific errors
  showError('Pusher error: ${e.message}');

} catch (e) {
  // Handle unexpected errors
  showError('Unexpected error: $e');
}
```

#### Handle Errors in Callbacks

The `onError` callback receives typed exceptions:

```dart
final client = ReverbClient.instance(
  host: 'localhost',
  port: 8080,
  appKey: 'your-app-key',

  onError: (error) {
    if (error is ConnectionException) {
      // Show "reconnecting" indicator
      showReconnectingIndicator();
    } else if (error is AuthenticationException) {
      // Prompt for re-authentication
      promptLogin();
    } else {
      // Show generic error
      showError('Error: $error');
    }
  },
);
```

#### Distinguish Between Connection and Auth Failures

Different failure modes require different handling:

```dart
Future<void> connectAndSubscribe() async {
  try {
    await client.connect();
    await client.subscribeToPrivateChannel('private-user-123').subscribe();

  } on ConnectionException catch (e) {
    // Network issue - retry makes sense
    print('Connection failed: ${e.message}');
    await Future.delayed(Duration(seconds: 5));
    return connectAndSubscribe(); // Retry

  } on AuthenticationException catch (e) {
    // Auth issue - retry won't help without new credentials
    print('Authentication failed: ${e.message}');
    await refreshAuthToken();
    return connectAndSubscribe(); // Retry with new token
  }
}
```

#### Using Try-Catch with Async/Await

Always handle exceptions in async operations:

```dart
Future<void> setupRealtime() async {
  try {
    final client = ReverbClient.instance(
      host: 'localhost',
      port: 8080,
      appKey: 'your-app-key',
    );

    await client.connect();

    final channel = client.channel('notifications');
    await channel.subscribe();

    channel.on('message').listen((event) {
      print('Received: ${event.data}');
    });

  } on PusherException catch (e) {
    print('Setup failed: $e');
    // Show error UI and allow user to retry
    showRetryButton(onPressed: setupRealtime);
  }
}
```

### Error Messages

All exceptions provide clear, actionable error messages through their `toString()` method:

```dart
// PusherException
PusherException: Connection failed

// ConnectionException with cause
ConnectionException: Failed to connect to server (Caused by: SocketException: Connection refused)

// AuthenticationException with status code
AuthenticationException: Authentication forbidden - insufficient permissions (HTTP 403) for channel "private-chat"

// ChannelException with channel name
ChannelException: Authorizer and authEndpoint must be configured for private channels for channel "private-user-123"

// InvalidChannelNameException
InvalidChannelNameException: Private channel name must start with "private-" prefix (Channel: "invalid-name")
```

## 📖 API Reference

### ReverbClient

- `ReverbClient.instance(...)` - Get or create singleton instance
- `connect()` - Connect to the Reverb server
- `disconnect()` - Disconnect from the server
- `channel(String name)` - Subscribe to a public channel
- `privateChannel(String name)` - Subscribe to a private channel
- `encryptedChannel(String name, {required String encryptionMasterKey})` - Subscribe to an encrypted channel
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

### EncryptedChannel

Extends `PrivateChannel` with automatic event decryption using AES-256-CBC encryption. All `PrivateChannel` and `Channel` methods are available.

**Special Events:**

- `pusher:decryption_error` - Emitted when event decryption fails

**Encryption Protocol:**

- Algorithm: AES-256-CBC
- Key Format: Base64-encoded 32-byte key
- Event Format: `{ciphertext: string, nonce: string}`

### ConnectionState

Enum representing connection states:

- `disconnected` - Not connected
- `connecting` - Connection in progress
- `connected` - Successfully connected
- `reconnecting` - Attempting to reconnect after connection loss
- `error` - Error occurred during connection or communication

### ChannelState

Enum representing channel subscription states:

- `unsubscribed` - Not subscribed
- `subscribing` - Subscription in progress
- `subscribed` - Successfully subscribed

## 🧪 Testing

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

## 🤝 Contributing

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
