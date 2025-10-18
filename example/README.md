# Pusher Reverb Flutter - Example App

A comprehensive example application demonstrating all features of the `pusher_reverb_flutter` package. This app showcases real-time WebSocket communication with Laravel Reverb, including public channels, private channels, presence channels, and encrypted channels.

## Features Demonstrated

### 🎯 Core Features

- ✅ WebSocket connection management with real-time status
- ✅ Automatic reconnection with exponential backoff
- ✅ Connection state monitoring via streams
- ✅ Singleton pattern for client access
- ✅ Stream-based and callback-based APIs
- ✅ Comprehensive error handling with typed exceptions

### 📡 Channel Types

- **Public Channels** - Open channels accessible to anyone
- **Private Channels** - Secure channels requiring authentication
- **Presence Channels** - Track online members in real-time
- **Encrypted Channels** - End-to-end encryption with AES-256-CBC

### 🎨 UI/UX Features

- Modern Material 3 design
- Dark mode support
- Real-time connection status indicator
- Live event feed for each channel type
- Member list for presence channels
- Settings screen for server configuration
- Beautiful error handling and empty states

## Screenshots

The example app includes:

- **Home Screen** - Connection status and channel type navigation
- **Settings Screen** - Configure server connection and authentication
- **Public Channel Demo** - Subscribe to public channels and receive events
- **Private Channel Demo** - Authenticate and subscribe to private channels
- **Presence Channel Demo** - See online members and track joins/leaves
- **Encrypted Channel Demo** - Subscribe with encryption keys and receive decrypted events

## Prerequisites

Before running this example app, you need:

### 1. Laravel Application with Reverb

Install Laravel Reverb in your Laravel application:

```bash
# In your Laravel project
php artisan install:broadcasting
```

This will:

- Install Laravel Reverb
- Publish configuration files
- Set up broadcasting routes

### 2. Start Reverb Server

Start the Reverb WebSocket server:

```bash
php artisan reverb:start
```

By default, Reverb runs on:

- Host: `localhost` or `127.0.0.1`
- Port: `8080`
- WebSocket Path: `/`

### 3. Configure Laravel Broadcasting

Update your `.env` file:

```env
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

### 4. Set Up Broadcasting Authentication (for Private/Presence/Encrypted Channels)

In `routes/channels.php`, define your channel authorization logic:

```php
use Illuminate\Support\Facades\Broadcast;

// Public channels don't need authorization

