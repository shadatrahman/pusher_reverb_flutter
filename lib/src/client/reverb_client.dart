import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../channels/channel.dart';
import '../channels/private_channel.dart';
import '../auth/authorizer.dart';
import '../models/connection_state.dart';

/// A client for interacting with a Laravel Reverb WebSocket server.
///
/// This class follows the singleton pattern to ensure a single instance
/// throughout the application lifecycle. Use [ReverbClient.instance] to
/// access the singleton instance.
class ReverbClient {
  /// The singleton instance of ReverbClient.
  static ReverbClient? _instance;

  /// The host of the Reverb server.
  final String host;

  /// The port of the Reverb server.
  final int port;

  /// The application key for the Reverb server.
  final String appKey;

  /// The authorizer function for private channel authentication.
  final Authorizer? authorizer;

  /// The authentication endpoint URL for private channel authentication.
  final String? authEndpoint;

  /// The custom WebSocket path for the connection.
  /// If not provided, defaults to '/app/{appKey}'.
  final String? wsPath;

  /// The WebSocket channel used for communication.
  WebSocketChannel? _channel;

  /// The subscription to the WebSocket stream.
  StreamSubscription? _subscription;

  /// The socket ID assigned by the server upon connection.
  String? socketId;

  /// Map of subscribed channels by name.
  final Map<String, Channel> _channels = {};

  /// Stream controller for connection state changes.
  final StreamController<ConnectionState> _connectionStateController = StreamController<ConnectionState>.broadcast();

  /// The current connection state.
  ConnectionState _currentConnectionState = ConnectionState.disconnected;

  /// Callback for when the connection is successfully established.
  final void Function(String? socketId)? onConnected;

  /// Callback for when a connection error occurs.
  final void Function(dynamic error)? onError;

  /// A factory for creating WebSocket channels, primarily for testing.
  @visibleForTesting
  final WebSocketChannel Function(Uri uri)? channelFactory;

  /// A stream that emits connection state changes.
  ///
  /// Listen to this stream to be notified when the connection state changes.
  ///
  /// Example:
  /// ```dart
  /// ReverbClient.instance().onConnectionStateChange.listen((state) {
  ///   print('Connection state: $state');
  /// });
  /// ```
  Stream<ConnectionState> get onConnectionStateChange => _connectionStateController.stream;

  /// Gets the current connection state.
  ConnectionState get connectionState => _currentConnectionState;

  /// Private constructor for singleton pattern.
  ///
  /// This constructor is only accessible internally and ensures that
  /// only one instance of ReverbClient can exist.
  ReverbClient._internal({required this.host, required this.port, required this.appKey, this.authorizer, this.authEndpoint, this.wsPath, this.onConnected, this.onError, this.channelFactory}) {
    // Validate required parameters to prevent connection issues
    if (host.isEmpty) {
      throw ArgumentError('Host cannot be null or empty');
    }
    if (port <= 0 || port > 65535) {
      throw ArgumentError('Port must be between 1 and 65535');
    }
    if (appKey.isEmpty) {
      throw ArgumentError('App key cannot be null or empty');
    }
  }

