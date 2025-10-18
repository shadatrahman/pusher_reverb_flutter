/// Base exception for all Pusher Reverb Flutter errors.
///
/// All custom exceptions in this package extend from [PusherException].
/// This allows developers to catch all package-specific exceptions with a single catch block.
///
/// Example:
/// ```dart
/// try {
///   await client.connect();
/// } on PusherException catch (e) {
///   print('Pusher error occurred: $e');
/// } catch (e) {
///   print('Other error: $e');
/// }
/// ```
class PusherException implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Creates a new PusherException with the given message.
  const PusherException(this.message);

  @override
  String toString() => 'PusherException: $message';
}

/// Exception thrown when WebSocket connection fails.
///
/// This exception is thrown in scenarios like:
/// - Unable to establish initial connection to the server
/// - Network errors during connection attempts
/// - Invalid connection configuration (host, port, etc.)
///
/// Example:
/// ```dart
/// try {
///   await client.connect();
/// } on ConnectionException catch (e) {
///   print('Connection failed: ${e.message}');
///   if (e.cause != null) {
///     print('Caused by: ${e.cause}');
///   }
/// }
/// ```
class ConnectionException extends PusherException {
  /// The underlying cause of the connection failure, if available.
  final dynamic cause;

  /// Creates a new ConnectionException.
  const ConnectionException(super.message, {this.cause});

  @override
  String toString() {
    final causeInfo = cause != null ? ' (Caused by: $cause)' : '';
    return 'ConnectionException: $message$causeInfo';
  }
}

/// Exception thrown when channel operations fail.
///
/// This exception is thrown for channel-specific errors such as:
/// - Subscription failures
/// - Invalid channel state transitions
/// - Channel not found errors
///
/// Example:
/// ```dart
/// try {
///   await channel.subscribe();
/// } on ChannelException catch (e) {
///   print('Channel error: ${e.message}');
/// }
/// ```
class ChannelException extends PusherException {
  /// The name of the channel that caused the error.
  final String? channelName;

  /// Creates a new ChannelException.
  const ChannelException(super.message, {this.channelName});

  @override
  String toString() {
    final channelInfo = channelName != null ? ' for channel "$channelName"' : '';
    return 'ChannelException: $message$channelInfo';
  }
}

/// Exception thrown when a channel name is invalid.
///
/// This exception is thrown when:
/// - Channel name is empty
/// - Channel name exceeds 200 characters
/// - Channel name contains invalid characters
/// - Private channel missing "private-" prefix
/// - Presence channel missing "presence-" prefix
/// - Encrypted channel missing "private-encrypted-" prefix
///
/// Example:
/// ```dart
/// try {
///   client.subscribeToPrivateChannel('invalid');
/// } on InvalidChannelNameException catch (e) {
///   print('Invalid channel name: ${e.message}');
/// }
/// ```
class InvalidChannelNameException extends PusherException {
  /// The invalid channel name that caused the error.
  final String channelName;

  /// Creates a new InvalidChannelNameException.
  const InvalidChannelNameException(super.message, this.channelName);

  @override
  String toString() => 'InvalidChannelNameException: $message (Channel: "$channelName")';
}

/// Exception thrown when authentication fails for private/presence/encrypted channels.
///
/// This exception is thrown when:
/// - Authentication endpoint returns 403 (Forbidden)
/// - Authentication endpoint returns non-200 status
/// - Authentication response missing required 'auth' key
/// - Network errors during authentication request
///
/// Example:
/// ```dart
/// try {
///   await client.subscribeToPrivateChannel('private-chat');
/// } on AuthenticationException catch (e) {
///   if (e.statusCode == 403) {
///     print('Access forbidden: ${e.message}');
///   } else {
///     print('Auth failed: ${e.message}');
///   }
/// }
/// ```
class AuthenticationException extends PusherException {
  /// The HTTP status code if available (e.g., 403 for Forbidden).
  final int? statusCode;

  /// The channel name that failed authentication.
  final String channelName;

  /// Creates a new AuthenticationException.
  const AuthenticationException({required String message, this.statusCode, required this.channelName}) : super(message);

  @override
  String toString() {
    final statusInfo = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'AuthenticationException: $message$statusInfo for channel "$channelName"';
  }
}
