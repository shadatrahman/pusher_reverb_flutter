import 'package:web_socket_channel/web_socket_channel.dart';

/// Web implementation: uses the platform-agnostic [WebSocketChannel.connect].
///
/// The browser's WebSocket API does not support custom headers during the
/// handshake, so [headers] and [pingInterval] are intentionally ignored.
/// Channel-level auth (private/presence) is unaffected — it goes through
/// the [Authorizer] callback, not the connection headers.
WebSocketChannel createWebSocketChannel(
  Uri uri, {
  Map<String, dynamic>? headers,
  Duration? pingInterval,
}) {
  return WebSocketChannel.connect(uri);
}