  /// Gets or initializes the singleton instance of ReverbClient.
  ///
  /// This method must be called with configuration parameters on first access.
  /// Subsequent calls will return the existing instance and ignore any parameters.
  ///
  /// Example:
  /// ```dart
  /// // First initialization
  /// final client = ReverbClient.instance(
  ///   host: 'localhost',
  ///   port: 8080,
  ///   appKey: 'my-app-key',
  /// );
  ///
  /// // Later access (parameters optional)
  /// final sameClient = ReverbClient.instance();
  /// ```
  ///
  /// [host] The host of the Reverb server.
  /// [port] The port of the Reverb server.
  /// [appKey] The application key for the Reverb server.
  /// [authorizer] Optional authorizer function for private channel authentication.
  /// [authEndpoint] Optional authentication endpoint URL for private channel authentication.
  /// [wsPath] Optional custom WebSocket path. If not provided, defaults to '/app/{appKey}'.
  /// [onConnected] Optional callback for when the connection is successfully established.
  /// [onError] Optional callback for when a connection error occurs.
  /// [channelFactory] Optional factory for creating WebSocket channels, primarily for testing.
  ///
  /// Throws [StateError] if called without parameters when instance is not yet initialized.
  static ReverbClient instance({
    String? host,
    int? port,
    String? appKey,
    Authorizer? authorizer,
    String? authEndpoint,
    String? wsPath,
    void Function(String? socketId)? onConnected,
    void Function(dynamic error)? onError,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) {
    if (_instance == null) {
      if (host == null || port == null || appKey == null) {
        throw StateError(
          'ReverbClient instance has not been initialized. '
          'Please call ReverbClient.instance() with required parameters (host, port, appKey) first.',
        );
      }
      _instance = ReverbClient._internal(
        host: host,
        port: port,
        appKey: appKey,
        authorizer: authorizer,
        authEndpoint: authEndpoint,
        wsPath: wsPath,
        onConnected: onConnected,
        onError: onError,
        channelFactory: channelFactory,
      );
    }
    return _instance!;
  }

  /// Factory constructor that throws an error to prevent direct instantiation.
  ///
  /// Use [ReverbClient.instance] instead to access the singleton instance.
  ///
  /// Throws [StateError] always, as direct instantiation is not allowed in production code.
  ///
  /// For testing purposes, use [ReverbClient.forTesting] instead.
  factory ReverbClient({
    required String host,
    required int port,
    required String appKey,
    Authorizer? authorizer,
    String? authEndpoint,
    String? wsPath,
    void Function(String? socketId)? onConnected,
    void Function(dynamic error)? onError,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) {
    throw StateError(
      'ReverbClient cannot be instantiated directly. '
      'Use ReverbClient.instance() to access the singleton instance.',
    );
  }

  /// Factory constructor for testing purposes only.
  ///
  /// This constructor allows creating multiple instances for testing,
  /// bypassing the singleton pattern.
  ///
  /// This should NEVER be used in production code.
  @visibleForTesting
  factory ReverbClient.forTesting({
    required String host,
    required int port,
    required String appKey,
    Authorizer? authorizer,
    String? authEndpoint,
    String? wsPath,
    void Function(String? socketId)? onConnected,
    void Function(dynamic error)? onError,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) {
    return ReverbClient._internal(
      host: host,
      port: port,
      appKey: appKey,
      authorizer: authorizer,
      authEndpoint: authEndpoint,
      wsPath: wsPath,
      onConnected: onConnected,
      onError: onError,
      channelFactory: channelFactory,
    );
  }

  /// Resets the singleton instance.
  ///
  /// This method is primarily for testing purposes to allow resetting
  /// the singleton state between tests.
  @visibleForTesting
  static void resetInstance() {
    _instance?.disconnect();
    _instance?._connectionStateController.close();
    _instance = null;
  }

  /// Updates the connection state and notifies listeners.
  void _setConnectionState(ConnectionState newState) {
    if (_currentConnectionState != newState) {
      _currentConnectionState = newState;
      _connectionStateController.add(newState);
    }
  }

  /// Connects to the Reverb server.
  Future<void> connect() async {
    try {
      // Guard against null or empty host to prevent infinite connection loops
      if (host.isEmpty) {
        throw ArgumentError('Host cannot be null or empty');
      }

      _setConnectionState(ConnectionState.connecting);

      final uri = _constructWebSocketUri();
      _channel = channelFactory != null ? channelFactory!(uri) : WebSocketChannel.connect(uri);
      _subscription = _channel?.stream.listen(
        _handleMessage,
        onError: (error) {
          _setConnectionState(ConnectionState.error);
          onError?.call(error);
        },
        onDone: () {
          _setConnectionState(ConnectionState.disconnected);
          disconnect();
        },
      );
    } catch (e) {
      _setConnectionState(ConnectionState.error);
      onError?.call(e);
    }
  }

  /// Constructs the WebSocket URI for the connection.
  ///
  /// Uses the custom [wsPath] if provided, otherwise defaults to '/app/{appKey}'.
  Uri _constructWebSocketUri() {
    final path = wsPath ?? '/app/$appKey';
    // Handle empty path case
    if (path.isEmpty) {
      return Uri.parse('ws://$host:$port');
    }
    // Ensure path starts with '/' for proper URI construction
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('ws://$host:$port$normalizedPath');
  }

  /// Closes the connection to the Reverb server.
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    // Safe clear: create a copy of keys to avoid concurrent modification
    final channelNames = _channels.keys.toList();
    for (final channelName in channelNames) {
      final channel = _channels[channelName];
      if (channel != null) {
        channel.unsubscribe();
        channel.dispose();
      }
    }
    _channels.clear();
    _setConnectionState(ConnectionState.disconnected);
  }

  /// Subscribes to a public channel.
  Channel subscribeToChannel(String channelName) {
    if (_channels.containsKey(channelName)) {
      return _channels[channelName]!;
    }

    final channel = Channel(name: channelName, sendMessage: _sendMessage);

    _channels[channelName] = channel;
    channel.subscribe();

    return channel;
  }

  /// Subscribes to a private channel with authentication.
  ///
  /// [channelName] The name of the private channel (must start with "private-").
  ///
  /// Returns a PrivateChannel instance for the subscribed channel.
  ///
  /// Throws [ArgumentError] if the channel name is not a valid private channel name.
  /// Throws [StateError] if authorizer or authEndpoint are not configured.
  PrivateChannel subscribeToPrivateChannel(String channelName) {
    if (_channels.containsKey(channelName)) {
      final existingChannel = _channels[channelName]!;
      if (existingChannel is PrivateChannel) {
        return existingChannel;
      } else {
        throw ArgumentError(
          'Channel "$channelName" already exists as a public channel. '
          'Cannot convert to private channel.',
        );
      }
    }

    if (authorizer == null) {
      throw StateError(
        'Authorizer function is required for private channel subscription. '
        'Please configure the authorizer when creating the ReverbClient.',
      );
    }

    if (authEndpoint == null) {
      throw StateError(
        'Authentication endpoint is required for private channel subscription. '
        'Please configure the authEndpoint when creating the ReverbClient.',
      );
    }

    if (socketId == null) {
      throw StateError(
        'Socket ID is not available. Please ensure the client is connected '
        'before subscribing to private channels.',
      );
    }

    final channel = PrivateChannel(name: channelName, authorizer: authorizer!, authEndpoint: authEndpoint!, socketId: socketId!, sendMessage: _sendMessage);

    _channels[channelName] = channel;
    channel.subscribe();

    return channel;
  }

  /// Unsubscribes from a channel.
  void unsubscribeFromChannel(String channelName) {
    final channel = _channels[channelName];
    if (channel != null) {
      channel.unsubscribe();
      channel.dispose();
      // Safe removal: check if the channel still exists before removing
      // This prevents runtime errors if the channel was already removed
      if (_channels.containsKey(channelName)) {
        _channels.remove(channelName);
      }
    }
  }

  /// Gets a channel by name if it exists.
  Channel? getChannel(String channelName) {
    return _channels[channelName];
  }

  /// Gets all subscribed channels.
  List<Channel> get subscribedChannels => _channels.values.toList();

  /// Sends a message through the WebSocket channel.
  void _sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    }
  }

  void _handleMessage(dynamic message) {
    final decodedMessage = jsonDecode(message as String);
    final event = decodedMessage['event'];
    final data = decodedMessage['data'];

    if (event == 'pusher:connection_established') {
      final connectionData = jsonDecode(data as String);
      socketId = connectionData['socket_id'] as String?;
      _setConnectionState(ConnectionState.connected);
      onConnected?.call(socketId);
    } else if (event == 'pusher_internal:subscription_succeeded') {
      final channelData = jsonDecode(data as String);
      final channelName = channelData['channel'] as String?;
      if (channelName != null) {
        final channel = _channels[channelName];
        channel?.handleSubscriptionSucceeded();
      }
    } else if (event == 'pusher_internal:unsubscription_succeeded') {
      final channelData = jsonDecode(data as String);
      final channelName = channelData['channel'] as String?;
      if (channelName != null) {
        final channel = _channels[channelName];
        channel?.handleUnsubscriptionSucceeded();
      }
    } else {
      // Handle channel events
      final channelName = decodedMessage['channel'] as String?;
      if (channelName != null) {
        final channel = _channels[channelName];
        channel?.handleEvent(event, data);
      }
    }
  }
}
