import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/authorizer.dart';
import '../models/exceptions.dart';
import '../models/presence_member.dart';
import 'channel.dart';
import 'private_channel.dart';

/// A presence channel that tracks subscribed members.
///
/// Presence channels extend PrivateChannel with member awareness capabilities.
/// They must start with the "presence-" prefix and require authentication
/// like private channels. Additionally, they track who is currently subscribed
/// to the channel and provide member_added and member_removed events.
class PresenceChannel extends PrivateChannel {
  /// Map of currently subscribed members by their ID.
  final Map<String, PresenceMember> _members = {};

  /// Optional channel data for presence subscription (typically user info).
  final Map<String, dynamic>? channelData;

  /// Creates a new PresenceChannel instance.
  ///
  /// [name] The name of the presence channel (must start with "presence-").
  /// [authorizer] The function that provides authentication headers.
  /// [authEndpoint] The URL endpoint for authentication requests.
  /// [socketId] The socket ID for authentication.
  /// [sendMessage] Callback for sending WebSocket messages.
  /// [channelData] Optional data to include in the subscription (typically user info).
  PresenceChannel({required super.name, required super.authorizer, required super.authEndpoint, required super.socketId, required super.sendMessage, this.channelData}) {
    validatePresenceChannelName(name);
  }

  /// Returns the list of currently subscribed members.
  ///
  /// This list is updated automatically when members join or leave the channel.
  List<PresenceMember> get members => _members.values.toList();

  /// Returns the count of currently subscribed members.
  int get memberCount => _members.length;

  /// Subscribes to the presence channel with authentication and channel data.
  ///
  /// This method first authenticates with the server using the authorizer
  /// function, including channel_data in the request if provided.
  @override
  Future<void> subscribe() async {
    if (state == ChannelState.subscribed || state == ChannelState.subscribing) {
      return;
    }

    setState(ChannelState.subscribing);

    try {
      // Get authentication headers from the authorizer
      final authHeaders = await authorizer(name, socketId);

      // Send authentication request to the server with channel data
      final authResponse = await _authenticateWithServerAndChannelData(authHeaders);

      // Send subscription message with auth key and channel data
      final message = {
        'event': 'pusher:subscribe',
        'data': {'channel': name, 'auth': authResponse['auth'], if (authResponse.containsKey('channel_data')) 'channel_data': authResponse['channel_data']},
      };

      sendMessage(_encodeMessage(message));
    } catch (e) {
      setState(ChannelState.unsubscribed);
      rethrow;
    }
  }

  /// Authenticates with the server including channel data.
  ///
  /// [authHeaders] The authentication headers from the authorizer function.
  ///
  /// Returns a map containing 'auth' and optionally 'channel_data'.
  ///
  /// Throws [AuthenticationException] if authentication fails.
  Future<Map<String, dynamic>> _authenticateWithServerAndChannelData(Map<String, String> authHeaders) async {
    try {
      // Prepare the request body with channel name, socket ID, and channel data
      final requestBody = {'socket_id': socketId, 'channel_name': name, if (channelData != null) 'channel_data': jsonEncode(channelData)};

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

        return {'auth': authKey, if (responseData.containsKey('channel_data')) 'channel_data': responseData['channel_data']};
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

  /// Handles subscription success and parses initial member list.
  ///
  /// The subscription_succeeded data contains a 'presence' field with
  /// member information.
  @override
  void handleSubscriptionSucceeded([dynamic data]) {
    setState(ChannelState.subscribed);

    // Parse initial member list from subscription data
    if (data != null && data is Map<String, dynamic>) {
      final presence = data['presence'];
      if (presence != null && presence is Map<String, dynamic>) {
        final hash = presence['hash'];
        if (hash != null && hash is Map<String, dynamic>) {
          _members.clear();
          hash.forEach((userId, userInfo) {
            final member = PresenceMember(id: userId, info: userInfo is Map<String, dynamic> ? userInfo : {});
            _members[userId] = member;
          });
        }
      }
    }
  }

  /// Handles incoming events for this presence channel.
  ///
  /// Intercepts member_added and member_removed events to update the
  /// member list, then forwards all events to the base class.
  @override
  void handleEvent(String eventName, dynamic data) {
    // Handle presence-specific events
    if (eventName == 'pusher:member_added') {
      _handleMemberAdded(data);
    } else if (eventName == 'pusher:member_removed') {
      _handleMemberRemoved(data);
    }

    // Call parent to emit events to streams and callbacks
    super.handleEvent(eventName, data);
  }

  /// Handles member_added events.
  ///
  /// Parses the member data and adds it to the member list.
  void _handleMemberAdded(dynamic data) {
    if (data != null && data is Map<String, dynamic>) {
      final userId = data['user_id'] as String?;
      final userInfo = data['user_info'];

      if (userId != null) {
        final member = PresenceMember(id: userId, info: userInfo is Map<String, dynamic> ? userInfo : {});
        _members[userId] = member;
      }
    }
  }

  /// Handles member_removed events.
  ///
  /// Parses the member ID and removes it from the member list.
  void _handleMemberRemoved(dynamic data) {
    if (data != null && data is Map<String, dynamic>) {
      final userId = data['user_id'] as String?;

      if (userId != null) {
        _members.remove(userId);
      }
    }
  }

  /// Encodes a message to JSON string.
  String _encodeMessage(Map<String, dynamic> message) {
    return jsonEncode(message);
  }
}
