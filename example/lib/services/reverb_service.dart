import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class that manages the Reverb client connection.
///
/// This service handles initialization, connection management, and provides
/// easy access to the Reverb client throughout the application.
class ReverbService {
  static ReverbService? _instance;
  ReverbClient? _client;

  // Connection configuration
  String _host = 'localhost';
  int _port = 8080;
  String _appKey = 'your-app-key';
  String _authEndpoint = 'http://localhost:8000/broadcasting/auth';
  String _wsPath = '/';
  String _authToken = '';
  bool _useTLS = false;

  // Private constructor for singleton
  ReverbService._();

  /// Get the singleton instance
  static ReverbService get instance {
    _instance ??= ReverbService._();
    return _instance!;
  }

  /// Get the Reverb client (may be null if not initialized)
  ReverbClient? get client => _client;

  /// Check if the client is initialized
  bool get isInitialized => _client != null;

  /// Load configuration from shared preferences
  Future<void> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('reverb_host') ?? 'localhost';
    _port = prefs.getInt('reverb_port') ?? 8080;
    _appKey = prefs.getString('reverb_app_key') ?? 'your-app-key';
    _authEndpoint = prefs.getString('reverb_auth_endpoint') ?? 'http://localhost:8000/broadcasting/auth';
    _wsPath = prefs.getString('reverb_ws_path') ?? '/';
    _authToken = prefs.getString('reverb_auth_token') ?? '';
    _useTLS = prefs.getBool('reverb_use_tls') ?? false;
  }

  /// Save configuration to shared preferences
  Future<void> saveConfiguration({
    required String host,
    required int port,
    required String appKey,
    required String authEndpoint,
    required String wsPath,
    required String authToken,
    required bool useTLS,
  }) async {
    _host = host;
    _port = port;
    _appKey = appKey;
    _authEndpoint = authEndpoint;
    _wsPath = wsPath;
    _authToken = authToken;
    _useTLS = useTLS;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reverb_host', host);
    await prefs.setInt('reverb_port', port);
    await prefs.setString('reverb_app_key', appKey);
    await prefs.setString('reverb_auth_endpoint', authEndpoint);
    await prefs.setString('reverb_ws_path', wsPath);
    await prefs.setString('reverb_auth_token', authToken);
    await prefs.setBool('reverb_use_tls', useTLS);
  }

  /// Get current configuration
  Map<String, dynamic> get configuration => {'host': _host, 'port': _port, 'appKey': _appKey, 'authEndpoint': _authEndpoint, 'wsPath': _wsPath, 'authToken': _authToken, 'useTLS': _useTLS};

  /// Sample authorizer function for private channels
  Future<Map<String, String>> _authorizer(String channelName, String socketId) async {
    // In a real app, you would fetch the token from secure storage
    // or your authentication service
    return {'Authorization': 'Bearer $_authToken', 'Content-Type': 'application/json'};
  }

  /// Initialize the Reverb client
  Future<void> initialize() async {
    await loadConfiguration();

    _client = ReverbClient.instance(
      host: _host,
      port: _port,
      appKey: _appKey,
      wsPath: _wsPath,
      useTLS: _useTLS,
      authorizer: _authorizer,
      authEndpoint: _authEndpoint,
      onConnecting: () {
        debugPrint('[ReverbService] Connecting to server...');
      },
      onConnected: (socketId) {
        debugPrint('[ReverbService] Connected! Socket ID: $socketId');
      },
      onReconnecting: () {
        debugPrint('[ReverbService] Connection lost. Reconnecting...');
      },
      onDisconnected: () {
        debugPrint('[ReverbService] Disconnected from server');
      },
      onError: (error) {
        debugPrint('[ReverbService] Connection error: $error');
      },
    );
  }

  /// Connect to the Reverb server
  Future<void> connect() async {
    if (_client == null) {
      await initialize();
    }

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('[ReverbService] Connection failed: $e');
      rethrow;
    }
  }

  /// Disconnect from the Reverb server
  void disconnect() {
    if (_client != null) {
      _client!.disconnect();
    }
  }

  /// Reinitialize the client with new configuration
  /// Note: This creates a new client instance with updated configuration.
  /// The old client instance will be discarded.
  Future<void> reinitialize() async {
    disconnect();
    // Create a new client instance (singleton will be replaced)
    _client = null;
    await initialize();
  }
}
