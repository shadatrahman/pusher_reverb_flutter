## 0.0.3

### New Features

- **API Key Authentication Support**: Added optional API key parameter for enhanced authentication

  - New `apiKey` parameter in `ReverbClient.instance()` for API key-based authentication
  - API key is automatically included in WebSocket connection headers as `Authorization: Bearer {apiKey}`
  - API key is also included in private channel authentication headers
  - Maintains full backward compatibility - existing code continues to work without changes
  - Example: `ReverbClient.instance(host: 'localhost', port: 8080, appKey: 'app-key', apiKey: 'your-api-key')`

- **Cluster Configuration Support**: Added predefined cluster configurations for easier deployment

  - New `cluster` parameter in `ReverbClient.instance()` for predefined cluster settings
  - Available clusters: `us-east-1`, `us-west-2`, `eu-west-1`, `ap-southeast-1`, `local`, `staging`
  - Cluster settings automatically configure host, port, and TLS settings
  - Can be combined with explicit parameters for mixed configuration
  - Example: `ReverbClient.instance(cluster: 'us-east-1', appKey: 'app-key', apiKey: 'your-api-key')`

- **Enhanced Configuration Management**: Added helper methods for configuration access and debugging

  - `availableClusters` - Get list of available cluster names
  - `getClusterConfig(String cluster)` - Get configuration for specific cluster
  - `resolvedConfig` - Access to final resolved configuration
  - `isUsingCluster` - Check if client is using cluster configuration
  - `effectiveHost`, `effectivePort`, `effectiveUseTLS` - Get final configuration values

- **Updated Example App**: Enhanced example application with new features
  - Added API key and cluster configuration fields in settings screen
  - Secure API key input with show/hide password toggle
  - Cluster selection with helpful hints about available options
  - Enhanced connection status display showing cluster information
  - Updated setup guide with new feature information

### Technical Improvements

- **Configuration Resolution**: Implemented robust configuration resolution system

  - Cluster settings override explicit parameters when specified
  - Proper parameter validation for API keys and cluster names
  - Comprehensive error handling for invalid configurations
  - Performance optimized with configuration cached during initialization

- **WebSocket Integration**: Enhanced WebSocket connection with header support

  - Uses `IOWebSocketChannel.connect()` with headers for API key authentication
  - Proper header merging for cluster-specific and custom headers
  - Maintains compatibility with existing WebSocket channel factory pattern

- **Testing**: Added comprehensive test coverage for new features
  - 17 new unit tests covering API key and cluster functionality
  - Tests for parameter priority, backward compatibility, and edge cases
  - All existing tests continue to pass (259 total tests)
  - Test coverage maintained at over 90%

### Documentation Updates

- **README.md**: Updated with comprehensive API key and cluster documentation

  - New section dedicated to API key and cluster support
  - Usage examples for all new features
  - Updated parameter table with new options
  - Backward compatibility information

- **API Documentation**: Enhanced inline documentation
  - Detailed parameter descriptions for new options
  - Usage examples in code comments
  - Clear migration guidance for existing users

## 0.0.2

### Bug Fixes

- **Fixed async subscription cleanup issue**: Resolved "failed after test completion" error in presence, private, and encrypted channel tests
  - Added proper state checks during async authentication to prevent errors when channels are unsubscribed before authentication completes
  - Improved error handling to silently ignore authentication failures for channels that have already been unsubscribed
  - Added tearDown cleanup in tests to ensure pending async operations complete before test completion
  - Affects `PrivateChannel` and `PresenceChannel` (including `EncryptedChannel`) subscription flows

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
