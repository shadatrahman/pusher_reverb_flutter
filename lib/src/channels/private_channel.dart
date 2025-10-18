import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/authorizer.dart';
import '../models/exceptions.dart';
import 'channel.dart';

/// A private channel that requires authentication for subscription.
///
/// Private channels extend the base Channel functionality with authentication
/// capabilities. They must start with the "private-" prefix and require
/// an authorizer function to provide authentication headers.
class PrivateChannel extends Channel {
  /// The authorizer function that provides authentication headers.
  final Authorizer authorizer;

  /// The authentication endpoint URL for private channel authentication.
  final String authEndpoint;

  /// The socket ID used for authentication.
  final String socketId;

  /// Creates a new PrivateChannel instance.
  ///
  /// [name] The name of the private channel (must start with "private-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [socketId] The socket ID for authentication.
  /// [sendMessage] Callback for sending WebSocket messages.
  PrivateChannel({required super.name, required this.authorizer, required this.authEndpoint, required this.socketId, required super.sendMessage}) {
    // Only validate if this is actually a PrivateChannel, not a subclass
    if (runtimeType == PrivateChannel) {
      validatePrivateChannelName(name);
    }
  }

  /// Subscribes to the private channel with authentication.
  ///
  /// This method first authenticates with the server using the authorizer
  /// function, then proceeds with the normal subscription process.
  @override
  Future<void> subscribe() async {
    if (state == ChannelState.subscribed || state == ChannelState.subscribing) {
      return;
    }

    setState(ChannelState.subscribing);

    try {
      // Get authentication headers from the authorizer
      final authHeaders = await authorizer(name, socketId);

      // Check if channel is still subscribing (not unsubscribed during auth)
      if (state != ChannelState.subscribing) {
        return;
      }

      // Send authentication request to the server
      final authKey = await _authenticateWithServer(authHeaders);

      // Check again if channel is still subscribing before sending message
      if (state != ChannelState.subscribing) {
        return;
      }

      // Send subscription message with auth key
      final message = {
        'event': 'pusher:subscribe',
        'data': {'channel': name, 'auth': authKey},
      };

      sendMessage(_encodeMessage(message));
    } catch (e) {
      // Only update state if still subscribing (not already unsubscribed)
      if (state == ChannelState.subscribing) {
        setState(ChannelState.unsubscribed);
        rethrow;
      }
      // If already unsubscribed, silently ignore the error
    }
  }

  /// Authenticates with the server using the provided headers.
  ///
  /// [authHeaders] The authentication headers from the authorizer function.
  ///
  /// Returns the authentication key from the server response.
  ///
  /// Throws [AuthenticationException] if authentication fails.
  Future<String> _authenticateWithServer(Map<String, String> authHeaders) async {
    try {
      // Prepare the request body with channel name and socket ID
      final requestBody = {'socket_id': socketId, 'channel_name': name};

      // Create the HTTP request
      final response = await http.post(
        Uri.parse(authEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...authHeaders, // Include headers from the authorizer function
        },
        body: jsonEncode(requestBody),
      );

      // Handle the response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final authKey = responseData['auth'] as String?;

        if (authKey == null || authKey.isEmpty) {
          throw AuthenticationException(message: 'Authentication response missing auth key', channelName: name, statusCode: response.statusCode);
        }

        return authKey;
      } else if (response.statusCode == 403) {
        throw AuthenticationException(message: 'Authentication forbidden - insufficient permissions', channelName: name, statusCode: response.statusCode);
      } else {
        throw AuthenticationException(message: 'Authentication failed with status ${response.statusCode}', channelName: name, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw AuthenticationException(message: 'Network error during authentication: ${e.message}', channelName: name);
    } on FormatException catch (e) {
      throw AuthenticationException(message: 'Invalid response format during authentication: ${e.message}', channelName: name);
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw AuthenticationException(message: 'Unexpected error during authentication: $e', channelName: name);
    }
  }

  /// Encodes a message to JSON string.
  String _encodeMessage(Map<String, dynamic> message) {
    return jsonEncode(message);
  }
}
