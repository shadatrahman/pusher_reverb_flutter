import 'dart:async';

/// A function that provides authentication headers for private channel access.
///
/// This function is called when subscribing to a private channel to obtain
/// the necessary authentication headers for the authorization request.
///
/// [channelName] The name of the private channel being subscribed to.
/// [socketId] The socket ID assigned by the server upon connection.
///
/// Returns a Future that completes with a Map of authentication headers.
/// The headers should include any necessary tokens or credentials for
/// authenticating the private channel subscription.
typedef Authorizer = Future<Map<String, String>> Function(String channelName, String socketId);

/// Exception thrown when authentication fails for a private channel.
class AuthenticationException implements Exception {
  /// The error message describing the authentication failure.
  final String message;

  /// The HTTP status code if available (e.g., 403 for Forbidden).
  final int? statusCode;

  /// The channel name that failed authentication.
  final String channelName;

  /// Creates a new AuthenticationException.
  const AuthenticationException({required this.message, this.statusCode, required this.channelName});

  @override
  String toString() {
    final statusInfo = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'AuthenticationException: $message$statusInfo for channel "$channelName"';
  }
}

/// Validates that a channel name is a valid private channel name.
///
/// Private channels must start with the "private-" prefix.
///
/// [channelName] The channel name to validate.
///
/// Throws [ArgumentError] if the channel name is not a valid private channel name.
void validatePrivateChannelName(String channelName) {
  if (channelName.isEmpty) {
    throw ArgumentError('Channel name cannot be empty');
  }

  if (!channelName.startsWith('private-')) {
    throw ArgumentError(
      'Private channel name must start with "private-" prefix. '
      'Received: "$channelName"',
    );
  }

  // Use the same validation as the base Channel class for the rest of the name
  if (channelName.length > 200) {
    throw ArgumentError('Channel name cannot exceed 200 characters');
  }

  final invalidChars = RegExp(r'[^a-zA-Z0-9_\-=@,.;]');
  if (invalidChars.hasMatch(channelName)) {
    throw ArgumentError(
      'Channel name contains invalid characters. Only alphanumeric characters, '
      'underscores, hyphens, equals signs, at signs, commas, periods, and semicolons are allowed.',
    );
  }
}