// Private channel example
Broadcast::channel('private-user-{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Presence channel example
Broadcast::channel('presence-chat-room', function ($user) {
    return ['id' => $user->id, 'name' => $user->name];
});

// Encrypted channel example
Broadcast::channel('private-encrypted-messages', function ($user) {
    return ['id' => $user->id, 'name' => $user->name];
});
```

In `app/Http/Middleware/Authenticate.php` or your broadcasting routes, ensure authentication is properly configured:

```php
// routes/api.php or routes/web.php
Route::post('/broadcasting/auth', function (Request $request) {
    return Broadcast::auth($request);
})->middleware('auth:sanctum'); // or your authentication method
```

## Installation

### 1. Clone and Install Dependencies

```bash
# Navigate to the example directory
cd example

# Get Flutter dependencies
flutter pub get
```

### 2. Run the Example App

```bash
# Run on your preferred device/simulator
flutter run

# Or specify a device
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run -d ios         # iOS simulator
flutter run -d android     # Android emulator
```

## Configuration

### Initial Setup

1. **Launch the App** - The app will start with default configuration
2. **Go to Settings** - Tap the "Settings" tab in the bottom navigation
3. **Configure Server Connection**:

   - **Host**: Your Reverb server hostname (default: `localhost`)
   - **Port**: Your Reverb server port (default: `8080`)
   - **Application Key**: Your app key from `.env` (default: `your-app-key`)
   - **WebSocket Path**: Custom path if needed (default: `/`)
   - **Use TLS/SSL (wss://)**: Toggle for secure connections (default: OFF)
   - **Auth Endpoint**: Your Laravel broadcasting auth endpoint (default: `http://localhost:8000/broadcasting/auth`)
   - **Auth Token**: Bearer token for authentication (optional, required for private channels)

4. **Save Settings** - Tap "Save Settings" to apply configuration
5. **Return to Home** - Tap the "Home" tab
6. **Connect** - Tap "Connect to Server"

> **Note**: For production servers using HTTPS (port 443), enable the **"Use TLS/SSL"** toggle to use secure WebSocket connections (`wss://`).

### Obtaining an Auth Token

For private, presence, and encrypted channels, you need a valid authentication token:

#### Using Laravel Sanctum:

```bash
# In your Laravel application
php artisan tinker

# Create a token for a user
$user = User::find(1);
$token = $user->createToken('reverb-token')->plainTextToken;
echo $token;
```

Copy this token and paste it into the "Auth Token" field in the app settings.

#### Using Laravel Passport:

```bash
# Generate a personal access token through your Laravel API
# Then use it in the app settings
```

### Using on Physical Devices

If you're running on a physical device (not localhost), you need to:

1. **Use Your Computer's IP Address**:

   ```bash
   # Find your IP (macOS/Linux)
   ifconfig | grep "inet "

   # Find your IP (Windows)
   ipconfig
   ```

2. **Update Settings**:

   - Host: `192.168.1.X` (your computer's IP)
   - Auth Endpoint: `http://192.168.1.X:8000/broadcasting/auth`
   - Use TLS/SSL: OFF (for local development)

3. **Allow Network Access** in Laravel:

   ```bash
   # Start Reverb with host binding
   php artisan reverb:start --host=0.0.0.0

   # Start Laravel dev server accessible on network
   php artisan serve --host=0.0.0.0
   ```

### Using with Production Servers

For production servers with HTTPS/TLS:

1. **Enable TLS/SSL Toggle**: Turn ON the "Use TLS/SSL (wss://)" switch
2. **Use Proper Domain**: Enter your production domain (e.g., `api.example.com`)
3. **Use HTTPS Port**: Typically port `443` or your custom HTTPS port
4. **Secure Auth Endpoint**: Use `https://` for your auth endpoint

Example production configuration:

- Host: `api.example.com`
- Port: `443`
- Use TLS/SSL: ✅ ON
- WebSocket Path: `/realtime/app/your-app-key`
- Auth Endpoint: `https://api.example.com/api/broadcasting/auth`

## Usage Guide

### Public Channels Demo

1. Navigate to "Public Channels" from the home screen
2. Enter a channel name (e.g., `notifications`)
3. Optionally enter an event name for the callback demo
4. Tap "Subscribe"
5. Events will appear in real-time

**Testing with Laravel Tinker:**

```php
php artisan tinker

# Broadcast to public channel
broadcast(new \Illuminate\Notifications\Events\BroadcastNotificationCreated(
    App\Models\User::first(),
    new \App\Notifications\TestNotification(),
    ['message' => 'Hello from Laravel!']
))->toOthers();

# Or use Reverb directly
use Illuminate\Broadcasting\Broadcasters\PusherBroadcaster;
broadcast()->on('notifications')->event('message')->with(['text' => 'Test message']);
```

### Private Channels Demo

1. Ensure you have configured an auth token in Settings
2. Navigate to "Private Channels"
3. Enter a private channel name starting with `private-` (e.g., `private-user-123`)
4. Tap "Subscribe" - authentication will occur automatically
5. Private events will appear in real-time

**Testing with Laravel:**

```php
// Create an event
php artisan make:event PrivateMessageEvent

// In PrivateMessageEvent.php
public function broadcastOn()
{
    return new PrivateChannel('private-user-123');
}

// Broadcast it
event(new PrivateMessageEvent(['message' => 'Private message']));
```

### Presence Channels Demo

1. Ensure you have configured an auth token in Settings
2. Navigate to "Presence Channels"
3. Enter a presence channel name starting with `presence-` (e.g., `presence-chat-room`)
4. Tap "Subscribe"
5. See online members in the members list
6. Open the app on multiple devices/browsers to see members join/leave

**Testing with Laravel:**

```php
// In routes/channels.php
Broadcast::channel('presence-chat-room', function ($user) {
    return ['id' => $user->id, 'name' => $user->name, 'avatar' => $user->avatar];
});

// Create a presence event
php artisan make:event ChatMessageEvent

// In ChatMessageEvent.php
public function broadcastOn()
{
    return new PresenceChannel('presence-chat-room');
}

// Broadcast it
event(new ChatMessageEvent(['message' => 'Hello everyone!', 'user' => auth()->user()]));
```

### Encrypted Channels Demo

1. Ensure you have configured an auth token in Settings
2. Navigate to "Encrypted Channels"
3. Enter an encrypted channel name starting with `private-encrypted-`
4. Enter your base64-encoded 32-byte encryption key
5. Tap "Subscribe"
6. Events will be automatically decrypted

**Setting up Encryption in Laravel:**

```php
// Generate an encryption key
$key = base64_encode(random_bytes(32));
echo $key; // Use this in the Flutter app

// In .env
REVERB_ENCRYPTION_KEY=your-base64-key-here

// In routes/channels.php
Broadcast::channel('private-encrypted-messages', function ($user) {
    return ['id' => $user->id, 'name' => $user->name];
});

// Create an encrypted event
php artisan make:event EncryptedMessageEvent

// In EncryptedMessageEvent.php
public function broadcastOn()
{
    return new PrivateChannel('private-encrypted-messages');
}

// The encryption is handled automatically by Laravel Reverb
event(new EncryptedMessageEvent(['secret' => 'This is encrypted!']));
```

## Code Examples

### Using the ReverbService Singleton

```dart
import 'package:pusher_reverb_flutter_example/services/reverb_service.dart';

final reverbService = ReverbService.instance;

// Initialize and connect
await reverbService.initialize();
await reverbService.connect();

// Access the client
final client = reverbService.client;
```

### Subscribing to a Channel with Stream API

```dart
final channel = client.channel('my-channel');
await channel.subscribe();

channel.stream.listen((event) {
  print('Received: ${event.eventName} - ${event.data}');
});
```

### Subscribing with Callback API

```dart
final channel = client.channel('my-channel');
await channel.subscribe();

channel.bind('my-event', (data) {
  print('Event data: $data');
});
```

### Monitoring Connection State

```dart
client.onConnectionStateChange.listen((state) {
  switch (state) {
    case ConnectionState.connected:
      print('Connected with socket ID: ${client.socketId}');
      break;
    case ConnectionState.disconnected:
      print('Disconnected');
      break;
    // ... handle other states
  }
});
```

### Error Handling

```dart
try {
  await channel.subscribe();
} on AuthenticationException catch (e) {
  print('Auth failed: ${e.message}, Status: ${e.statusCode}');
} on ChannelException catch (e) {
  print('Channel error: ${e.message}');
} on ConnectionException catch (e) {
  print('Connection error: ${e.message}');
}
```

## Project Structure

```
example/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── services/
│   │   └── reverb_service.dart     # Singleton service for Reverb client
│   ├── screens/
│   │   ├── home_screen.dart        # Home screen with navigation
│   │   ├── settings_screen.dart    # Settings and configuration
│   │   ├── public_channel_screen.dart
│   │   ├── private_channel_screen.dart
│   │   ├── presence_channel_screen.dart
│   │   └── encrypted_channel_screen.dart
│   └── widgets/
│       ├── connection_status_widget.dart
│       ├── channel_demo_card.dart
│       └── event_list_item.dart
├── pubspec.yaml
└── README.md (this file)
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to Reverb server

**Solutions**:

- Verify Reverb server is running: `php artisan reverb:start`
- Check host and port in settings match your Reverb configuration
- If on a physical device, use your computer's IP instead of `localhost`
- Check firewall settings

### Authentication Failures

**Problem**: Private/Presence/Encrypted channels return 403 Forbidden

**Solutions**:

- Ensure auth token is valid and not expired
- Check that the user has permission in `routes/channels.php`
- Verify auth endpoint is correct and accessible
- Check that authentication middleware is properly configured

### Events Not Received

**Problem**: Subscribed but not receiving events

**Solutions**:

- Check console logs for subscription confirmation
- Verify channel names match exactly (case-sensitive)
- Ensure events are being broadcast on the correct channel
- Check that the event implements `ShouldBroadcast` in Laravel

### Encryption Errors

**Problem**: Receiving `pusher:decryption_error` events

**Solutions**:

- Verify encryption key matches exactly between client and server
- Ensure key is properly base64-encoded
- Check that the channel is configured as encrypted in Laravel

## Additional Resources

- [pusher_reverb_flutter Package](https://pub.dev/packages/pusher_reverb_flutter)
- [Laravel Reverb Documentation](https://laravel.com/docs/reverb)
- [Laravel Broadcasting Documentation](https://laravel.com/docs/broadcasting)
- [Pusher Protocol Documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/)

## Contributing

Found an issue or want to improve the example? Contributions are welcome!

## License

This example app is part of the pusher_reverb_flutter package and is licensed under the MIT License.
