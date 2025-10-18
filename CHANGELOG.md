## 0.0.1

### Initial Release

A comprehensive Flutter/Dart client for Laravel Reverb, providing real-time WebSocket communication using the Pusher Protocol.

#### Core Features

- **WebSocket Connection Management**

  - Connect to Laravel Reverb servers with automatic reconnection
  - Real-time connection state monitoring via streams
  - Enhanced connection callbacks (onConnecting, onConnected, onReconnecting, onDisconnected, onError)
  - Proper socket ID handling and management

- **Channel Types Support**

  - **Public Channels**: Open channels accessible to anyone
  - **Private Channels**: Secure channels requiring authentication
  - **Presence Channels**: Track who is subscribed with real-time member lists
  - **Encrypted Channels**: End-to-end encryption using AES-256-CBC

- **Flexible API Design**

  - Singleton pattern with `ReverbClient.instance()` for convenient access
  - Stream-based API for idiomatic Dart/Flutter integration
  - Traditional callback-based API for backward compatibility
  - Support for both callback and stream APIs simultaneously

- **Authentication & Security**

  - Dynamic authentication with custom authorizers
  - Support for custom authentication headers
  - Configurable authentication endpoints
  - Encrypted channel support with AES-256-CBC encryption

- **Developer Experience**

  - Custom WebSocket path support (`wsPath` parameter)
  - Comprehensive example app with all channel types
  - Detailed documentation with 40+ code examples
  - Over 90% test coverage with comprehensive unit tests
  - Typed error handling with custom exception classes

- **Community Contributions**
  - Integration of bug fixes from community forks
  - Improved stability and reliability
  - Better error handling and debugging

#### Technical Details

- Minimum Flutter SDK: >=1.17.0
- Minimum Dart SDK: ^3.9.2
- Dependencies: web_socket_channel, http, encrypt, meta
- Platforms: iOS, Android, Web, macOS, Linux, Windows

#### Example App

Includes a comprehensive example application demonstrating:

- Connection management with real-time status
- Public channel subscriptions
- Private channel authentication
- Presence channel member tracking
- Encrypted channel end-to-end encryption
- Settings configuration
- Both callback and stream-based APIs
